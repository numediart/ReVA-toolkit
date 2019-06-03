import os
import numpy
import time
import json
import argparse
from .transformations import *
from pythonosc import osc_message_builder
from pythonosc import udp_client

def get_matrix( data ):
	return numpy.matrix( data )

def get_mandatory_indices( usage = 'index' ):
	if usage == 'index':
		return [ ('valid',False,bool), ('all_indices',False,bool), ('timestamp',None,int), ('landmarks',None,list) ]
	elif usage == 'frame':
		return [ ('valid',False,bool), ('timestamp',None,float), ('landmarks',None,list) ]

def get_optional_indices( usage = 'index' ):
	if usage == 'index':
		return [ ('gaze',None,list), ('au',None,list) ]
	elif usage == 'frame':
		return [ ('gaze',None,list), ('au',None,list) ]

def generate_indices( all_indices = True ):
	d = {}
	for k in get_mandatory_indices():
		d[ k[0] ] = k[1]
	if all_indices:
		for k in get_optional_indices():
			d[ k[0] ] = k[1]
	d['all_indices'] = all_indices
	return d

def validate_indices( indices ):
	
	ll = get_mandatory_indices()
	if 'all_indices' in indices.keys():
		ll += get_optional_indices()
	
	err = ''
	for i in range(len(ll)):
		if ll[i][0] not in indices:
			if err != '':
				err += '\n'
			err += "lavatar::validate_indices, error: missing field '%s' in dictionary!" % ll[i][0]
		if indices[ ll[i][0] ] == None:
			if err != '':
				err += '\n'
			err += "lavatar::validate_indices, error: field '%s' not found in the CSV!" % ll[i][0]
		# checking type!
		if type(indices[ ll[i][0] ]) is not ll[i][2]:
			if err != '':
				err += '\n'
			err += "lavatar::validate_indices, error: field '%s' is not of the right type!" % ll[i][0]
	
	if err == '':
		for i in range(len(indices['landmarks'])):
			for j in range(0,3):
				if indices['landmarks'][i][j] == None:
					if err != '':
						err += '\n'
					err += "lavatar::validate_indices, error: missing data in landmarks for position '%i' on axis '%i'!" % (i,j)
		if indices['all_indices']:
			for i in range(len(indices['gaze'])):
				for j in range(0,3):
					if indices['gaze'][i][j] == None:
						if err != '':
							err += '\n'
						err += "lavatar::validate_indices, error: missing data in gaze for position '%i' on axis '%i'!" % (i,j)
	
	if err != '':
		print( err )
		return False
	else:
		indices['valid'] = True
	
	return True

def generate_frame( indices ):
	
	f = {}
	for k in get_mandatory_indices( 'frame' ):
		f[ k[0] ] = k[1]
	if indices['all_indices']:
		for k in get_optional_indices( 'frame' ):
			f[ k[0] ] = k[1]
	return f

def validate_frame( frame, indices ):
	
	ll = get_mandatory_indices( 'frame' )
	if 'all_indices' in indices.keys():
		ll += get_optional_indices( 'frame' )
	
	err = ''
	for i in range(len(ll)):
		if ll[i][0] not in frame:
			if err != '':
				err += '\n'
			err += "lavatar::validate_frame, error: missing field '%s' in dictionary!" % ll[i][0]
		if frame[ ll[i][0] ] == None:
			if err != '':
				err += '\n'
			err += "lavatar::validate_frame, error: field '%s' not found in the CSV!" % ll[i][0]
		# checking type!
		if type(frame[ ll[i][0] ]) is not ll[i][2]:
			if err != '':
				err += '\n'
			err += "lavatar::validate_frame, error: field '%s' is not of the right type!" % ll[i][0]
	
	if err == '':
		for i in range(len(frame['landmarks'])):
			for j in range(0,3):
				if frame['landmarks'][i][j] == None:
					if err != '':
						err += '\n'
					err += "lavatar::validate_frame, error: missing data in landmarks for position '%i' on axis '%i'!" % (i,j)
		if indices['all_indices']:
			for i in range(len(frame['gaze'])):
				for j in range(0,3):
					if frame['gaze'][i][j] == None:
						if err != '':
							err += '\n'
						err += "lavatar::validate_frame, error: missing data in gaze for position '%i' on axis '%i'!" % (i,j)
	
	if err != '':
		print( err )
		return False
	else:
		frame['valid'] = True
	
	return True

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
	x, y, z = translation_from_matrix( matrix * translation_matrix( numpy.array([xyz[0],xyz[1],xyz[2]]) ) )
	return [ x, y, z ]

# provide RADIANS!!!
def apply_matrix_rotation( xyz, matrix ):
	rot = euler_from_matrix( matrix * euler_matrix( xyz[0], xyz[1], xyz[2] ) )
	return [rot[0],rot[1],rot[2]]

