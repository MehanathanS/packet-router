from common_utils import *
import driver
import monitor

class RouterEnv(pyuvm.uvm_env):
    def __init__(self,name,parent):
        super().__init__(name,parent)
        self.cfg = ConfigClass(self.logger)
        self.bfm = BusFunctionalModel(self.logger)
        self.seqr = None
        self.driver = None
        self.inp_mon = None
        self.out_mon = [None for _ in range(NUM_OF_PORTS)]

    def build_phase(self):
        self.cfg.randomize()
        self.seqr = pyuvm.uvm_sequencer("Sequencer",self)
        pyuvm.ConfigDB().set(None, "*", "Sequencer", self.seqr)
        self.driver = driver.Driver.create("Driver",self)
        self.inp_mon = monitor.InputMonitor("InputMonitor",self)
        self.out_mon = [monitor.OutputMonitor(f"OutputMonitor[{port_num}]", self, port_num)
                        for port_num in range(NUM_OF_PORTS)]

    def connect_phase(self):
        self.driver.seq_item_port.connect(self.seqr.seq_item_export)
