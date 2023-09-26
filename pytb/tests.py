from common_utils import *
import env
from sequences import *
sys.path.append(str(Path("..").resolve()))

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
        self.drop_objection()

@pyuvm.test()
class RandLenTest(BaseTestClass):
    def __init__(self, name="RandLenTest", parent=None):
        super().__init__(name, parent)

    def build_phase(self):
        pyuvm.uvm_factory().set_type_override_by_type(BaseSequence, RandLenSequence)
        super().build_phase()
