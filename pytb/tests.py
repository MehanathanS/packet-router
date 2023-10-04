from common_utils import *
import env
from sequences import *

class BaseTestClass(pyuvm.uvm_test):
    def __init__(self,name = "BaseTest",parent = None):
        super().__init__(name,parent)
        self.env = None
        self.test_seq = None

    def build_phase(self):
        self.env = env.RouterEnv("RouterEnv",self)
        self.test_seq = BaseSequence.create("TestSequence")

    async def run_phase(self):
        self.raise_objection()
        await self.test_seq.start()
        await self.wait_for_all_txns_to_complete()
        self.drop_objection()

    async def wait_for_all_txns_to_complete(self):
        live_loop_count = 0
        tmax_loop_count = self.env.cfg.num_txn
        while True:
            if cocotb.top.dut.fifo_empty.value == 1:
                break
            else:
                await wait_clk(260)
                live_loop_count += 1
            if live_loop_count == tmax_loop_count:
                break

@pyuvm.test()
class ZeroLenTest(BaseTestClass):
    def __init__(self, name="RandLenTest", parent=None):
        super().__init__(name, parent)

    def build_phase(self):
        pyuvm.uvm_factory().set_type_override_by_type(BaseSequence, ZeroLenSequence)
        super().build_phase()

@pyuvm.test()
class MinRangeLenTest(BaseTestClass):
    def __init__(self, name="RandLenTest", parent=None):
        super().__init__(name, parent)

    def build_phase(self):
        pyuvm.uvm_factory().set_type_override_by_type(BaseSequence, MinRangeLenSequence)
        super().build_phase()

@pyuvm.test()
class MaxRangeLenTest(BaseTestClass):
    def __init__(self, name="RandLenTest", parent=None):
        super().__init__(name, parent)

    def build_phase(self):
        pyuvm.uvm_factory().set_type_override_by_type(BaseSequence, MaxRangeLenSequence)
        super().build_phase()

@pyuvm.test()
class MaxLenTest(BaseTestClass):
    def __init__(self, name="RandLenTest", parent=None):
        super().__init__(name, parent)

    def build_phase(self):
        pyuvm.uvm_factory().set_type_override_by_type(BaseSequence, MaxLenSequence)
        super().build_phase()

@pyuvm.test()
class RandLenTest(BaseTestClass):
    def __init__(self, name="RandLenTest", parent=None):
        super().__init__(name, parent)

    def build_phase(self):
        pyuvm.uvm_factory().set_type_override_by_type(BaseSequence, RandLenSequence)
        super().build_phase()

@pyuvm.test()
class OnlyValidDATest(BaseTestClass):
    def __init__(self, name="OnlyValidDATest", parent=None):
        super().__init__(name, parent)

    def build_phase(self):
        pyuvm.uvm_factory().set_type_override_by_type(BaseSequence, RandLenSequence)
        super().build_phase()
        self.env.cfg.test_DA = "valid"

    def report_phase(self):
        passed = True
        if self.env.scbd.drpd_trans != 0:
            passed = False
        assert passed

@pyuvm.test()
class OnlyInvalidDATest(BaseTestClass):
    def __init__(self, name="OnlyInvalidDATest", parent=None):
        super().__init__(name, parent)

    def build_phase(self):
        pyuvm.uvm_factory().set_type_override_by_type(BaseSequence, RandLenSequence)
        super().build_phase()
        self.env.cfg.test_DA = "invalid"

    def report_phase(self):
        passed = True
        if self.env.scbd.drpd_trans != self.env.cfg.num_txn:
            passed = False
        assert passed

@pyuvm.test(expect_fail=True)
class BadFCSTest(BaseTestClass):
    def __init__(self, name="BadFCSTest", parent=None):
        super().__init__(name, parent)

    def build_phase(self):
        pyuvm.uvm_factory().set_type_override_by_type(BaseSequence, RandLenSequence)
        super().build_phase()
        self.env.cfg.test_FCS = "bad"

    def report_phase(self):
        passed = True
        if self.env.scbd.fail_trans != self.env.cfg.num_txn:
            passed = False
        assert passed

@pyuvm.test(expect_fail=True)
class RandFCSTest(BaseTestClass):
    def __init__(self, name="RandFCSTest", parent=None):
        super().__init__(name, parent)

    def build_phase(self):
        pyuvm.uvm_factory().set_type_override_by_type(BaseSequence, RandLenSequence)
        super().build_phase()
        self.env.cfg.test_FCS = "rand"

    def report_phase(self):
        passed = True
        if self.env.scbd.fail_trans == 0:
            passed = False
        assert passed
