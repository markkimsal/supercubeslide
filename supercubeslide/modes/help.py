###########################################################################
#    Copyright (C) 2005, 2015 by Mark Kimsal
#    https://github.com/markkimsal
#
# Copyright: See LICENSE file that comes with this distribution
#
###########################################################################
import pygame, os
from pygame.locals import *
from pygame import font

import supercubeslide
#import SCS
#import modes
#from modes import gamemode
import supercubeslide.modes.gamemode as gamemode

import supercubeslide.bgmusic

class Modes_Help (gamemode.Modes_GameMode):

	sprite = None
	isDead = 0
	isQuit = 0
	myFont = None
	myGame = None
	attractMode = None
	paintedOnce = False

	def __init__(self, game):
		from pygame import font
		self.myImage = pygame.image.load(supercubeslide.SCS.getFilename( os.path.join('..', 'media', 'help.png')))
		self.myGame = game
		pass

	def enterMode(self):
		print("entering pause mode")
		pass

	def exitMode(self):
		pass

	def paint(self, g, field, wallpaper):
		if self.paintedOnce:
			return
		#g.blit( wallpaper, (0,0))
		#whiteScreen = g.convert_alpha()
		#whiteScreen.fill( (250, 250, 250, 220), (0,0,800,600))
		#g.blit( whiteScreen, (0,0))
		#text = self.myFont.render("Paused", 0, (0,0,0) )
		#text2 = self.myFont.render("(~Q to quit~)", 1, (0,0,0) )

		#textWid =  320 -( text.get_width()/2) 
		#text2Wid = 320 -( text2.get_width()/2) 
		#g.blit ( text,  ( (textWid,200) ) )
		#g.blit ( text2, ( (text2Wid,240) ) )
		g.blit ( self.myImage, (0,0) )
		pygame.display.update( (0,0,800,600))

		self.paintedOnce = True

	def update(self, field, window):
		if (self.isQuit == 1):
			return -1

		if (self.isDead == 1):
			supercubeslide.bgmusic.unpauseSong()
			return self.getNextMode()
		pass

	def getNextMode(self):
		#return -1
		return self.attractMode


	def onKey(self,evt):
		if (evt.type == KEYDOWN ):
			self.isDead = 1

		if (evt.type == QUIT or (evt.type == KEYDOWN and evt.key == K_q) ):
			self.isQuit = 1

		if evt.type == MOUSEBUTTONDOWN:
			self.isDead = 1
