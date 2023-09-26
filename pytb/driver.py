from common_utils import *

class Driver(pyuvm.uvm_driver):
    def __init__(self,name,parent):
        super().__init__(name,parent)
        self.drv_inp_port = None
        self.intf_bfm_cls = None

    def build_phase(self):
        self.drv_inp_port = pyuvm.uvm_analysis_port("drv_inp_port", self)

    def start_of_simulation_phase(self):
        self.intf_bfm_cls = BusFunctionalModel()

    async def start_bfm_work(self):
        await self.intf_bfm_cls.reset_dut()
        await self.intf_bfm_cls.config_dut()
        self.intf_bfm_cls.spawn_necessary_threads()

    async def run_phase(self):
        await self.start_bfm_work()
        while True:
            item = await self.seq_item_port.get_next_item()
            user_list = item.pack_packet()
            await self.intf_bfm_cls.send_txn(user_list)
            sent_list = await self.intf_bfm_cls.get_sent_txn()
            result = all(item1 == item2 for item1, item2 in zip(user_list,sent_list))
            if result:
                pass
            else:
                self.logger.critical("Issue with Interacting with BFM ::: ExpList = %s ActList = %s",
                                     user_list, sent_list)
            self.seq_item_port.item_done()
