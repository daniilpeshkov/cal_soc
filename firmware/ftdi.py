import pyftdi.serialext
import time
import random

from serial.serialutil import PARITY_NONE, STOPBITS_ONE

port = pyftdi.serialext.serial_for_url('COM6', baudrate=115200, parity=PARITY_NONE, stopbits=STOPBITS_ONE)

while True:
    # port.write(random.randbytes(1))
    print(port.read())

