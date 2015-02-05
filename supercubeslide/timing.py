###########################################################################
#    Copyright (C) 2005, 2015 by Mark Kimsal
#    https://github.com/markkimsal
#
# Copyright: See LICENSE file that comes with this distribution
#
###########################################################################
import pygame

deltaTic    = 0.00;
worldTic    = 0.00;
frameRate   = 70;
clock = pygame.time.Clock()

def getDeltaTime():
	global deltaTic, frameRate, worldTic
	#deltaTic = clock.tick() / 1000.00
	worldTic += clock.get_rawtime() / 1.00
	return deltaTic

def calcDeltaTime():
	global deltaTic, frameRate, worldTic
	deltaTic = clock.tick(40) / 1000.00

