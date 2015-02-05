###########################################################################
#    Copyright (C) 2005, 2015 by Mark Kimsal
#    https://github.com/markkimsal
#
# Copyright: See LICENSE file that comes with this distribution
#
###########################################################################
import pygame
from pygame.locals import *
from pygame import font
import os

import supercubeslide

import supercubeslide
import gamemode
import playmode
import help
#import pause

class Modes_Attract (gamemode.Modes_GameMode):

	sprite = None
	isDead = 0
	isQuit = 0
	isHelp = 0
	myImage = None
	myFont  = None
	paintedOnce = 0

	def __init__(self, game):
		self.game = game
		self.myImage = pygame.image.load(supercubeslide.SCS.getFilename( os.path.join('..', 'media', 'loadingscreen.png')))
		self.myFont = font.Font(supercubeslide.SCS.getFilename(os.path.join('..', 'media','freesansbold.ttf')), 20)
		pass

	def enterMode(self):
		""" Reset variables
		"""
		print "entering attact mode"
		self.isDead = 0
		self.isQuit = 0
		self.isHelp = 0
		self.paintedOnce = 0
		pass

	def exitMode(self):
		pass

	def paint(self, g, field, wallpaper):
		if self.paintedOnce:
			return
##		g.fill( (255,255,255), (0,0,800,600))
##		g.fill( (255,0,255), (self.g_offset_x, self.g_offset_y, self.width, self.height))
		g.blit ( self.myImage, (0,0) )
		self.paintInstructions(g)
		pygame.display.update( (0,0,640,480))
		self.paintedOnce = 1
		pass

	def paintInstructions(self, g):
		#clear thought balloon
		g.fill( (255, 255, 255), (330, 60, 240, 120))
		text = self.myFont.render("Press [ENTER] to start.", 1, (0,0,0)  )
		text2 = self.myFont.render("[N] for Next song", 1, (50,50,50)  )
		text3 = self.myFont.render("[H] for Help", 1, (50,50,50)  )
		g.blit ( text,  ( (330,77) ) )
		g.blit ( text2, ( (330,127) ) )
		g.blit ( text3, ( (330,157) ) )

	def update(self, field, window):
		if (self.isDead == 1):
			return self.getNextMode()
		if (self.isHelp == 1):
			return self.getNextMode()

		if (self.isQuit == 1):
			return -1
		pass

	def getNextMode(self):
		#return -1
		#return modes.pause.Modes_Pause(self.game)

		if (self.isDead == 1):
			return playmode.Modes_Play(self.game)

		if (self.isHelp == 1):
			helpMode = help.Modes_Help(self.game)
			helpMode.attractMode = self
			return helpMode

	def onKey(self,evt):
		if (evt.type == KEYDOWN and evt.key == K_RETURN ):
			self.isDead = 1
			return 0
		if (evt.type == KEYDOWN and evt.key == K_ESCAPE ):
			self.isQuit = 1
			return 0

		if (evt.type == KEYDOWN and evt.key == K_h ):
			self.isHelp = 1
			return 0

		return -1
