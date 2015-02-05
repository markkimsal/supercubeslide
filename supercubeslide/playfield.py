###########################################################################
#    Copyright (C) 2005, 2015 by Mark Kimsal
#    https://github.com/markkimsal
#
# Copyright: See LICENSE file that comes with this distribution
#
###########################################################################
import sprite
from sprite import SCS_sprite
from sprite import SCS_magnetSprite
import SCS

import pygame, os
import numpy
from numpy import array

class playfield:
	"""Playfield for cubes
	"""
	def __init__(self, width, height, x, y):

		global SCS
		from pygame import font
		self.width = width
		self.height = height
		self.x_size = 24
		self.y_size = 24
		self.actors = []
		self.immobiles = []
		self.g_offset_x = x
		self.g_offset_y = y
		self.isDirty = 0
		#self.newGrid = numpy.array( [[None]*(height/self.y_size)]*(width/self.x_size), numpy.PyObject)
		self.newGrid = numpy.array( [[None]*(height/self.y_size)]*(width/self.x_size))
		self.clearGrid()
		self.needsCompact = 0
		self.needsRemoving = []
		self.missingColumn = None
		self.missingRow = None
		#self.f = font.Font('../media/fonts/arial.ttf',9)
		#self.f = font.Font('freesansbold.ttf',9)
		self.f = font.Font(SCS.getFilename(os.path.join('..', 'media', 'freesansbold.ttf')), 15)
		#self.f = font.SysFont('arial',9)
		self.intUpd = pygame.Rect((0,0,0,0));


	def reset(self):
		self.actors        = []
		self.immobiles     = []
		self.needsRemoving = []
		self.missingColumn = None
		self.missingRow    = None
		self.newGrid = numpy.array( [[None]*(height/self.y_size)]*(width/self.x_size), numpy.PyObject)

	def clearAll(self):
		self.actors        = []
		self.immobiles     = []
		self.needsRemoving = []
		self.missingColumn = None
		self.missingRow    = None
		#$self.newGrid = numpy.array( [[None]*(self.height/self.y_size)]*(self.width/self.x_size), numpy.PyObject)
		self.clearGrid()


	def addToGrid(self, actor, x, y):
		self.addToPlayfield(actor, (x * self.x_size)+self.g_offset_x, (y * self.y_size)+self.g_offset_y)


	def addToPlayfield(self, actor, x, y):
		actor.x_pos = x
		actor.y_pos = y
		#print "actor = (" , actor.x_pos, ", ", actor.y_pos,") "
		actor.isDirty = 1
		if (actor.isMobile == 1):
			#print "got a mobile actor"
			self.actors.append(actor)
		else:
			#self.checkForPlayer( (actor.x_pos, actor.y_pos) )
			self.immobiles.append(actor)
		self.isDirty = 1


	def checkForPlayer(self, xypos):
		player = self.actors[0]

		if (player.x_pos == xypos[0]
				and player.y_pos == xypos[1]):
			player.moveOutward(self)

	def scheduleRemove(self,actor):
		self.needsRemoving.append(actor)


	def removeFromPlayfield(self,actor):
		if (actor is None): return;
		if (actor.isMobile == 1):
			self.actors.remove(actor)
		else:
			self.immobiles.remove(actor)
		self.isDirty = 1


	def canMove(self, actor, newXPos, newYPos):
		hasDiagonalActor = 0;
		for act in self.immobiles:
		#check for moving away from cluster first
		#if there's no "immobile actor"  any direction (diagonal or straight)
		# from newXPos and newYPos, return false
			#striaght up
			if (newXPos == act.x_pos
				and newYPos - actor.y_size == act.y_pos):
					hasDiagonalActor = 1
					break
			#striaght down
			if (newXPos == act.x_pos
				and newYPos + actor.y_size == act.y_pos):
					hasDiagonalActor = 1
					break
			#striaght left
			if (newXPos + actor.x_size == act.x_pos
				and newYPos  == act.y_pos):
					hasDiagonalActor = 1
					break
			#striaght right
			if (newXPos - actor.x_size == act.x_pos
				and newYPos  == act.y_pos):
					hasDiagonalActor = 1
					break


			#upper right
			if (newXPos + actor.x_size == act.x_pos
				and newYPos - actor.y_size == act.y_pos):
					hasDiagonalActor = 1
					break
			#upper left
			if (newXPos - actor.x_size == act.x_pos
				and newYPos - actor.y_size == act.y_pos):
					hasDiagonalActor = 1
					break
			#lower right
			if (newXPos + actor.x_size == act.x_pos
				and newYPos + actor.y_size == act.y_pos):
					hasDiagonalActor = 1
					break
			#lower left
			if (newXPos - actor.x_size == act.x_pos
				and newYPos + actor.y_size == act.y_pos):
					hasDiagonalActor = 1
					break

		if (hasDiagonalActor == 0 ):
			return 0

		return not self.hasImmobileAt(newXPos, newYPos)


	def hasImmobileAt(self, newXPos, newYPos):
		for act in self.immobiles:
		#now check for collisions against objects
			if act.x_pos == newXPos and act.y_pos == newYPos:
				return 1;
			if newXPos < self.g_offset_x or newYPos < self.g_offset_y:
				#print "can't move up or left\n"
				return 1;
			if newXPos >= self.g_offset_x+self.width or newYPos >= self.g_offset_y+self.height:
				#print "can't move down or right\n"
				return 1;
		return 0


	def getNeighbor(self, actor):
		"""return the most immediate straight neighbor
		"""
		neighborActor = 0;
		for act in self.immobiles:
			#print act
			#striaght up
			if (actor.x_pos == act.x_pos
				and actor.y_pos - actor.y_size == act.y_pos):
					neighborActor = act
					return act
			#striaght down
			if (actor.x_pos == act.x_pos
				and actor.y_pos + actor.y_size == act.y_pos):
					neighborActor = act
					return act
			#striaght left
			if (actor.x_pos + actor.x_size == act.x_pos
				and actor.y_pos  == act.y_pos):
					neighborActor = act
					return act
			#striaght right
			if (actor.x_pos - actor.x_size == act.x_pos
				and actor.y_pos  == act.y_pos):
					neighborActor = act
					return act
		return


	def getObject(self, x, y):
		for act in self.immobiles:
			if (act.x_pos ==x and act.y_pos == y):
				return act
		return None


	def updatePerTurn(self):
		"""Return true if resolve field needs 
		to happen """

		if ( self.isDirty ):
			#print "i'm dirty...."
			self.sortGrid()
			return True

		if (self.needsCompact):
			return True

		return False


	def resolveField(self, player):
		"""wholly unoptimized
		"""

		#print "needs Compact ", self.needsCompact

		if ( self.isDirty ):
				self.sortGrid()

		if (self.needsCompact):
			#print "returning compact"
			return self.compactGrid(player)

		#print "running resolve field"
		gridWidth = len(self.newGrid)
		gridHeight = len(self.newGrid[0])
		for x in range (0, gridWidth):
			rowGood = 0
			lastColor = ''
			emptySpace = 0
			for y in range(0, gridHeight):
				#if (self.newGrid[x,y] is not None and self.newGrid[x,y] != 0):
				if (self.newGrid[x,y] is not None):
					if (lastColor == ''):
						lastColor = self.newGrid[x,y].color
						continue;
					if ( lastColor != self.newGrid[x,y].color ):
						rowGood=0
						break;
					rowGood = 1
			if (rowGood == 1):
				self.missingColumn = x
				for dy in range(0, y):
					if (self.newGrid[ x,dy ] is None): continue;
					self.newGrid[ x,dy ].isDead = 1
				return
		
		for y in range (0, gridHeight):
			lastColor = ''
			for x in range(0, gridWidth):
				if (self.newGrid[x,y] is not None):
					if (lastColor == ''):
						lastColor = self.newGrid[x,y].color
						continue;
					if ( lastColor != self.newGrid[x,y].color ):
						rowGood=0
						break;
					rowGood = 1
			if (rowGood):
				self.missingRow = y
				for dx in range(0, x):
					if (self.newGrid[ dx,y ] is None): continue
					self.newGrid[ dx,y ].isDead = 1
				return



	def clearGrid(self):
		for x in range (0,self.width/24):
			for y in range(0,self.height/24):
				self.newGrid[x,y] =  None


	def sortGrid(self):
		self.clearGrid()
		self.isDirty = 0
		for act in self.immobiles:
			#print "new actor added at ", ((act.x_pos/24), (act.y_pos/24))
			#print "new actor added at ", ((act.x_pos), (act.y_pos))
			self.newGrid[act.x_pos/24,act.y_pos/24]= act


	def compactGrid(self, player):
		deltaX = 0
		deltaY = 0
		deadBlocks = 0
		for act in self.immobiles:
			if (act.__class__ == sprite.SCS_magnetSprite):
				self.scheduleRemove(act)
				deadBlocks +=1
				#print "got a magnet sprite"
				#print "self.missing Column = ", self.missingColumn
				if (self.missingColumn is not None):
					if (self.missingColumn > 10 ):
						deltaX = -24
						deltaY = 0
					else:
						deltaX = 24
						deltaY = 0
				if (self.missingRow is not None):
					if (self.missingRow > 9):
						deltaX = 0
						deltaY = -24
					else:
						deltaX = 0
						deltaY = 24

				#print "Delta x = ", deltaX, " delta y = ", deltaY
				neighbor = self.getObject(act.x_pos-deltaX, act.y_pos-deltaY)
				if (not neighbor):
					continue
		
				act.x_pos = neighbor.x_pos
				act.y_pos = neighbor.y_pos
		
				while ( 1 ):
					neighbor.isDirty = 1
					self.intUpd = self.intUpd.unionall( (self.intUpd, (neighbor.x_pos,neighbor.y_pos,24,24)) )
					nextNeighbor = self.getObject(neighbor.x_pos-deltaX,neighbor.y_pos-deltaY)
					if nextNeighbor == neighbor:
						break
					#print 'next neighbor is ',nextNeighbor 
					neighbor.x_pos += deltaX
					neighbor.y_pos += deltaY
					if ( not nextNeighbor ):
						break
					neighbor = nextNeighbor

		if player is None:
			return deadBlocks

		#print "missing column = ", self.missingColumn
		#print "missing row    = ", self.missingRow
		#print "player  x_pos     = ", player.x_pos / 24
		#print "player  y_pos     = ", player.y_pos / 24
		#if (self.missingColumn is not None):
		#	player.x_pos += deltaX

		
		if (self.missingColumn is not None ):
			if (self.missingColumn > 10 and (player.x_pos / 24) > 10):
				player.x_pos += deltaX

			elif (self.missingColumn <= 10 and (player.x_pos / 24) <= 10):
				player.x_pos += deltaX


		if (self.missingRow is not None):
			if (self.missingRow > 9 and (player.y_pos / 24) > 9):
				player.y_pos += deltaY
			elif (self.missingRow <= 9 and (player.y_pos/24) <= 9):
				player.y_pos += deltaY


		self.needsCompact = 0
		self.missingColumn = None
		self.missingRow = None
		return deadBlocks


	def paintActors(self, g, updates):
		for act in self.needsRemoving:
			self.removeFromPlayfield(act)
			updates = updates.unionall( (updates,(act.x_pos,act.y_pos,24,24)) )
		self.needsRemoving = []

		for act in self.immobiles:
			act.update(self)
			act.paint(g)
			if act.isDirty:
				#print " == actor is dirty "
				updates = updates.unionall( (updates,(act.x_pos,act.y_pos,24,24)) )
				act.isDirty = 0

			updates = updates.unionall( (updates, self.intUpd) )
			self.intUpd = pygame.Rect( (act.x_pos,act.y_pos,24,24) )
		return updates


	def killSprite(self, sprite):
		self.scheduleRemove(sprite)
		x = SCS_magnetSprite()
		self.addToPlayfield(x, sprite.x_pos, sprite.y_pos)
		self.needsCompact = 1

	def noMoreMoves(self):
		"""check for only one row or one column remaining
		"""
		gridWidth = len(self.newGrid)
		gridHeight = len(self.newGrid[0])

		for y in range(0, gridHeight):
			colCount = 0
			for x in range(0, gridWidth):
				if (self.newGrid[x, y] is not None):
					colCount = colCount+1;
			if (colCount > 1):
				break;


		for x in range(0, gridWidth):
			rowCount = 0
			for y in range(0, gridHeight):
				if (self.newGrid[x, y] is not None):
					rowCount = rowCount+1;
			if (rowCount > 1):
				break;

		#print "rowCount ", rowCount, " colCount", colCount
		if ((rowCount < 1) and (colCount < 1)):
			return 1

		return 0

	def addNewRowOrCol(self):
		"""figure out if grid is wider or taller
		"""
		gridWidth = len(self.newGrid)
		gridHeight = len(self.newGrid[0])
		maxRowCount = 0
		maxColCount = 0
		for y in range(0, gridHeight):
			for x in range (0, gridWidth):
				if self.newGrid[x, y] != None:
					maxColCount+=1
			if maxColCount > 0:
				break;

		for x in range (0, gridWidth):
			for y in range(0, gridHeight):
				if self.newGrid[x, y] != None:
					maxRowCount+=1

			if maxRowCount > 0:
				break;

		#print "maxRowCount = ", maxRowCount, " maxColCount = ", maxColCount
		if maxRowCount >= maxColCount:
			self.addNewCol()
		else:
			self.addNewRow()

		pass

	def addNewRow(self):
		"""Find the perfect row to fill and fill it
		"""
		gridWidth = len(self.newGrid)
		gridHeight = len(self.newGrid[0])
		
		rowStart = None
		rowEnd   = None

		colStart = None
		colEnd   = None
		for x in range (0, gridWidth):
			for y in range(0, gridHeight):
				if self.newGrid[x, y] != None:
					if (rowStart == None):
						rowStart = x
					else:
						rowEnd = x

					if (colStart == None):
						colStart = y
					else:
						colEnd = y


		#print "going to add row between ", rowStart, ' ', rowEnd, ' and ', colStart, ' ', colEnd
		colors = (('red','b'),('green','a'),('orange','c'),('blue','d'))

		#decide to add row on top or bottom

		midpoint = (self.height/self.y_size /2) +1
		if ((colEnd - midpoint) < (midpoint - colStart)):
			colInsert = colEnd
		else:
			colInsert = colStart-2
		#print "midpiont is ", midpoint, ' colend - midpoint is ', (colEnd - midpoint), ' colstart - midpoint is ', (midpoint - colStart)

		#first, move the player out of the way
		# otherwise it won't know wich direction to move away from
		for x in range(rowStart-1, rowEnd):
			self.checkForPlayer(((x*24)+32, (colInsert*24)+32))

		import random
		for x in range(rowStart-1, rowEnd):
			set = colors[random.randint(0,3)]
			blockName = os.path.join(
				'..', 'media', 'block_'+set[1]+'.png');
			block = SCS_sprite(pygame.image.load(SCS.getFilename(blockName)),set[0] )
			self.addToGrid(block, x, colInsert)
			#self.addToPlayfield(block, (x*24)+32, ((colInsert)*24)+32)

		self.needsCompact = 0

	def addNewCol(self):
		"""Find the perfect col to fill and fill it
		"""

		gridWidth = len(self.newGrid)
		gridHeight = len(self.newGrid[0])
		
		rowStart = None
		rowEnd   = None

		colStart = None
		colEnd   = None
		for x in range (0, gridWidth):
			for y in range(0, gridHeight):
				if self.newGrid[x, y] != None:
					if (rowStart == None):
						rowStart = x
					else:
						rowEnd = x

					if (colStart == None):
						colStart = y
					else:
						colEnd = y


		#print "going to col row between ", colStart, ' ' , colEnd
		colors = (('red','b'),('green','a'),('orange','c'),('blue','d'))

		#decide to add row on top or bottom

		midpoint = (self.width/self.x_size /2)
		if ((rowEnd - midpoint) < (midpoint - rowStart)):
			rowInsert = rowEnd 
		else:
			rowInsert = rowStart -2
		#print "midpiont is ", midpoint, ' rowend - midpoint is ', (rowEnd - midpoint), ' rowstart - midpoint is ', (midpoint - rowStart)

		for y in range(colStart-1, colEnd):
			self.checkForPlayer(((rowInsert*24)+32, (y*24)+32))

		import random
		for y in range(colStart-1, colEnd):
			set = colors[random.randint(0,3)]
			blockName = os.path.join(
				'..', 'media', 'block_'+set[1]+'.png');
			block = SCS_sprite(pygame.image.load(SCS.getFilename(blockName)),set[0] )
			self.addToGrid(block, rowInsert,  y)

		self.needsCompact = 0

	def hasDeadActors(self):
		for act in self.immobiles:
			if (act.isDead == 1):
				return 1
			if (act.__class__ == sprite.SCS_magnetSprite):
				return 1
		return 0

	def debugPaint(self, g,updates=None):
		#print '../media/fonts/arial.ttf'
		#f = font.Font('../media/fonts/arial.ttf',9)
		if updates == None:
			updates = pygame.Rect( (0,0,0,0))
		f = self.f
		g.fill( (255,0,255), (self.g_offset_x, self.g_offset_y, self.width, self.height))
		for x in range(0,self.width / self.x_size):
			for y in range(0,self.height / self.y_size):
				message = x.__str__()+ ','+ y.__str__()	
				text = f.render(message, 0, (255,255,255) )
				g.blit ( text, ( (x* self.x_size)+self.g_offset_x , (y * self.y_size) + self.g_offset_y))
		pygame.draw.rect(g, (255,0,0), updates, 2)
