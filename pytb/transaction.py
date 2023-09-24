from common_utils import *

class Transaction(pyuvm.uvm_sequence_item):
    def __init__(self, name):
        super().__init__(name)
        self.src_port = 0
        self.dst_port = 0
        self.length = 0
        self.data = []
        self.valid_dst = 0
        self.fcs_type = FcsType.GOOD_FCS
        self.fcs = 0
        self.packed_data = []
        self.cfg_class = ConfigClass()

    def randomize(self):
        self.valid_dst = random.choices([1,0], [0.95, 0.05])[0]
        if self.valid_dst == 1:
            self.dst_port = random.choice(self.cfg_class.port)
            self.src_port = random.choice(
                [val for val in range(0, 0xFF) if val not in self.cfg_class.port])
        else:
            self.dst_port = random.randint(0, 0xFF)
            self.src_port = random.choice(
                [val for val in self.cfg_class.port if val != self.dst_port])
        self.length = random.randint(0, 0xFF)
        self.data = [random.randint(0,0xFF) for _ in range(self.length)]
        self.post_randomize()

    def post_randomize(self):
        self.fcs = self.calc_fcs()
        if self.fcs_type == FcsType.BAD_FCS:
            self.fcs = self.fcs ^ 0xFF
        self.pack_packet()
        self.print_packet()

    def calc_fcs(self):
        local_fcs = 0
        local_fcs = self.src_port ^ self.dst_port
        local_fcs = local_fcs ^ self.length
        for item in self.data:
            local_fcs = local_fcs ^ item
        return local_fcs

    def check_fcs(self):
        chk_fcs = self.calc_fcs()
        if chk_fcs == self.fcs:
            self.fcs_type = FcsType.GOOD_FCS
        else:
            self.fcs_type = FcsType.BAD_FCS

    def pack_packet(self):
        self.packed_data.append(self.dst_port)
        self.packed_data.append(self.src_port)
        self.packed_data.append(self.length)
        for item in self.data:
            self.packed_data.append(item)
        self.packed_data.append(self.fcs)

    def unpack_packet(self):
        self.dst_port = self.packed_data[0]
        self.src_port = self.packed_data[1]
        self.length = self.packed_data[2]
        self.fcs = self.packed_data[-1]
        self.data = self.packed_data[3:-1]
        self.check_fcs()
        self.print_packet()
        if self.length != len(self.data):
            logging.fatal("Problem Observed with Unpacked Packet")

    def print_packet(self):
        logging.debug("SRC_PORT = %s DST_PORT = %s Length = %s DATA_SIZE = %s FCS = %s TYPE = %s",
                      hex(self.src_port), hex(self.dst_port), self.length, len(self.data),
                      hex(self.fcs), self.fcs_type.name)

if __name__ == "__main__":
    logging.basicConfig(
        level=logging.DEBUG, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

    cfg_class = ConfigClass()
    cfg_class.randomize()

    for _ in range(10):
        SW_Txn = Transaction("MyTransaction")
        SW_Txn.randomize()
