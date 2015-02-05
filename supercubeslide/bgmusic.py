###########################################################################
#    Copyright (C) 2005, 2015 by Mark Kimsal
#    https://github.com/markkimsal
#
# Copyright: See LICENSE file that comes with this distribution
#
###########################################################################
# Music Licensed by Mod Archive Distribution License
# See more @ http://modarchive.org/index.php?terms-upload

import pygame
import SCS
import os

songList = [
		{'filename': '8bit_party.it', 'title': '8Bit Party', 'artist': 'Line', 
			'homepage': 'http://modarchive.org/index.php?request=view_by_moduleid&query=162286'},

		{'filename': '1_channel_moog.it', 'title': 'Channel Moog', 'artist': 'Manwe', 
			'homepage': 'http://modarchive.org/index.php?request=view_by_moduleid&query=158975'},

		{'filename': 'a--fchip.it', 'title': 'Friend(Chip)', 'artist': 'AquaLife', 
			'homepage': 'http://modarchive.org/index.php?request=view_by_moduleid&query=32414'}
		]

def startSong(idx):
	if pygame.mixer.music.get_busy():
		pygame.mixer.music.stop()
	songFile = os.path.join('..', 'media', 'music', songList[idx]['filename'])
	pygame.mixer.music.load(SCS.getFilename(songFile))
	pygame.mixer.music.play(-1)

def pauseSong():
	pygame.mixer.music.pause()

def unpauseSong():
	pygame.mixer.music.unpause()
