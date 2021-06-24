#!/bin/python

import RPi.GPIO as GPIO
import os
import time

gpio_pin_number=3
GPIO.setmode(GPIO.BCM)
GPIO.setup(gpio_pin_number, GPIO.IN)

while 1:
       	time.sleep(0.5)
        print GPIO.input(3) 

GPIO.cleanup()
