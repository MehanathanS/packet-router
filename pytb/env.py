from common_utils import *
import driver
import monitor
import scoreboard

class RouterEnv(pyuvm.uvm_env):
    def __init__(self,name,parent):
        super().__init__(name,parent)
        self.cfg = ConfigClass(self.logger)
        self.seqr = None
        self.scbd = None
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
        self.scbd = scoreboard.Scoreboard("Scoreboard",self)

    def connect_phase(self):
        self.driver.seq_item_port.connect(self.seqr.seq_item_export)
        self.driver.drv_inp_port.connect(self.scbd.driver_fifo.analysis_export)
        self.inp_mon.inp_mon_port.connect(self.scbd.inputm_fifo.analysis_export)
        for lp_var in range(NUM_OF_PORTS):
            self.out_mon[lp_var].out_mon_port.connect(self.scbd.output_fifo[lp_var].analysis_export)
