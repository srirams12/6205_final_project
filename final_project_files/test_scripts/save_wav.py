import serial
import wave


# opens serial port, waits for 6 seconds of 8kHz audio data, writes it to output.wav

# set to proper serial port name and WAV!
# find the port name using test_ports.py
# CHANGE ME
SERIAL_PORT_NAME = "/dev/cu.usbserial-8874042402F51"
BAUD_RATE = 115200

ser = serial.Serial(SERIAL_PORT_NAME,BAUD_RATE)
print("Serial port initialized")

print("Recording 6 seconds of audio:")
ypoints = []
fs = 12500
for i in range(fs*6):
    val = int.from_bytes(ser.read(),'little')
    if ((i+1)%fs==0):
        print(f"{(i+1)/fs} seconds complete")
    ypoints.append(val)

with wave.open('output.wav','wb') as wf:
    wf.setframerate(fs)
    wf.setnchannels(1)
    wf.setsampwidth(1)
    samples = bytearray(ypoints)
    wf.writeframes(samples)
    print("Recording saved to output.wav")

