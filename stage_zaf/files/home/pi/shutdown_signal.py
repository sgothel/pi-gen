#!/bin/python

import RPi.GPIO as GPIO
import time
GPIO.setmode(GPIO.BCM)
GPIO.setup(26, GPIO.OUT)
GPIO.output(26, GPIO.LOW)
time.sleep(0.5)
GPIO.output(26, GPIO.HIGH)
#GPIO.cleanup()
