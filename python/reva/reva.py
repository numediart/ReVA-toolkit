import os
import math
import numpy
import time
import json
import argparse
import copy
import shutil
import wave
import subprocess
from .transformations import *
from pythonosc import osc_message_builder
from pythonosc import udp_client

'''
## GLOBALS ##
'''

ReVA_VERSION = 1
ReVA_PREFIX = 'ReVA'

'''
## ENVIRONMENT ##
'''

FFPROBE_EXEC_PATH = 'ffprobe'


'''
## TEMPLATES ##
see https://github.com/numediart/ReVA-toolkit/wiki/file_format for
valid frame json format
'''

FRAME_TEMPLATE = {
	'gazes': [],
	'points': [],
	'pose_euler': [0,0,0],
	'pose_translation': [0,0,0],
	'timestamp': 0.0
}

SOUND_TEMPLATE = {
	'bits_per_sample': 0,
	'channels': 0,
	'sample_rate': 0,
	'path': ''
}

VIDEO_TEMPLATE = {
	'width': 0,
	'height': 0,
	'path': ''
}

ANIMATION_TEMPLATE = {
	'type' : ReVA_PREFIX+'_animation',
	'version' : ReVA_VERSION,
	'display_name': '',
	'frames' : [],
	'gaze_count': 0,
	'point_count': 0,
	'duration': 0,
	'sound': None,
	'video': None,
	'aabb': {
		'center': None,
		'min': None,
		'max': None,
		'size': None,
	}
}

'''
## UTILS ##
all general & utility functions
'''

def mat( data ):
	return numpy.matrix( data )

def mat_euler( x, y, z ):
	'''
	alpha, beta, gamma = 0.123, -1.234, 2.345
	origin, xaxis, yaxis, zaxis = [0, 0, 0], [1, 0, 0], [0, 1, 0], [0, 0, 1]
	I = identity_matrix()
	Rx = rotation_matrix(alpha, xaxis)
	print(Rx)
	Ry = rotation_matrix(beta, yaxis)
	print(Ry)
	Rz = rotation_matrix(gamma, zaxis)
	print(Rz)
	R = concatenate_matrices(Rx, Ry, Rz)
	euler = euler_from_matrix(R, 'rxyz')
	numpy.allclose([alpha, beta, gamma], euler)
	Re = euler_matrix(alpha, beta, gamma, 'rxyz')
	print(Re)
	print(is_same_transform(R, Re))
	'''
	return euler_matrix( x, y, z, 'rxyz')

def parse_int( txt ):
	try:
		return int( txt.strip() )
	except Exception as e:
		print( e )
		return None

def parse_float( txt ):
	try:
		return float( txt.strip() )
	except Exception as e:
		print( e )
		return None

def apply_matrix_position( xyz, matrix ):
	trans = translation_matrix( numpy.array([xyz[0],xyz[1],xyz[2]]) )
	x, y, z = translation_from_matrix( concatenate_matrices( matrix, trans ) )
	return [ x, y, z ]

# provide euler angles in RADIANS!!! (if degree, use a/180*PI)
def apply_matrix_rotation( xyz, matrix ):
	em = euler_matrix( xyz[0], xyz[1], xyz[2], axes='sxyz' )
	rot = euler_from_matrix( concatenate_matrices( matrix, em ), axes='sxyz' ) # godot convention for rotations!!!
	return [rot[0],rot[1],rot[2]]

'''
## ANIMATION ##
function used to generate a valid animation
'''

def push_in_aabb( aabb, pt ):
	
	if aabb['min'] == None:
		aabb['min'] = list(pt)
		aabb['max'] = list(pt)
	else:
		for i in range(0,3):
			if aabb['min'][i] > pt[i]:
				aabb['min'][i] = pt[i]
			if aabb['max'][i] < pt[i]:
				aabb['max'][i] = pt[i]

def process_aabb( aabb ):
	aabb['center'] = [0,0,0]
	aabb['size'] = [0,0,0]
	for i in range(0,3):
		aabb['size'][i] = aabb['max'][i] - aabb['min'][i]
		aabb['center'][i] = aabb['min'][i] + aabb['size'][i] * 0.5

def normalise_in_aabb( aabb, pt ):
	
	for i in range(0,3):
		pt[i] /= aabb['size'][i]
	return pt

