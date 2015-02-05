#!/usr/bin/python
###########################################################################
#    Copyright (C) 2005, 2015 by Mark Kimsal
#    https://github.com/markkimsal
#
# Copyright: See LICENSE file that comes with this distribution
#
###########################################################################
import pygame
from pygame.locals import *
import pygame.font
from pygame.font import Font
import pygame.cursors

import os
import sys
import random
import time

import playfield
import timing
import sprite
from sprite import SCS_sprite

import gameclock
from gameclock import SCS_gameclock

import gamescore
from gamescore import SCS_gamescore


#import supercubeslide.modes
from supercubeslide.modes import *
#from supercubeslide.modes import attract

import bgmusic

if hasattr(sys, 'frozen'):
	SCS_fullpath = os.path.dirname(os.path.abspath(sys.executable))
else:
	SCS_fullpath = os.path.dirname(os.path.abspath(__file__))

def getFilename(relative):
	global SCS_fullpath
	dirs = os.path.split(relative)
	fullpath = ''

	for x in dirs:
		fullpath = os.path.join(fullpath, x)

	fullpath = os.path.join(SCS_fullpath, fullpath)
	return fullpath



class SCS_Game:
	sprite = None
	field  = None
	clock  = None
	score  = None
	window = None
	loopStack = {}
	points = 0
	difficulty = 2
	startTall = 4
	startWide = 4
	maxWidth  = 10
	bgmusicIdx = 2
	
	def __init__(self, field):
		self.field = field
		self.clock = SCS_gameclock(self, self.difficulty*2)
		self.score = SCS_gamescore(self)

	def setSprite(self, sprite):
		self.sprite = sprite

	def addMessage(self, msg):
		pass
		#print msg

	def increaseDifficulty(self):
		self.difficulty += 1
		if (self.startTall < self.maxWidth):
			self.startTall += 1
			self.startWide += 1
		#don't try to make the timer go faster
		#only increasing speed can make the game too hard
		#if (self.difficulty <= 5):
		#	self.clock.speed = self.difficulty*2

	def populateField(self):
		tall = self.startTall
		wide = self.startWide
		#field is 19x16
		leftCorner = (19/2) - (wide/2) + 0
		upperCorner = (16/2) - (tall/2) + 0
		

		sprite =  SCS_sprite(pygame.image.load(getFilename( '../media/block_d.png')), 'blue')
		sprite.isMobile = 1;
		self.setSprite(sprite)

		field = self.field
		field.clearAll()
		#print "sprite is mobile: ", self.sprite.isMobile
		#print "sprite x: ", self.sprite.x_pos
		field.addToGrid(self.sprite, leftCorner-1, upperCorner)
		#print "sprite x: ", self.sprite.x_pos

		colors = (('red','b'),('green','a'),('orange','c'),('blue','d'))
		for x in range(leftCorner, leftCorner+wide):
			for y in range(upperCorner, upperCorner+tall):
	#			print x ,', ',y
				set = colors[random.randint(0,3)]
				block = SCS_sprite(pygame.image.load(getFilename('../media/block_'+set[1]+'.png')),set[0] )
				field.addToPlayfield(block, (x*24)+32, (y*24)+32)
		field.needsCompact = 0

	def getGameClock(self):
		return self.clock

	def getScoreBoard(self):
		return self.score

	def getPoints(self):
		return self.points

	def addScore(self, num):
		self.points += num
		self.getScoreBoard().update()
		#print "points is now %d ..." % self.points

	def subScore(self, num):
		self.points -= num
		self.getScoreBoard().update()

	def handleGlobalEvent(self, evt):
		if ((evt.type == KEYDOWN and evt.key == K_n) ):
			self.bgmusicIdx +=1
			if (self.bgmusicIdx > 2):
				self.bgmusicIdx = 0
			bgmusic.startSong(self.bgmusicIdx)


	def update(self):
		for k,x in self.loopStack.items():
			x.update(self)

	def addToLoopStack(self, item, name):
		self.loopStack[name] = item

	def removeFromLoopStack(self, name):
		del self.loopStack[name]


if __name__ == '__main__':

	#print 'first time ', SCS_fullpath
	run()


def run():
	pygame.init()
	pygame.display.init()
	window = pygame.display.set_mode( (640,480), RESIZABLE )
	pygame.display.set_caption('Super Cube Slide')


	bgfile = getFilename('../media/background.png')
#	bgfile = os.path.join(SCS_fullpath, 'media', 'background.png')
	wallpaper =  pygame.image.load(bgfile)
	#window.blit( wallpaper, (0,0))

	field = playfield.playfield(480,408,32,32)
	game = SCS_Game(field)
	game.window = window

	#field.debugPaint( window )

	#sprite =  SCS_sprite(pygame.image.load(fullpath + 'media/block_d.png'), 'blue')
	#sprite.isMobile = 1;
	#game.setSprite(sprite)

	pygame.display.update()

	
	bgmusic.startSong(game.bgmusicIdx)
	currentMode = attract.Modes_Attract(game);
	#currentMode.sprite = sprite
	newMode = None
	#pygame.fastevent.init()
	#print currentMode
	currentMode_onKey = currentMode.onKey

	noop = pygame.locals.NOEVENT
	evt_peek = pygame.event.peek
	evt_poll = pygame.event.poll

	while (1):
		#only call this once per game loop
		timing.calcDeltaTime()
		if not evt_peek():
			time.sleep(.01)
			#continue
		evt = evt_poll()
		pygame.event.clear((pygame.locals.MOUSEMOTION, pygame.locals.ACTIVEEVENT))

		if evt.type != noop:
			mods = pygame.key.get_mods()
			if not mods:
				if currentMode_onKey(evt) == -1:
					game.handleGlobalEvent(evt)
			else:
				"""Handle key presses the same if NUM or CAPS is on"""
				if mods & pygame.KMOD_NUM or mods & pygame.KMOD_CAPS:
					if currentMode_onKey(evt) == -1:
						game.handleGlobalEvent(evt)


		newMode = currentMode.update(field, window)

		if (newMode == -1):
			print 'quitting...'
			pygame.quit()
			break

		#switching modes
		if (newMode is not None):
			currentMode = newMode
			currentMode.field = field
			currentMode.enterMode()
			currentMode.update(field,window)
			currentMode.paint(window, field, wallpaper)
			currentMode_onKey = currentMode.onKey
			#pygame.display.update( (0,0,800,600) )
			pygame.display.flip( )
			continue
		currentMode.paint(window, field, wallpaper)
		game.update()
		pygame.display.update( (0,0,800,600))
		#pygame.fastevent.pump()
