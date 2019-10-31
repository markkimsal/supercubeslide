###########################################################################
#    Copyright (C) 2005, 2015 by Mark Kimsal
#    https://github.com/markkimsal
#
# Copyright: See LICENSE file that comes with this distribution
#
###########################################################################

import pygame
import SCS

class SCS_gameclock():

	def __init__(self, game, speed=1):
		self.game = game
		self.fullTicks = 100
		self.currentTicks = self.fullTicks
		self.speed = speed
		i = pygame.image.load( SCS.getFilename('../media/gameclock.png'))
		self.originalImage = pygame.image.load(SCS.getFilename('../media/gameclock.png'))
		self.emptyImage = pygame.image.load(SCS.getFilename('../media/gameclock_empty.png'))
		self.image = i

	def updateTicks(self, ticks):
		if self.currentTicks <=0:
			self.reset()
		self.currentTicks = self.currentTicks - (self.speed * ticks)
		#repaint the clock graphic with more and more black
		pctEmpty = (100-self.currentTicks) * 1.41
		self.image.blit( self.emptyImage, (0, 0), pygame.Rect(0, 0, 39, pctEmpty))
		#print("# Game Clock ", self.currentTicks)

	def repaintSelf(self):
		self.image.blit(self.originalImage, (0, 0))

	def reset(self):
		self.currentTicks = self.fullTicks
		self.repaintSelf()

	def getSurface(self):
		return self.image

	def isClockEmpty(self):
		if self.currentTicks <= 0:
			return 1
		else:
			return 0

