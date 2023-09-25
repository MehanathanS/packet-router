from common_utils import *
import transaction

class InputMonitor(pyuvm.uvm_component):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.inp_mon_port = None
        self.intf_bfm_cls = None

    def build_phase(self):
        self.inp_mon_port = pyuvm.uvm_analysis_port("inp_mon_port", self)

    def start_of_simulation_phase(self):
        self.intf_bfm_cls = BusFunctionalModel()

    async def run_phase(self):
        while True:
            item = await self.intf_bfm_cls.get_inp_mon_txn()
            txnp = transaction.Transaction("InpMonTxn")
            txnp.unpack_packet(item)
            self.inp_mon_port.write(txnp)

class OutputMonitor(pyuvm.uvm_component):
    def __init__(self, name, parent, port_num):
        super().__init__(name, parent)
        self.out_mon_port = None
        self.intf_bfm_cls = None
        self.port_num = port_num

    def build_phase(self):
        self.out_mon_port = pyuvm.uvm_analysis_port(f"out_mon_port[{self.port_num}]", self)

    def start_of_simulation_phase(self):
        self.intf_bfm_cls = BusFunctionalModel()

    async def run_phase(self):
        while True:
            item = await self.intf_bfm_cls.get_out_mon_txn(self.port_num)
            txnp = transaction.Transaction(f"OutMonTxn[{self.port_num}]")
            txnp.unpack_packet(item)
            self.out_mon_port.write(txnp)
