import nest_asyncio
nest_asyncio.apply()

from bleak import BleakClient,BleakScanner
import asyncio
# import keyboard
import time
import math
import socket

UDP_IP = "127.0.0.1"
UDP_PORT = 5005
sock = socket.socket(socket.AF_INET, # Internet
                     socket.SOCK_DGRAM) # UDP

from pynput import keyboard
def on_press(key):
    global fAngleRefHor, fAngleRefVer
    global fAngleHor0, fAngleVer0
    if key == keyboard.Key.ctrl:
        print('{0} pressed'.format(key))
    try:
        print(fAngleHor0)
        print(fAngleRefHor)
        fAngleRefHor = fAngleHor0
        fAngleRefVer = fAngleVer0
        print('Angles calibrated')
    except AttributeError:
        print('keyboard error')
def on_release(key):
    print('{0} released'.format(key))
    # if key == keyboard.Key.esc:
    #     # Stop listener
    #     return False
listener = keyboard.Listener(on_press=on_press,on_release=on_release)
listener.start()

# Setup parameters
CHARACTERISTIC_UUID = ("6e400003-b5a3-f393-e0a9-e50e24dcca9e")
CHARACTERISTIC_UUID0 = ("6e400001-b5a3-f393-e0a9-e50e24dcca9e")

CHARACTERISTIC_UUID_BATTERY = ("2A19")

UUID = ('4073E736-34A2-DE62-E380-CF4676735C01') # MacOS, Joels Headtracker
#UUID = ('6EEE5B9E-675B-EED4-5645-D550A1FB63E2') # MacOS, Papa
#UUID = ('FB93ECFF-74BE-08AC-164A-F86F23026975') # MacOS, Headtracker_3
#UUID = ('DD3987EE-6709-CD9D-71A2-8B8260796DE8') # MacOS, Adafruit BNO 085


uuid_battery_service = '0000180f-0000-1000-8000-00805f9b34fb'
uuid_battery_level_characteristic = '00002a19-0000-1000-8000-00805f9b34fb'

fAngleRefHor        = 0.0
fAngleRefVer        = 0.0
fDuration           = 60*120
PI                  = 3.141592653589793
time1               = 0
iCounter            = 0

def notification_handler(sender,data):
    global fAngleRefHor, fAngleRefVer
    global fAngleHor0, fAngleVer0
    global sock, UDP_IP, UDP_PORT    
    if data!=b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00':
        data = int.from_bytes(data, byteorder='little', signed=False)
        fAngleVer0 = math.floor(data/pow(2,13))
        fAngleHor0 = data-fAngleVer0*pow(2,13)   
        fAngleHor0 = 180/PI*fAngleHor0/1000
        fAngleVer0 = 180/PI*fAngleVer0/100
        fAngleHor = (fAngleHor0-fAngleRefHor-180) % 360 - 180;
        fAngleVer = (fAngleVer0-fAngleRefVer-180) % 360 - 180;   
        fAngleHor = '%+8.3f' % fAngleHor
        fAngleVer = '%+8.3f' % fAngleVer
        bAngleHor   = bytes(fAngleHor, 'utf-8')
        bAngleVer   = bytes(fAngleVer, 'utf-8')
        sock.sendto(bAngleHor+bAngleVer, (UDP_IP, UDP_PORT))
        print(bAngleHor)
        print(fAngleHor0)

    
async def run(address):
    scanner = BleakScanner(service_uuids=[CHARACTERISTIC_UUID0])
    devices = await scanner.discover(service_uuids=[CHARACTERISTIC_UUID0])
    for d in devices:
        print("Device details: ", d.details)
    async with BleakClient(address_or_ble_device=devices[0]) as client:
        print("Device details: ", devices[0].details)        
        global fAngleRefHor, fAngleRefVer
        conn = await client.connect()
        print(conn)
        print('Connected to headtracker ...')

        #print('Try to read battery level')
        #battery_level = await client.read_gatt_char(uuid_battery_level_characteristic)
        #battery_level = int.from_bytes(battery_level, byteorder='big')
        #print('Battery level: ',str(battery_level),'%')
        #print('Battery level read')
        
        bInitAngles = False
        await client.start_notify(CHARACTERISTIC_UUID, notification_handler)
        print('Notification handler started ...')
        time.sleep(1.0)
        while not bInitAngles:
            print('Try to read initial values ...')
            data = await client.read_gatt_char(CHARACTERISTIC_UUID)
            data=b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01'
            if data!=b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00':
                data = int.from_bytes(data, byteorder='little', signed=False)
                fAngleRefVer = math.floor(data/pow(2,13))
                fAngleRefHor = data-fAngleRefVer*pow(2,13)
                fAngleRefHor = 180/PI*fAngleRefHor/1000
                fAngleRefVer = 180/PI*fAngleRefVer/100
                bInitAngles = True
                print('Initial values read ...')
        #await client.start_notify(CHARACTERISTIC_UUID, notification_handler)
        print('Headtracker notification started ...')
        print('Press alt+c to center ...')
        await asyncio.sleep(fDuration, loop=loop)
        await client.stop_notify(CHARACTERISTIC_UUID)
        print('Headtracker notification stopped ...')
        print("End headtracker session!")
        
       
# Main function
if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    # loop = asyncio.get_running_loop()
    loop.run_until_complete(run(UUID))
    loop.close()