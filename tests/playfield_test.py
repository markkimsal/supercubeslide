import unittest
import pygame
from pygame.locals import *
import os, sys
sys.path.append("./")

import supercubeslide
import supercubeslide.playfield
#import supercubeslide.sprite
from supercubeslide.sprite import SCS_sprite


class TestPlayfieldFunctions(unittest.TestCase):

	def setUp(self):
		fullpath = "../"
		#import sys; sys.path.insert(0, "..")
		#sys.path.insert(0, ".")
		pygame.init()
		pygame.display.init()
		self.window = pygame.display.set_mode( (640,480), RESIZABLE )
		pygame.display.set_caption('Super Cube Slide')

		wallpaper =  pygame.image.load('./media/background.png')
		self.window.blit( wallpaper, (0,0) )

		self.field = supercubeslide.playfield.playfield(480,408,32,32)

	def testStuff(self):
		img = pygame.image.load('./media/block_a.png')
		imgb = pygame.image.load('./media/block_b.png')
		block1 = SCS_sprite(img, 'red' )
		block2 = SCS_sprite(img, 'red' )
		block3 = SCS_sprite(img, 'red' )
		block4 = SCS_sprite(imgb, 'blue' )

		self.field.addToGrid(block1, 8, 9)
		self.field.addToGrid(block2, 9, 9)
		self.field.addToGrid(block3, 10, 9)
		self.field.addToGrid(block4, 10, 10)

		self.field.debugPaint( self.window, None )
		pygame.display.update()

		block1.paint(self.window)
		block2.paint(self.window)
		block3.paint(self.window)
		block4.paint(self.window)
		pygame.display.update()

		self.field.resolveField(None)

		''' block 4 should not be dead, it is
		a different color in a different row
		'''

		self.assertEqual(block1.isDead, 1)
		self.assertEqual(block2.isDead, 1)
		self.assertEqual(block3.isDead, 1)
		self.assertEqual(block4.isDead, 0)

		#self.field.paintActors(self.window, pygame.Rect(0 ,0 ,640 ,480 ))
		#print self.field.needsRemoving

		import time
		time.sleep(2)
		pass


if __name__ == '__main__':
	fullpath = ''
	dirs = os.path.split(__file__)
	y = 0
	for x in dirs:
		if y == len(dirs) - 1:
			break
		y+=1
		fullpath = fullpath + x + os.sep 

	unittest.main()