def parse_text_frame( words, indices, matrix = None ):
	
	if not indices['valid']:
		print( "lavatar::parse_text_frame, error: indices are NOT valid!" )
		return
	if type(words) is not list:
		print( "lavatar::parse_text_frame, error: first argument must be a list of strings!" )
		return
	if type(words[0]) is not str:
		print( "lavatar::parse_text_frame, error: first argument must be a list of strings!" )
		return
	
	frame = generate_frame( indices )
	
	frame['timestamp'] = parse_float( words[ indices['timestamp'] ] )
	
	frame['landmarks'] = [[0,0,0] for i in range( len(indices['landmarks']) )]
	for i in range( len(indices['landmarks']) ):
		for j in range(0,3):
			frame['landmarks'][i][j] = parse_float( words[ indices['landmarks'][i][j] ] )
		if len(matrix) > 0:
			frame['landmarks'][i] = apply_matrix_position( frame['landmarks'][i], matrix )
			
	if indices['all_indices']:
		
		frame['gaze'] = [[0,0,0] for i in range( len(indices['gaze']) )]
		for i in range( len(indices['gaze']) ):
			for j in range(0,3):
				frame['gaze'][i][j] = parse_float( words[ indices['gaze'][i][j] ] )
			if len(matrix) > 0:
				frame['gaze'][i] = apply_matrix_rotation( frame['gaze'][i], matrix )
		
		frame['au'] = [None for i in range( len(indices['au']) )]
		for i in range( len(indices['au']) ):
			frame['au'][i] = parse_float( words[ indices['au'][i] ] )
	
	validate_frame( frame, indices )
	
	return frame

def generate_aabb( frame, center = None ):
	
	if not frame['valid']:
		return
	
	pos0 = frame['landmarks'][0]
	barycenter = [0,0,0]
	aabb_min = [pos0[0],pos0[1],pos0[2]]
	aabb_max = [pos0[0],pos0[1],pos0[2]]
	aabb_size = []
	for i in range( 0, len( frame['landmarks'] ) ):
		for j in range(3):
			v = frame['landmarks'][i][j]
			barycenter[j] += v
			if aabb_min[j] > v:
				aabb_min[j] = v
			if aabb_max[j] < v:
				aabb_max[j] = v
	
	for j in range(3):
		barycenter[j] /= len( frame['landmarks'] )
		if center == None:
			aabb_min[j] -= barycenter[j]
			aabb_max[j] -= barycenter[j]
		else:
			barycenter[j] -= center[j]
			aabb_min[j] -= center[j]
			aabb_max[j] -= center[j]
	for j in range(3):
		aabb_size.append( aabb_max[j]-aabb_min[j] )

	return { 'center':barycenter, 'min':aabb_min, 'max':aabb_max, 'size':aabb_size }
	
def pack_animation( frames, indices ):
	
	if len(frames) == 0 or not indices['valid']:
		return None
	
	animation = {}
	animation['duration'] = frames[len(frames)-1]['timestamp'] - frames[0]['timestamp']
	animation['frame_count'] = len(frames)
	animation['landmark_count'] = len(indices['landmarks'])
	animation['action_unit_count'] = len(indices['au'])
	animation['gaze_count'] = len(indices['gaze'])
	animation['fields'] = []
	for k in indices.keys():
		if k == 'valid' or k == 'all_indices':
			continue
		animation['fields'].append( k )

	animation['aabb'] = generate_aabb( frames[0] )
	animation['scale'] = 1.0 / animation['aabb']['size'][0]
	if animation['aabb']['size'][1] > animation['aabb']['size'][0]:
		animation['scale'] = 1.0 / animation['aabb']['size'][1]
	if animation['aabb']['size'][2] > animation['aabb']['size'][1]:
		animation['scale'] = 1.0 / animation['aabb']['size'][2]
		
	animation['frames'] = []
	for f in frames:
		newf = dict(f)
		newf.pop('valid', None)
		newf['frame'] = len(animation['frames'])
		newf['aabb'] = generate_aabb( f, animation['aabb']['center'] )
		for i in range(len(newf['landmarks'])):
			for j in range(3):
				newf['landmarks'][i][j] -= animation['aabb']['center'][j]
				newf['landmarks'][i][j] *= animation['scale']
		animation['frames'].append( newf )
	
	return animation

def save_animation_json( anim, path, compress = True ):
	
	out = open( path, 'w' )
	if ( compress ):
		cc = json.dumps( anim, sort_keys=True, indent=0, separators=(',', ':'))
		cc = cc.replace( '\n','' )
	else:
		cc = json.dumps( anim, sort_keys=True, indent=4, separators=(',', ':'))
	out.write( cc )
	out.close()



