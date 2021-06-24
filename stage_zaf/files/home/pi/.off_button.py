#!/bin/python

import RPi.GPIO as GPIO
import os
import time

gpio_pin_number=3
GPIO.setmode(GPIO.BCM)
GPIO.setup(26, GPIO.OUT)
GPIO.output(26, GPIO.HIGH)
GPIO.setup(gpio_pin_number, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
buttonState=1
buttonCounter=0
while 1:
	time.sleep(0.005)
	reading = GPIO.input(gpio_pin_number)
	if reading!=buttonState:
		buttonCounter=buttonCounter+1
	else:
		buttonCounter=0
	if buttonCounter>50:
		if reading!=buttonState:
			buttonState=reading
			buttonCounter=0
	if buttonState==0:
		os.system("shutdown -h now")
		

GPIO.cleanup()
