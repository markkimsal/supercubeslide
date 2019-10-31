###########################################################################
#    Copyright (C) 2005, 2015 by Mark Kimsal
#    https://github.com/markkimsal
#
# Copyright: See LICENSE file that comes with this distribution
#
###########################################################################
import pygame
from pygame.locals import *

import supercubeslide
import supercubeslide.timing as timing
#import SCS
#import timing
#import modes
#from modes import gamemode
import supercubeslide.modes.gamemode as gamemode
import supercubeslide.modes.leveldone as leveldone
import supercubeslide.modes.pause as pause


class Modes_Play (gamemode.Modes_GameMode):

	sprite = None
	isDead   = 0
	isPaused = 0
	field = None
	myGame = None
	removedLastUpdate = 0
	chain = 0
	textBoard = None

	def __init__(self,game):
		self.updates = []
		self.myGame = game
		pass

	def enterMode(self):

		if (self.isPaused == 1):
			print("unpausing")
			self.isPaused = 0
			return 

		pygame.display.update( (0,0,800,600) )
		pygame.display.flip()

		self.myGame.field.clearAll()
		self.myGame.populateField()
		clock = self.myGame.getGameClock()
		clock.reset()
		print("entering play mode")

		import supercubeslide.spritetext as spritetext
		self.textBoard = spritetext.spritetext()
		self.myGame.addToLoopStack(self.textBoard, 'spritetext')
		pass

	def exitMode(self):
		pass

	def paint(self, g, field, wallpaper):
		"""paint happens after the update, it is 
		called from SCS
		"""

		#pygame.display.update(self.updates)
		g.blit( wallpaper, (0,0) )

		#field.debugPaint( g )
		#field.debugPaint( g, self.updates )
		#sprite.paint(window)
		sprite = self.myGame.sprite
		sprite.paint(g)

		clock = self.myGame.getGameClock()
		g.blit( clock.getSurface(), (568, 130))
		clockposition = (568, 130, 39, 141)

		score = self.myGame.getScoreBoard()
		#text must be right-aligned
		rect = score.getSurface().get_rect()
		position = (616 - rect[2], 52)
		g.blit( score.getSurface(), position)
		#print("blitting score, ", score.getSurface().get_rect())
		#g.fill( (255, 0, 0), score.getSurface().get_rect())
		scoreposition = (616 - rect[2], 52, 39, 141)

		#testing to see if multiple updates is better than 1 big update
		#self.updates = self.updates.unionall( (self.updates,field.paintActors(g, self.updates)) )
		#pygame.display.update(self.updates)
		#pygame.display.update(scoreposition)
		#pygame.display.update(clockposition)

		self.updates = self.updates.unionall( (self.updates,field.paintActors(g, self.updates), scoreposition, clockposition) )
		pygame.display.update(self.updates)
		pass


	def update(self, field, window):
		"""remove window from param list
			refactor into paint / update commands
		"""
		if (self.isDead == 1):
			return -1

		if (self.isPaused == 1):
			return self.pauseEvent()

		deltaTic = timing.getDeltaTime()
		self.sprite = self.myGame.sprite
		self.updates = pygame.Rect( (self.sprite.x_pos,self.sprite.y_pos,24,24) )


		#window.blit( wallpaper, (0,0) )
		#field.debugPaint( window, self.updates)
		self.sprite.update(field)

		#if the clock is empty, add a row to the play field
		clock = self.myGame.getGameClock()
		if clock.isClockEmpty():
			#print("# You should be getting more rows now")
			self.myGame.field.addNewRowOrCol()

		##if the field is dirty, that means
		# the player cleared a row, reset the time 
		# before calling "resolveField"
		if field.needsCompact == 1:
			clock.reset()
		else:
			if not field.hasDeadActors():
				clock.updateTicks(deltaTic)

		if(field.updatePerTurn() == True):
			removedBlocks = self.myGame.field.resolveField(self.sprite)
			if (removedBlocks and removedBlocks > 0):
				self.chain+=1

			if (removedBlocks and removedBlocks > 0):
				if (self.chain > 1):
					self.textBoard.addMessage("Chain x"+ str(self.chain)+ "!")
					self.myGame.addMessage("Chain x"+ str(self.chain)+ "!")
				self.myGame.addScore(removedBlocks * self.chain)
				#print("*** removed %d blocks" % removedBlocks)
			self.removedLastUpdate = removedBlocks


		if ( field.noMoreMoves()):
			return leveldone.Modes_LevelDone(self.myGame)

		if (len(field.immobiles) < 1):
			return leveldone.Modes_LevelDone(self.myGame)

	def moveSpriteEvent(self):
		newSprite = self.sprite.processAction(self.field)
		#print("*** Removing CHAIN! ")
		self.removedLastUpdate = 0
		self.chain = 0
		return newSprite


	def pauseEvent(self):
		pauseMode = pause.Modes_Pause(self.myGame)
		pauseMode.playMode = self
		return pauseMode

	def onKey(self,evt):
		if (evt.type == QUIT):
			print('got quit event')
			self.isDead = 1

		if ((evt.type == KEYDOWN and evt.key == K_ESCAPE) ):
			print('got pause event')
			self.isPaused = 1
		if (evt.type == KEYDOWN and evt.key == K_RIGHT):
			self.sprite.h_velocity = 1
			self.sprite.is_accelerating = 1
		if (evt.type == KEYDOWN and evt.key == K_LEFT):
			self.sprite.h_velocity = -1
			self.sprite.is_accelerating = 1
		if (evt.type == KEYUP and (evt.key == K_RIGHT or evt.key == K_LEFT)):
			#sprite.is_accelerating = 0
			self.sprite.h_velocity=0
		if (evt.type == KEYDOWN and evt.key == K_UP):
			self.sprite.v_velocity = 1
			self.sprite.is_accelerating = 1
		if (evt.type == KEYDOWN and evt.key == K_DOWN):
			self.sprite.v_velocity = -1
			self.sprite.is_accelerating = 1
		if (evt.type == KEYUP and (evt.key == K_UP or evt.key == K_DOWN)):
			#sprite.is_accelerating = 0
			self.sprite.v_velocity=0
		if (evt.type == KEYDOWN and evt.key == K_F12):
			self.myGame.populateField()
			pygame.display.update()

		if (evt.type == KEYDOWN and evt.key == K_RETURN):
			if not self.myGame.field.hasDeadActors():
				self.myGame.field.addNewRowOrCol()
				clock = self.myGame.getGameClock()
				clock.reset()


		if evt.type == MOUSEBUTTONDOWN:
			if evt.dict['button'] == 4:
				#print('Wheel Down')
				self.sprite.clockwise_velocity = 1
				#self.sprite.moveCW(self.field)
			elif evt.dict['button'] == 5:
				#print('Wheel Up')
				self.sprite.clockwise_velocity = -1
				#self.sprite.moveCCW(self.field)
			elif evt.dict['button'] == 3:
				#right click adds more blocks
				self.myGame.field.addNewRowOrCol()
				clock = self.myGame.getGameClock()
				clock.reset()
			else:
				if not self.myGame.field.hasDeadActors():
					newSprite = self.moveSpriteEvent()
					#newSprite = self.sprite.processAction(self.field)
					if ( newSprite is not None ) :
						self.sprite = newSprite
						self.myGame.setSprite(newSprite)
						self.myGame.field.resolveField(self.sprite)


		if (evt.type == KEYDOWN and evt.key == K_SPACE):
			"""check to make sure that the playfield
			   doesn't have dead cubes.  player can move
			   but not do actions when the playfield is in a
			   state of resolve
			"""
			if not self.myGame.field.hasDeadActors():
				newSprite = self.moveSpriteEvent()
				#newSprite = self.sprite.processAction(self.field)
				if ( newSprite is not None ) :
					self.sprite = newSprite
					self.myGame.setSprite(newSprite)
					self.myGame.field.resolveField(self.sprite)
		return -1
