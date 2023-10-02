import random
from enum import Enum, unique
import cocotb
import pyuvm

NUM_OF_PORTS = 4

@unique
class FcsType(Enum):
    GOOD_FCS = 0
    BAD_FCS = 1

async def wait_clk(num_clk):
    if num_clk > 0:
        for _ in range(num_clk):
            await cocotb.triggers.FallingEdge(cocotb.top.clock)

class ConfigClass(metaclass=pyuvm.utility_classes.Singleton):
    def __init__(self, parent_logger = pyuvm.uvm_root().logger):
        self.__rand_dly = 0
        self.port = [0 for _ in range(NUM_OF_PORTS)]
        self.max_mon_dly = [0 for _ in range(NUM_OF_PORTS)]
        self.num_txn = 0
        self.min_delay = 1
        self.max_delay = 20
        self.logger = parent_logger

    def randomize(self):
        if "NO_DELAY" in cocotb.plusargs:
            self.__rand_dly = 0
        else:
            self.__rand_dly = 1
        self.port = random.sample(range(0, 0xFF), NUM_OF_PORTS)
        if self.__rand_dly:
            self.max_mon_dly = random.sample(
                range(self.min_delay, self.max_delay), NUM_OF_PORTS)
        else:
            self.max_mon_dly = [0 for _ in range(NUM_OF_PORTS)]
        if "NUM_TXN" in cocotb.plusargs:
            self.num_txn = int(cocotb.plusargs["NUM_TXN"])
        else:
            self.num_txn = random.randint(1,5000)
        self.post_randomize()

    def post_randomize(self):
        self.logger.info("CFG_CLS : NUM_TXN = %s NUM_PORTS = %s", self.num_txn, NUM_OF_PORTS)
        tstr = ', '.join(f'Port[{lv}] = {hex(self.port[lv])}' for lv in range(NUM_OF_PORTS))
        self.logger.info("CFG_CLS : %s", tstr)
        tstr = ', '.join(f'MaxMonDelay[{lv}] = {self.max_mon_dly[lv]}' for lv in range(NUM_OF_PORTS))
        self.logger.info("CFG_CLS : %s", tstr)
