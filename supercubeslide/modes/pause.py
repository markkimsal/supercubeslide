###########################################################################
#    Copyright (C) 2005, 2015 by Mark Kimsal
#    https://github.com/markkimsal
#
# Copyright: See LICENSE file that comes with this distribution
#
###########################################################################
import pygame, os
from pygame.locals import *

#import SCS
import supercubeslide
import gamemode
#from modes import gamemode
from pygame import font

import supercubeslide.bgmusic

class Modes_Pause (gamemode.Modes_GameMode):

	sprite = None
	isDead = 0
	isQuit = 0
	myFont = None
	myGame = None
	playMode = None
	paintedOnce = False

	def __init__(self, game):
		from pygame import font
		from supercubeslide import bgmusic
		#self.myFont = pygame.font.SysFont('arial',32)
		self.myFont = font.Font(supercubeslide.SCS.getFilename(os.path.join('..', 'media','freesansbold.ttf')), 32)
		self.myGame = game
		bgmusic.pauseSong()
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
		whiteScreen = g.convert_alpha()
		whiteScreen.fill( (250, 250, 250, 220), (0,0,800,600))
		g.blit( whiteScreen, (0,0))
		text = self.myFont.render("Paused", 0, (0,0,0) )
		text2 = self.myFont.render("(~Q to quit~)", 1, (0,0,0) )

		textWid =  320 -( text.get_width()/2) 
		text2Wid = 320 -( text2.get_width()/2) 
		g.blit ( text,  ( (textWid,200) ) )
		g.blit ( text2, ( (text2Wid,240) ) )
		pygame.display.update( (0,0,800,600))
		self.paintedOnce = True

	def update(self, field, window):
		from supercubeslide import bgmusic
		if (self.isQuit == 1):
			return -1


		if (self.isDead == 1):
			bgmusic.unpauseSong()
			return self.getNextMode()
		pass

	def getNextMode(self):
		#return -1
		return self.playMode


	def onKey(self,evt):
		if (evt.type == KEYDOWN ):
			self.isDead = 1

		if (evt.type == QUIT or (evt.type == KEYDOWN and evt.key == K_q) ):
			self.isQuit = 1

		if evt.type == MOUSEBUTTONDOWN:
			self.isDead = 1
