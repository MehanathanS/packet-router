import argparse
import random
import logging
import sys
from enum import Enum, unique
from pathlib import Path
from cocotb.log import default_config
import pyuvm
sys.path.append(str(Path("..").resolve()))

NUM_OF_PORTS = 4

@unique
class FcsType(Enum):
    GOOD_FCS = 0
    BAD_FCS = 1

def setup_logger():
    try:
        default_config()
    except RuntimeError:
        pass
    logging.basicConfig(level=logging.NOTSET)
    logger = logging.getLogger("name")
    logging.addLevelName(5, "TEST")
    logger.setLevel(5)
    logger.log(5, "TST_MSG")

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--no_delay", action="store_true")
    parser.add_argument("--num_txn", type=int, default=random.randint(1, 5000))
    args = parser.parse_args()
    return args

class ConfigClass(metaclass=pyuvm.utility_classes.Singleton):
    def __init__(self):
        self.__rand_dly = 0
        self.port = [0 for _ in range(NUM_OF_PORTS)]
        self.mon_dly = [0 for _ in range(NUM_OF_PORTS)]
        self.num_txn = 0
        self.min_delay = 1
        self.max_delay = 20

    def randomize(self):
        args = parse_arguments()
        if args.no_delay:
            self.__rand_dly = 0
        else:
            self.__rand_dly = 1
        self.port = random.sample(range(0, 0xFF), NUM_OF_PORTS)
        if self.__rand_dly:
            self.mon_dly = random.sample(
                range(self.min_delay, self.max_delay), NUM_OF_PORTS)
        else:
            self.mon_dly = [0 for _ in range(NUM_OF_PORTS)]
        self.num_txn = args.num_txn
        self.post_randomize()

    def post_randomize(self):
        logging.info("CFG_CLS : NUM_TXN = %s NUM_PORTS = %s", self.num_txn, NUM_OF_PORTS)
        tstr = ', '.join(f'Port[{lv}] = {hex(self.port[lv])}' for lv in range(NUM_OF_PORTS))
        logging.info("CFG_CLS : %s", tstr)
        tstr = ', '.join(f'MonDelay[{lv}] = {self.mon_dly[lv]}' for lv in range(NUM_OF_PORTS))
        logging.info("CFG_CLS : %s", tstr)
