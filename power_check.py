#!/usr/bin/env python3
import os, sys
import mariadb
import datetime #new
import time
import board, busio
import adafruit_ads1x15.ads1015 as ADS
from adafruit_ads1x15.analog_in import AnalogIn

from python_mysql_dbconfig import read_db_config
dbconfig = read_db_config()
conn = None
try:
   conn = mariadb.connect(**dbconfig)
   cursor = conn.cursor()
except mariadb.Error as e:
   print(f"Error connecting to MariaDB Platform: {e}")
   sys.exit(1)

try:
   def add_data(cursor,volt,mA):
      """Adds the given data to the power table"""
      sql_insert_query = (f'INSERT INTO power_check ( volt, amp) VALUES ({volt:.3f},{amp:.4f})')
      cursor.execute(sql_insert_query)
      conn.commit()

except mariadb.Error as e:
   print(f"Error adding data to Maridb: {e}")
   sys.exit(1)

# Voltage is a diff voltage between 0 and middle of power divider, battery voltage divided by 4.
# Multiply with 4 to get volt which reflect true battery voltage
# amp measures diff voltage measure U = R x I , R= 0,0025 Ohm -> I = U/R
# multiplied with 400 gives AMP into Regattastart -> I = U*400

# Create the I2C bus
i2c = busio.I2C(board.SCL, board.SDA)
# Create the ADC object using the I2C bus
ads = ADS.ADS1015(i2c)

# Create differential input between channel 0 and 1
amps = AnalogIn(ads, ADS.P0, ADS.P1)
# Create input channel 2 
batt = AnalogIn(ads, ADS.P2)

#To boost small signals, the gain can be adjusted on the ADS1x15 chips in the following steps:
#GAIN_TWOTHIRDS (for an input range of +/- 6.144V)
#// ads1015.setGain(GAIN_TWOTHIRDS); // 2/3x gain +/- 6.144V 1 bit = 3mV (default)
#// ads1015.setGain(GAIN_ONE);     // 1x gain   +/- 4.096V  1 bit = 2mV
#// ads1015.setGain(GAIN_TWO);     // 2x gain   +/- 2.048V  1 bit = 1mV
#// ads1015.setGain(GAIN_FOUR);    // 4x gain   +/- 1.024V  1 bit = 0.5mV
#// ads1015.setGain(GAIN_EIGHT);   // 8x gain   +/- 0.512V  1 bit = 0.25mV
#// ads1015.setGain(GAIN_SIXTEEN); // 16x gain  +/- 0.256V  1 bit = 0.125mV
cable_loss= 1000

print("{:>6.4}\t{:>6.4}".format('volt','mA' ))
while True:
   ads.gain = 8.0
   amp = amps.voltage / 0.0025 * cable_loss
   time.sleep(1.0)
   ads.gain = 2/3
   volt = batt.voltage * 4
   time.sleep(1.0)
   print("{:>6.4}\t{:g}".format(volt,amp))
   try:
     add_data(cursor,volt, amp)
   except mariadb.Error as e:
     print(f"Error inserting to db: {e}")
     sys.exit(1)
   time.sleep(4.0)
print(f"Last Inserted ID: {cursor.lastrowid}")
cursor.close()
conn.close()
