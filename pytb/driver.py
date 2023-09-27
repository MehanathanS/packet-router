from common_utils import *

class Driver(pyuvm.uvm_driver):
    def __init__(self,name,parent):
        super().__init__(name,parent)
        self.dut = cocotb.top
        self.cfg = ConfigClass()
        self.drv_inp_port = None

    def build_phase(self):
        self.drv_inp_port = pyuvm.uvm_analysis_port("drv_inp_port", self)

    async def reset_dut(self):
        bfr_rst_dly = random.randint(2, 10)
        aft_rst_dly = random.randint(2, 12)
        self.dut.reset.value = 0
        await wait_clk(bfr_rst_dly)
        self.dut.reset.value = 1
        self.dut.mem_en.value = 0
        self.dut.mem_rd_wr.value = 0
        self.dut.mem_add.value = 0
        self.dut.mem_data.value = 0
        self.dut.data_status.value = 0
        self.dut.data.value = 0
        await wait_clk(aft_rst_dly)
        self.dut.reset.value = 0

    async def config_dut(self):
        await wait_clk(1)
        self.dut.mem_en.value = 1
        self.dut.mem_rd_wr.value = 1
        for idx in range(NUM_OF_PORTS):
            self.dut.mem_add.value = idx
            self.dut.mem_data.value = self.cfg.port[idx]
            await wait_clk(1)
        self.dut.mem_en.value = 0
        self.dut.mem_rd_wr.value = 0
        self.dut.mem_add.value = 0
        self.dut.mem_data.value = 0
        await wait_clk(1)

    async def drive_dut(self, user_list:list):
        list_len = len(user_list)
        for index in range(list_len):
            full = int(self.dut.fifo_full.value)
            while full == 1:
                self.dut.data_status.value = 0
                await wait_clk(1)
                full = int(self.dut.fifo_full.value)
            self.dut.data_status.value = 1
            self.dut.data.value = user_list[index]
            await wait_clk(1)
        self.dut.data_status.value = 0
        self.dut.data.value = random.randint(0, 0xFF)

    async def run_phase(self):
        await self.reset_dut()
        await self.config_dut()
        while True:
            item = await self.seq_item_port.get_next_item()
            user_list = item.pack_packet()
            await self.drive_dut(user_list)
            self.drv_inp_port.write(item)
            self.seq_item_port.item_done()
