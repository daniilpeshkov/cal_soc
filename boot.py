from turtle import st
import serial

escape_list = [b'\x00',b'\x7e', b'\x01']

def write_data(ser, start_addr : int, data):
    for i in b'\x01' + start_addr.to_bytes(4, 'big'):
        ser.write(bytes([i]))
    
    while (byte := data.read(1)):
        if byte in escape_list:
            ser.write(b'\x7e')
        ser.write(byte)
        print(byte)
    ser.write(b'\x00')


ser = serial.Serial('COM6', 9600)
with open('firmware/test.bin', 'rb') as bin_f:
    write_data(ser, 0x04000000, bin_f)
