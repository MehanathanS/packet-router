from common_utils import *
import transaction

class InputMonitor(pyuvm.uvm_component):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.dut = cocotb.top
        self.inp_mon_port = None

    def build_phase(self):
        self.inp_mon_port = pyuvm.uvm_analysis_port("inp_mon_port", self)

    async def run_phase(self):
        user_list = []
        list_size = 0
        data_size = 0
        while True:
            await wait_clk(1)
            try:
               if self.dut.data_status.value == 1:
                   if list_size == 2:
                       data_size = self.dut.data.value
                   elif list_size == 0:
                       user_list = []
                       data_size = 0
                   user_list.append(self.dut.data.value)
                   list_size += 1
                   if list_size-4 == data_size:
                       txnp = transaction.Transaction("InpMonTxn")
                       txnp.unpack_packet(user_list, "InpTxnMon")
                       self.inp_mon_port.write(txnp)
                       list_size = 0
            except ValueError:
                pass

class OutputMonitor(pyuvm.uvm_component):
    def __init__(self, name, parent, port_num):
        super().__init__(name, parent)
        self.dut = cocotb.top
        self.cfg = ConfigClass()
        self.out_mon_port = None
        self.port_num = port_num

    def build_phase(self):
        self.out_mon_port = pyuvm.uvm_analysis_port(f"out_mon_port[{self.port_num}]", self)

    def get_ready_val(self):
        if self.port_num == 0:
            return self.dut.ready_0.value
        if self.port_num == 1:
            return self.dut.ready_1.value
        if self.port_num == 2:
            return self.dut.ready_2.value
        else:
            return self.dut.ready_3.value

    def get_port_val(self):
        if self.port_num == 0:
            return self.dut.port0.value
        if self.port_num == 1:
            return self.dut.port1.value
        if self.port_num == 2:
            return self.dut.port2.value
        else:
            return self.dut.port3.value

    def set_read_val(self, val):
        if self.port_num == 0:
            self.dut.read_0.value = val
        elif self.port_num == 1:
            self.dut.read_1.value = val
        elif self.port_num == 2:
            self.dut.read_2.value = val
        else:
            self.dut.read_3.value = val

    async def run_phase(self):
        while True:
            await wait_clk(1)
            try:
                if self.get_ready_val() == 1:
                    user_list = []
                    local_dly = random.randint(0,self.cfg.max_mon_dly[self.port_num])
                    await wait_clk(local_dly)
                    self.set_read_val(1)
                    await wait_clk(1)
                    user_list.append(self.get_port_val())  # Capture DST_PORT
                    await wait_clk(1)
                    user_list.append(self.get_port_val())  # Capture SRC_PORT
                    await wait_clk(1)
                    data_size = self.get_port_val()
                    user_list.append(data_size)  # Capture Length
                    for _ in range(data_size):
                        await wait_clk(1)
                        user_list.append(self.get_port_val())  # Capture Data
                    await wait_clk(1)
                    user_list.append(self.get_port_val())  # Capture CRC
                    txnp = transaction.Transaction(f"OutMonTxn[{self.port_num}]")
                    txnp.unpack_packet(user_list, f"OutMonTxn[{self.port_num}]")
                    self.out_mon_port.write(txnp)
                    self.set_read_val(0)
            except ValueError:
                pass
