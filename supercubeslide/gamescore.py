###########################################################################
#    Copyright (C) 2005, 2015 by Mark Kimsal
#    https://github.com/markkimsal
#
# Copyright: See LICENSE file that comes with this distribution
#
###########################################################################

import pygame
import SCS
import os

class SCS_gamescore():

	def __init__(self, game):
		self.myGame = game
		from pygame import font
		#self.myFont = pygame.font.SysFont('arial',32)
		self.myFont = font.Font(SCS.getFilename(os.path.join('..', 'media', 'freesansbold.ttf')), 18)
		#print("Points is ", self.myGame.getPoints())
		self.image = self.myFont.render( "%d" % self.myGame.getPoints(), True, (240, 140, 140) )

	def update(self):
		self.image = self.myFont.render( "%d" % self.myGame.getPoints(), True, (240, 140, 140) )

	def getSurface(self):
		#print("Score, get surface")
		return self.image


