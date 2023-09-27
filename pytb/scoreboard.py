from common_utils import *
import transaction

class Scoreboard(pyuvm.uvm_scoreboard):
    def __init__(self,name,parent):
        super().__init__(name,parent)
        self.cfg = ConfigClass()
        self.actl_trans = 0
        self.rcvd_trans = 0
        self.imon_trans = 0
        self.omon_trans = 0
        self.drpd_trans = 0
        self.pass_trans = 0
        self.fail_trans = 0
        self.outm_count = [0 for _ in range(NUM_OF_PORTS)]
        self.driver_fifo = None
        self.inputm_fifo = None
        self.output_fifo = [None for _ in range(NUM_OF_PORTS)]

    def build_phase(self):
        self.actl_trans = self.cfg.num_txn
        self.driver_fifo = pyuvm.uvm_tlm_analysis_fifo("Drvr_Pkt_Fifo",self)
        self.inputm_fifo = pyuvm.uvm_tlm_analysis_fifo("Inp_Mon_Pkt_Fifo",self)
        for lp_var in range(NUM_OF_PORTS):
            self.output_fifo[lp_var] = pyuvm.uvm_tlm_analysis_fifo(f"Out_Mon_Pkt_Fifo[{lp_var}]", self)

    async def run_phase(self):
        while True:
            portnum = NUM_OF_PORTS
            dropped = 1
            matched = 0
            drv_pkt = await self.driver_fifo.get()
            self.rcvd_trans += 1
            inp_pkt = await self.inputm_fifo.get()
            self.imon_trans += 1
            matched = self.compare_packet(drv_pkt, inp_pkt)

            if matched == 1:
                matched = 0
                if inp_pkt.dst_port in self.cfg.port:
                    portnum = self.cfg.port.index(inp_pkt.dst_port)
                    dropped = 0
                if portnum != NUM_OF_PORTS:
                    out_pkt = await self.output_fifo[portnum].get()
                    self.outm_count[portnum] += 1
                    matched = self.compare_packet(inp_pkt, out_pkt)
                    if matched == 1:
                        self.pass_trans += 1
                    else:
                        self.fail_trans += 1
                else:
                    if dropped == 1:
                        self.drpd_trans += 1
                        self.pass_trans += 1
                    else:
                        self.fail_trans += 1
            else:
                self.fail_trans += 1

    def compare_packet(self, exp_pkt:transaction.Transaction, act_pkt:transaction.Transaction):
        exp_pkt_list = exp_pkt.pack_packet()
        act_pkt_list = act_pkt.pack_packet()
        if len(exp_pkt_list) != len(act_pkt_list):
            self.logger.critical("Not Matched ::: ExpLSize = %s ::: ActLSize = %s",
                                 len(exp_pkt_list), len(act_pkt_list))
            return 0
        for index, _ in enumerate(exp_pkt_list):
            if exp_pkt_list[index] != act_pkt_list[index]:
                self.logger.critical("Item at %s Not Matched ::: ExpLItem = %s ::: ActLItem = %s",
                                     index, exp_pkt_list[index], act_pkt_list[index])
                return 0
        return 1

    def check_phase(self):
        passed = True
        for lp_var in range(NUM_OF_PORTS):
            self.omon_trans += self.outm_count[lp_var]
            self.logger.info("No. of Output Monitor[%s] Transactions : %s", lp_var, self.outm_count[lp_var])
        self.logger.info("No. of Expected          Transactions : %s", self.actl_trans)
        self.logger.info("No. of Actual            Transactions : %s", self.rcvd_trans)
        self.logger.info("No. of Input Monitor     Transactions : %s", self.imon_trans)
        self.logger.info("No. of Dropped           Transactions : %s", self.drpd_trans)
        self.logger.info("No. of Output Monitor    Transactions : %s", self.omon_trans)
        self.logger.info("No. of Passed            Transactions : %s", self.pass_trans)
        self.logger.info("No. of Failed            Transactions : %s", self.fail_trans)
        if self.pass_trans == self.rcvd_trans and self.rcvd_trans == self.actl_trans and \
           self.rcvd_trans == self.imon_trans and self.fail_trans == 0 and \
           self.imon_trans == self.omon_trans + self.drpd_trans:
            self.logger.info("Test Passed!")
        else:
            self.logger.fatal("Test Failed")
            passed = False
        assert passed