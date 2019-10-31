###########################################################################
#    Copyright (C) 2005, 2015 by Mark Kimsal
#    https://github.com/markkimsal
#
# Copyright: See LICENSE file that comes with this distribution
#
###########################################################################
import pygame, os
from pygame.locals import *

import supercubeslide
#import SCS
#import modes
#from modes import gamemode
import gamemode
import playmode
from pygame import font

class Modes_LevelDone (gamemode.Modes_GameMode):

	sprite = None
	isDead = 0
	myFont = None
	myGame = None
	myPoints = 15
	paintedOnce = False

	def __init__(self, game):
		from pygame import font
		#self.myFont = pygame.font.SysFont('arial',32)
		self.myFont = font.Font(supercubeslide.SCS.getFilename(os.path.join('..', 'media','freesansbold.ttf')), 32)
		self.myGame = game
		pass

	def enterMode(self):
		#print("entering level done mode")
		pass

	def exitMode(self):
		pass

	def paint(self, g, field, wallpaper):
		if self.paintedOnce:
			return
		pausedScreen = g.convert_alpha()
		overlayScreen = pygame.Surface( (g.get_width(), g.get_height()),  SRCALPHA).convert_alpha()

		#print("level done paint")
		overlayScreen.fill( (255,255,255, 220), (0,0,800,600))
		#g.fill( (255,0,255), (self.g_offset_x, self.g_offset_y, self.width, self.height))
		text = self.myFont.render("Level Done", 1, (0,0,0)  )
		text2 = self.myFont.render("(~15 points!~)", 1, (0,0,0)  )

		textWid =  320 -( text.get_width()/2) 
		text2Wid = 320 -( text2.get_width()/2) 
		#g.blit ( text,  ( (200,200) ) )
		overlayScreen.blit ( text,  ( (textWid,200) ) )
		overlayScreen.blit ( text2, ( (text2Wid,240) ) )
		g.blit(overlayScreen, (0,0))
		#pygame.display.update( (0,0,800,600))
		self.paintedOnce = True

	def update(self, field, window):
		if (self.isDead == 1):
			return self.getNextMode()
		pass

	def getNextMode(self):
		#return -1

		self.myGame.addScore(15)
		self.myGame.increaseDifficulty()
		return playmode.Modes_Play(self.myGame)

	def onKey(self,evt):
		if (evt.type == KEYDOWN ):
			self.isDead = 1
		if (evt.type == QUIT or (evt.type == KEYDOWN and evt.key == K_ESCAPE) ):
			self.isDead = 1

		if evt.type == MOUSEBUTTONDOWN:
			self.isDead = 1
