import argparse
import random
import logging
import sys
from enum import Enum, unique
from pathlib import Path
import cocotb
import pyuvm

NUM_OF_PORTS = 4

@unique
class FcsType(Enum):
    GOOD_FCS = 0
    BAD_FCS = 1

def setup_logger():
    try:
        cocotb.default_config()
    except RuntimeError:
        pass
    logging.basicConfig(level=logging.NOTSET)
    logger = logging.getLogger("name")
    logging.addLevelName(5, "TEST")
    logger.setLevel(5)
    logger.log(5, "TST_MSG")

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--no_delay", action="store_true")
    parser.add_argument("--num_txn", type=int, default=random.randint(1, 5000))
    args = parser.parse_args()
    return args

class ConfigClass(metaclass=pyuvm.utility_classes.Singleton):
    def __init__(self):
        self.__rand_dly = 0
        self.port = [0 for _ in range(NUM_OF_PORTS)]
        self.mon_dly = [0 for _ in range(NUM_OF_PORTS)]
        self.num_txn = 0
        self.min_delay = 1
        self.max_delay = 20

    def randomize(self):
        args = parse_arguments()
        if args.no_delay:
            self.__rand_dly = 0
        else:
            self.__rand_dly = 1
        self.port = random.sample(range(0, 0xFF), NUM_OF_PORTS)
        if self.__rand_dly:
            self.mon_dly = random.sample(
                range(self.min_delay, self.max_delay), NUM_OF_PORTS)
        else:
            self.mon_dly = [0 for _ in range(NUM_OF_PORTS)]
        self.num_txn = args.num_txn
        self.post_randomize()

    def post_randomize(self):
        logging.info("CFG_CLS : NUM_TXN = %s NUM_PORTS = %s", self.num_txn, NUM_OF_PORTS)
        tstr = ', '.join(f'Port[{lv}] = {hex(self.port[lv])}' for lv in range(NUM_OF_PORTS))
        logging.info("CFG_CLS : %s", tstr)
        tstr = ', '.join(f'MonDelay[{lv}] = {self.mon_dly[lv]}' for lv in range(NUM_OF_PORTS))
        logging.info("CFG_CLS : %s", tstr)

