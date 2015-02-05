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

import SCS, os


class spritetext:

	messageList = []
	fontHeight  = 32

	def __init__(self):
		from pygame import font
		self.myFont = font.Font(SCS.getFilename(os.path.join('..', 'media','freesansbold.ttf')), 32)

	def update(self, game):
		g = game.window
		for m in self.messageList:
			#print m, m['txt']
			text = self.myFont.render(m['txt'], 100, (150,150,150) )
			#set the width and height the first time only
			if (m['x'] ==0):
				m['x'] = textWid =  320 -( text.get_width()/2) -50
				m['y'] = 50


			m['tick']+=1
			#overlayScreen = pygame.Surface( (g.get_width(), g.get_height()),  SRCALPHA).convert_alpha()
			#overlayScreen.blit ( text,  ( (textWid,200) ) )
			#game.window.blit(overlayScreen, (0,0))
			game.window.blit(text, (m['x'], m['y']))
			#self.paintedOnce = True
			#print m
			if (m['tick'] > 100):
				print "removing last message"
				self.messageList.remove(m)

	
	def addMessage(self, m):
		#bump all other messages up
		for q in self.messageList:
			q['y'] -= 32

		item = {'txt': m, 'x':0, 'y':0, 'tick':0}
		self.messageList.append(item)

