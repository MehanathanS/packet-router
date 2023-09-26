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
        #TODO self.length = random.randint(0, 0xFF)
        self.length = 1
        self.data = [random.randint(0,0xFF) for _ in range(self.length)]
        self.post_randomize()

    def post_randomize(self):
        self.fcs = self.calc_fcs()
        if self.fcs_type == FcsType.BAD_FCS:
            self.fcs = self.fcs ^ 0xFF
        self.print_packet("After__Random")

    def calc_fcs(self):
        local_fcs = 0
        local_fcs = self.src_port ^ self.dst_port
        local_fcs = local_fcs ^ self.length
        for _item in self.data:
            local_fcs = local_fcs ^ _item
        return local_fcs

    def check_fcs(self):
        chk_fcs = self.calc_fcs()
        if chk_fcs == self.fcs:
            self.fcs_type = FcsType.GOOD_FCS
        else:
            self.fcs_type = FcsType.BAD_FCS

    def pack_packet(self):
        packed_data = []
        packed_data.append(self.dst_port)
        packed_data.append(self.src_port)
        packed_data.append(self.length)
        for _item in self.data:
            packed_data.append(_item)
        packed_data.append(self.fcs)
        return packed_data

    def unpack_packet(self, packed_data:list, caller_name:str):
        self.dst_port = packed_data[0]
        self.src_port = packed_data[1]
        self.length = packed_data[2]
        self.fcs = packed_data[-1]
        self.data = packed_data[3:-1]
        self.check_fcs()
        self.print_packet(f"unpack_packet_{caller_name}")
        if self.length != len(self.data):
            self.cfg_class.logger.fatal("Problem Observed with Unpacked Packet")

    def print_packet(self, fname):
        self.cfg_class.logger.debug("%s : SRC_PORT = %s DST_PORT = %s Len = %s DATA_SIZE = %s FCS = %s TYPE = %s",
                      fname, hex(self.src_port), hex(self.dst_port), int(self.length), len(self.data),
                      hex(self.fcs), self.fcs_type.name)

if __name__ == "__main__":
    import logging
    MyLogger = logging.getLogger("MyLogger")
    MyLogger.setLevel(logging.DEBUG)

    MyConsoleHandler = logging.StreamHandler()
    MyConsoleHandler.setLevel(logging.DEBUG)

    MyFormatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    MyConsoleHandler.setFormatter(MyFormatter)

    MyLogger.addHandler(MyConsoleHandler)

    cfg_class = ConfigClass(MyLogger)
    cfg_class.randomize()

    for _ in range(10):
        sw_txn1 = Transaction("FirstTransaction")
        sw_txn2 = Transaction("SecondTransaction")
        sw_txn1.randomize()
        user_list1 = sw_txn1.pack_packet()
        sw_txn2.unpack_packet(user_list1)
        user_list2 = sw_txn2.pack_packet()
        if len(user_list1) != len(user_list2):
            pyuvm.uvm_root().logger.critical("Not Matched ::: List1Size = %s ::: List2Size = %s",
                              len(user_list1), len(user_list2))
        for index,item in enumerate(user_list1):
            if user_list1[index] != user_list2[index]:
                pyuvm.uvm_root().logger.critical("Item at %s Not Matched ::: List1Item = %s ::: List2Item = %s",
                                 index, user_list1[index], user_list2[index])
