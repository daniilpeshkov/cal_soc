from turtle import st
import pyftdi.serialext
import time
import random
import serial

def write_data(ser, start_addr, data):
    addr_b = bytes([start_addr])
    addr_b = b'\x00'*(4-len(addr_b)) + addr_b
    ser.write(b'\x01'+ addr_b)
    for b in data:
        pass


ser = serial.Serial('COM6', 9600)
ser.write(b'\x01')
ser.write(b'\x01')
ser.write(b'\x01')
ser.write(b'\x01')
ser.write(b'\x01')
ser.write(b'\x00')
write_data(ser, 1, [])