def pack_animation( frames, display_name, corr_mat ):
	
	anim = copy.deepcopy(ANIMATION_TEMPLATE)
	
	anim['display_name'] = display_name
	
	if len( frames ) != 0:
		
		f = frames[0]
		anim[ 'gaze_count' ] = len(f['gazes'])
		anim[ 'point_count' ] = len(f['points'])
		
		aabb = anim[ 'aabb' ]
		
		# rendering aabb
		for i in range(anim[ 'point_count' ]):
			pt = apply_matrix_position( f['points'][i], corr_mat )
			push_in_aabb( aabb, pt )
		process_aabb( aabb )

		last_ts = 0
		
		fi = 0
		for f in frames:
			
			if f['timestamp'] < last_ts:
				print( 'Invalid timestamp in frame', fi )
				fi += 1
				continue
			
			last_ts = f['timestamp']
			fi += 1
			
			newf = copy.deepcopy(FRAME_TEMPLATE)
			
			newf['timestamp'] = f['timestamp']
			newf['pose_euler'] = apply_matrix_rotation( f['pose_euler'], corr_mat )
			newf['pose_translation'] = apply_matrix_position( f['pose_translation'], corr_mat )
			
			for g in f['gazes']:
				newf['gazes'].append( apply_matrix_rotation( g, corr_mat ) )
			
			for i in range(anim[ 'point_count' ]):
				pt = apply_matrix_position( f['points'][i], corr_mat )
				for j in range(0,3):
					pt[j] -= newf['pose_translation'][j]
				#newf['points'].append( normalise_in_aabb( aabb, pt ) )
				newf['points'].append( pt )
			
			anim['frames'].append(newf)
	
	anim['duration'] = anim['frames'][len(anim['frames'])-1]['timestamp'] - anim['frames'][0]['timestamp']
	
	return anim

def animation_add_sound( animation, sound_path, json_path = None ):
	
	if os.path.isfile(sound_path):
		abs_path = os.path.abspath(sound_path)
		animation['sound'] = copy.deepcopy(SOUND_TEMPLATE)
		if json_path != None:
			target_path = os.path.dirname(os.path.realpath(json_path))
			target_path = os.path.join( target_path, os.path.basename(sound_path) )
			shutil.copyfile( sound_path, target_path )
			sound_path = os.path.basename(target_path)
		else:
			sound_path = abs_path

		# getting wav info with std library
		try:
			with wave.open(abs_path,'r') as w:
				animation['sound']['sample_rate'] = w.getframerate()
				animation['sound']['bits_per_sample'] = w.getsampwidth() * 8
				animation['sound']['channels'] = w.getnchannels()
				animation['sound']['path'] = sound_path
		except Exception as e:
			print( e )
			animation['sound'] = None

		# getting info from ffprobe:		
		'''
		cmd = FFPROBE_EXEC_PATH + ' -i ' + abs_path + ' -show_streams -select_streams a:0'
		proc = subprocess.run(cmd.split(' '), stdout=subprocess.PIPE)
		lines = proc.stdout.decode('utf-8').split('\n')
		for l in lines:
			if l.startswith( 'sample_rate' ):
				ws = l.split('=')
				animation['sound']['sample_rate'] = parse_int(ws[1])
			if l.startswith( 'channels' ):
				ws = l.split('=')
				animation['sound']['channels'] = parse_int(ws[1])
			if l.startswith( 'bits_per_sample' ):
				ws = l.split('=')
				animation['sound']['bits_per_sample'] = parse_int(ws[1])
		animation['sound']['path'] = sound_path
		'''
	
	else:
		animation['sound'] = None

def animation_add_video( animation, video_path, json_path = None ):
	if os.path.isfile(video_path):
		animation['video'] = copy.deepcopy(VIDEO_TEMPLATE)
		animation['video']['path'] = video_path
	else:
		animation['video'] = None

def save_animation_json( anim, path, compress = True ):
	
	out = open( path, 'w' )
	if ( compress ):
		cc = json.dumps( anim, sort_keys=True, indent=0, separators=(',', ':'))
		cc = cc.replace( '\n','' )
		cc = cc.replace( '\r','' )
	else:
		cc = json.dumps( anim, sort_keys=True, indent=4, separators=(',', ':'))
	out.write( cc )
	out.close()