class BusFunctionalModel(metaclass=pyuvm.utility_classes.Singleton):
    def __init__(self):
        self.dut = cocotb.top
        self.driver_queue = cocotb.queue.Queue(maxsize = 1)
        self.inp_mon_queue = cocotb.queue.Queue(maxsize = 0)
        self.out_mon_queue = [cocotb.queue.Queue(maxsize = 0) for _ in range(NUM_OF_PORTS)]
        self.cmd_sent_queue = cocotb.queue.Queue(maxsize=1)
        self.cfg_cls = ConfigClass()

    async def send_txn(self, user_list:list):
        await self.driver_queue.put(user_list)

    async def get_sent_txn(self):
        user_list = await self.cmd_sent_queue.get()
        return user_list

    async def get_inp_mon_txn(self):
        user_list = await self.inp_mon_queue.get()
        return user_list

    async def get_out_mon_txn(self, port_num):
        if port_num >= NUM_OF_PORTS:
            logging.critical("Unexpected Port Num = %s", port_num)
        user_list = await self.out_mon_queue[port_num].get()
        return user_list

    async def wait_clk(self, num_clk):
        if num_clk > 0:
            for _ in range(num_clk):
                await cocotb.triggers.FallingEdge(self.dut.clk)

    async def reset_dut(self):
        bfr_rst_dly = random.randint(2,10)
        aft_rst_dly = random.randint(2,12)
        self.dut.reset.value = 0
        await self.wait_clk(bfr_rst_dly)
        self.dut.reset.value = 1
        self.dut.mem_en.value = 0
        self.dut.mem_rd_wr.value = 0
        self.dut.mem_add.value = 0
        self.dut.mem_data.value = 0
        self.dut.data_status.value = 0
        self.dut.data.value = 0
        await self.wait_clk(aft_rst_dly)
        self.dut.reset.value = 0

    async def config_dut(self):
        await self.wait_clk(1)
        self.dut.mem_en.value = 1
        self.dut.mem_rd_wr.value = 1
        for idx in range(NUM_OF_PORTS):
            self.dut.mem_add.value = idx
            self.dut.mem_data.value = self.cfg_cls.port[idx]
            await self.wait_clk(1)
        self.dut.mem_en.value = 0
        self.dut.mem_rd_wr.value = 0
        self.dut.mem_add.value = 0
        self.dut.mem_data.value = 0
        await self.wait_clk(1)

    async def drive_dut(self):
        while True:
            await self.wait_clk(1)
            try:
                user_list = self.driver_queue.get_nowait()
                list_len = len(user_list)
                for index in range(list_len):
                    full = int(self.dut.fifo_full.value)
                    while full == 1:
                        self.dut.data_status.value = 0
                        await self.wait_clk(1)
                        full = int(self.dut.fifo_full.value)
                    self.dut.data_status.value = 1
                    self.dut.data.value = user_list[index]
                    if index != list_len - 1:
                        await self.wait_clk(1)
                self.cmd_sent_queue.put_nowait(user_list)
            except cocotb.queue.QueueEmpty:
                self.dut.data_status.value = 0

    async def mon_inp_intf(self):
        user_list = []
        list_size = 0
        data_size = 0
        while True:
            await self.wait_clk(1)
            if self.dut.data_status.value == 1:
                if list_size == 2:
                    data_size = self.dut.data.value
                elif list_size == 0:
                    user_list = []
                    data_size = 0
                user_list.append(self.dut.data.value)
                list_size += 1
                if list_size-4 == data_size:
                    self.inp_mon_queue.put_nowait(user_list)
                    list_size = 0

    def get_ready_val(self, port_num):
        if port_num == 0:
            return self.dut.ready_0.value
        if port_num == 1:
            return self.dut.ready_1.value
        if port_num == 2:
            return self.dut.ready_2.value
        else:
            return self.dut.ready_3.value

    def get_port_val(self, port_num):
        if port_num == 0:
            return self.dut.port0.value
        if port_num == 1:
            return self.dut.port1.value
        if port_num == 2:
            return self.dut.port2.value
        else:
            return self.dut.port3.value

    def set_read_val(self, port_num, val):
        if port_num == 0:
            self.dut.read_0.value = val
        if port_num == 1:
            self.dut.read_1.value = val
        if port_num == 2:
            self.dut.read_2.value = val
        else:
            self.dut.read_3.value = val

    async def mon_out_intf(self, port_num):
        if port_num >= NUM_OF_PORTS:
            logging.critical("Unexpected Port Num = %s", port_num)
        user_list = []
        data_size = 0
        while True:
            await self.wait_clk(1)
            if self.get_ready_val(port_num) == 1:
                self.set_read_val(port_num,1)
                await self.wait_clk(1)
                user_list.append(self.get_port_val(port_num)) #Capture DST_PORT
                await self.wait_clk(1)
                user_list.append(self.get_port_val(port_num)) #Capture SRC_PORT
                await self.wait_clk(1)
                user_list.append(self.get_port_val(port_num)) #Capture Length
                data_size = user_list[-1]
                for _ in range(data_size):
                    await self.wait_clk(1)
                    user_list.append(self.get_port_val(port_num)) #Capture Data
                await self.wait_clk(1)
                user_list.append(self.get_port_val(port_num)) #Capture CRC
                self.out_mon_queue[port_num].put_nowait(user_list)
                self.set_read_val(port_num,0)

    def spawn_necessary_threads(self):
        cocotb.start_soon(self.drive_dut())
        cocotb.start_soon(self.mon_inp_intf())
        for port_num in range(NUM_OF_PORTS):
            cocotb.start_soon(self.mon_out_intf(port_num))
