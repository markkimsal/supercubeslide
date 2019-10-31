###########################################################################
#    Copyright (C) 2005, 2015 by Mark Kimsal
#    https://github.com/markkimsal
#
# Copyright: See LICENSE file that comes with this distribution
#
###########################################################################
from supercubeslide import playfield as playfield
from supercubeslide import timing as timing

import pygame

class SCS_sprite:
	image              =''
	x_pos              =0
	y_pos              =0
	rect               =0
	x_size             = 24
	y_size             = 24
	h_velocity         = 0
	v_velocity         = 0
	clockwise_velocity = 0
	is_accelerating=0
	isMobile = 0
	isDead = 0
	isDirty = 0
	color = ''

	deathTic=0
	nextDeathTic=0

	nextUpdateTic=0

	def __init__(this,i, c):
		this.x_pos = 32 
		this.y_pos = 32 
		this.image = i
		this.color = c


	def paint(this,g):
		if ( this.deathTic % 2 == 1 ):
			this.isDirty = 1
			pygame.draw.rect(g, (255,255,255), (this.x_pos,this.y_pos,24,24))
			pygame.draw.rect(g, (255,0,0), (this.x_pos,this.y_pos,24,24), 1)
		else :
			g.blit( this.image, (this.x_pos,this.y_pos))


	def update(this,field):
		"""returns a rectangle of old position
		"""
		if (this.isDead):
			if (this.deathTic == 5):
				field.killSprite(this);
			return this.event_deathEffect()


		if (this.nextUpdateTic > timing.worldTic):
			return None

		this.nextUpdateTic = timing.worldTic + 50
		rect = (this.x_pos, this.y_pos, 24, 24)
		#if this.is_accelerating == 0:
		#	return
		newX = this.x_pos
		newY = this.y_pos

		if (this.clockwise_velocity ==1):
			this.clockwise_velocity = 0
			this.moveCW(field)
			return rect
		elif(this.clockwise_velocity==-1):
			this.clockwise_velocity = 0
			this.moveCCW(field)
			return rect

		if (this.h_velocity > 0):
			newX = this.x_pos+24
		
		if (this.h_velocity < 0):
			newX = this.x_pos-24

		if (this.v_velocity > 0):
			newY = this.y_pos-24

		if (this.v_velocity < 0):
			newY = this.y_pos+24

		if (field.canMove(this,newX,newY)):
			this.x_pos = newX;
			this.y_pos = newY;
		return rect

	def moveCCW(self, field):
		""" move the sprite in a counter-clockwise motion
		"""

		#am i on the right side?
		if (field.hasImmobileAt(self.x_pos-24, self.y_pos)):
			#move up
			self.y_pos = self.y_pos-24
			return 

		#am i on the top side?
		if (field.hasImmobileAt(self.x_pos, self.y_pos+24)):
			#move right
			self.x_pos = self.x_pos-24
			return 

		#am i on the left side?
		if (field.hasImmobileAt(self.x_pos+24, self.y_pos)):
			#move down
			self.y_pos = self.y_pos+24
			return 

		#am i on the bottom side?
		if (field.hasImmobileAt(self.x_pos, self.y_pos-24)):
			#move right
			self.x_pos = self.x_pos+24
			return 

		#check the corners
		#     bottom left
		if (field.hasImmobileAt(self.x_pos+24, self.y_pos-24)):
			#move right
			self.x_pos = self.x_pos+24
			return 

		#check the corners
		#     top left
		if (field.hasImmobileAt(self.x_pos+24, self.y_pos+24)):
			#move down
			self.y_pos = self.y_pos+24
			return 


		#check the corners
		#     bottom right
		if (field.hasImmobileAt(self.x_pos-24, self.y_pos-24)):
			#moveup 
			self.y_pos = self.y_pos-24
			return 

		#check the corners
		#     top right
		if ( field.hasImmobileAt(self.x_pos-24, self.y_pos+24)):
			#move left
			self.x_pos = self.x_pos-24
			return 




	def moveCW(self, field):
		""" move the sprite in a clockwise motion
		"""

		#am i on the right side?
		if (field.hasImmobileAt(self.x_pos-24, self.y_pos)):
			#move up
			self.y_pos = self.y_pos+24
			return 

		#am i on the top side?
		if (field.hasImmobileAt(self.x_pos, self.y_pos+24)):
			#move right
			self.x_pos = self.x_pos+24
			return 

		#am i on the left side?
		if (field.hasImmobileAt(self.x_pos+24, self.y_pos)):
			#move down
			self.y_pos = self.y_pos-24
			return 

		#am i on the bottom side?
		if (field.hasImmobileAt(self.x_pos, self.y_pos-24)):
			#move right
			self.x_pos = self.x_pos-24
			return 

		#check the corners
		#     bottom left
		if (field.hasImmobileAt(self.x_pos+24, self.y_pos-24)):
			#move right
			self.y_pos = self.y_pos-24
			return 

		#check the corners
		#     top left
		if (field.hasImmobileAt(self.x_pos+24, self.y_pos+24)):
			#move down
			self.x_pos = self.x_pos+24
			return 


		#check the corners
		#     bottom right
		if (field.hasImmobileAt(self.x_pos-24, self.y_pos-24)):
			#moveup 
			self.x_pos = self.x_pos-24
			return 

		#check the corners
		#     top right
		if ( field.hasImmobileAt(self.x_pos-24, self.y_pos+24)):
			#move left
			self.y_pos = self.y_pos+24
			return 

		pass

	def moveOutward(self, field):
		""" move the sprite in a counter-clockwise motion
		"""

		#am i on the right side?
		if (field.hasImmobileAt(self.x_pos-24, self.y_pos)):
			#move right
			self.x_pos = self.x_pos+24
			return 

		#am i on the top side?
		if (field.hasImmobileAt(self.x_pos, self.y_pos+24)):
			#move right
			self.y_pos = self.y_pos-24
			return 

		#am i on the left side?
		if (field.hasImmobileAt(self.x_pos+24, self.y_pos)):
			#move left
			self.x_pos = self.x_pos-24
			return 

		#am i on the bottom side?
		if (field.hasImmobileAt(self.x_pos, self.y_pos-24)):
			#move down
			self.y_pos = self.y_pos+24
			return 


	def isMobile(self):
		return self.isMobile;


	def processAction(self,field):
		"""try to slide the player cube into the stack of cubes
		"""
		#do nothing if the field still needs to be cleaned up
		if (field.needsCompact):
			return

		neighbor = field.getNeighbor(self)
		if (not neighbor):
			return

		#this gives you the direction of the neighbor vs the player
		deltaX = neighbor.x_pos - self.x_pos 
		deltaY = neighbor.y_pos - self.y_pos
		#print('delta x ', deltaX)
		#print('delta y ', deltaY)

		field.intUpd = field.intUpd.unionall( (field.intUpd,pygame.Rect( self.x_pos, self.y_pos, 24, 24)))
		self.x_pos = neighbor.x_pos
		self.y_pos = neighbor.y_pos
		#field.intUpd = field.intUpd.unionall( (field.intUpd,(self.x_pos,self.y_pos,24,24)) )

		while ( 1 ):
			neighbor.isDirty = 1
			nextNeighbor = field.getObject(neighbor.x_pos+deltaX,neighbor.y_pos+deltaY)
			#print('next neighbor is ',nextNeighbor )
			neighbor.x_pos += deltaX
			neighbor.y_pos += deltaY
			if ( not nextNeighbor ):
				break
			neighbor = nextNeighbor

		field.removeFromPlayfield(neighbor)
		field.removeFromPlayfield(self)
		#field.scheduleRemove(neighbor)
		#field.scheduleRemove(self)
		#print(" PROCESS ACTION ## sliding actor into field")
		neighbor.isMobile = 1
		self.isMobile = 0
		field.addToPlayfield(neighbor, neighbor.x_pos, neighbor.y_pos)
		field.addToPlayfield(self, self.x_pos, self.y_pos)

		return neighbor


	def event_deathEffect(self):
		if (timing.worldTic > self.nextDeathTic):
			self.deathTic +=1
			self.nextDeathTic = timing.worldTic + 150


class SCS_magnetSprite (SCS_sprite):

	def __init__(self):
		pass

	def paint(this,g):
		#pygame.draw.rect(g, (255,255,255), (this.x_pos,this.y_pos,24,24))
		pygame.draw.rect(g, (0,255,0), (this.x_pos,this.y_pos,24,24), 2)
