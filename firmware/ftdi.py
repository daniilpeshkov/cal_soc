import pyftdi.serialext
import time
import random
import serial

from serial.serialutil import PARITY_NONE, STOPBITS_ONE

# port = pyftdi.serialext.serial_for_url('COM6', baudrate=9600, parity=PARITY_NONE, stopbits=STOPBITS_ONE)

ser = serial.Serial('COM6', 9600)
ser_in = serial.Serial('COM8', 9600)


while True:
    ser.write(random.randbytes(1))
    time.sleep(1)
    print(ser_in.read())

