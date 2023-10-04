from common_utils import *
import transaction

class BaseSequence(pyuvm.uvm_sequence):
    def __init__(self, name):
        super().__init__(name)
        self.cfg_cls = ConfigClass()

    async def body(self):
        self.sequencer = pyuvm.ConfigDB().get(None, "", "Sequencer")

    async def send_txn(self, min_len, max_len):
        item = transaction.Transaction("SeqItem")
        item.min_len = min_len
        item.max_len = max_len
        await self.start_item(item)
        item.randomize()
        await self.finish_item(item)

class ZeroLenSequence(BaseSequence):
    async def body(self):
        await super().body()
        tasks = []
        for _ in range(self.cfg_cls.num_txn):
            task = cocotb.start_soon(self.send_txn(0,0))
            tasks.append(cocotb.triggers.Join(task))
        await cocotb.triggers.Combine(*tasks)

class MinRangeLenSequence(BaseSequence):
    async def body(self):
        await super().body()
        tasks = []
        for _ in range(self.cfg_cls.num_txn):
            task = cocotb.start_soon(self.send_txn(1, 10))
            tasks.append(cocotb.triggers.Join(task))
        await cocotb.triggers.Combine(*tasks)

class MaxRangeLenSequence(BaseSequence):
    async def body(self):
        await super().body()
        tasks = []
        for _ in range(self.cfg_cls.num_txn):
            task = cocotb.start_soon(self.send_txn(0xF0, 0XFE))
            tasks.append(cocotb.triggers.Join(task))
        await cocotb.triggers.Combine(*tasks)

class MaxLenSequence(BaseSequence):
    async def body(self):
        await super().body()
        tasks = []
        for _ in range(self.cfg_cls.num_txn):
            task = cocotb.start_soon(self.send_txn(0xFF, 0xFF))
            tasks.append(cocotb.triggers.Join(task))
        await cocotb.triggers.Combine(*tasks)

class RandLenSequence(BaseSequence):
    async def body(self):
        await super().body()
        tasks = []
        for _ in range(self.cfg_cls.num_txn):
            task = cocotb.start_soon(self.send_txn(0, 0xFF))
            tasks.append(cocotb.triggers.Join(task))
        await cocotb.triggers.Combine(*tasks)
