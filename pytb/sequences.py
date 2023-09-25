from common_utils import *
import transaction

class BaseSequence(pyuvm.uvm_sequence):
    def __init__(self, name):
        super().__init__(name)
        self.cfg_cls = ConfigClass()

    async def body(self):
        self.sequencer = pyuvm.ConfigDB().get(None, "", "Sequencer")


class RandLenSequence(BaseSequence):
    async def body(self):
        await super().body()
        for _ in range(self.cfg_cls.num_txn):
            item = transaction.Transaction("SeqItem")
            await self.start_item(item)
            await self.finish_item(item)
