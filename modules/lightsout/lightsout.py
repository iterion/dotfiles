import time
from datetime import datetime
from phue import Bridge

# IP address of your Hue Bridge
BRIDGE_IP = '192.168.1.200'

# Light ID you want to control
LIGHT_ID = "Desk Lamp"  # Adjust this to the ID of the light you want to control

def main():
    bridge = Bridge(BRIDGE_IP)
    
    # If the bridge button has not been pressed in the last 30 seconds, press it before running this script
    # bridge.connect()
    # lights = bridge.lights

    # # Print light names
    # for l in lights:
    #   print(l.id)
    #   print(l.name)
    
    current_time = datetime.now()
    # Check if current time is after 9 PM
    if current_time.hour >= 21 and current_time.minute >= 30 and bridge.get_light(LIGHT_ID, 'on'):
        # Turn off the light
        bridge.set_light(LIGHT_ID, 'on', False)
        print(f"Light {LIGHT_ID} turned off at {current_time.strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    main()
