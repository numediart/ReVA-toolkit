import os
import math
import numpy
import time
import json
import argparse
from .transformations import *
from pythonosc import osc_message_builder
from pythonosc import udp_client

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

def get_mandatory_keys( usage = 'index' ):
	if usage == 'index':
		return [ ('valid',False,bool), ('all_indices',False,bool), ('timestamp',None,int), ('landmarks',None,list) ]
	elif usage == 'frame':
		return [ ('valid',False,bool), ('timestamp',None,float), ('landmarks',None,list) ]
	elif usage == 'animation':
		return [('duration',0,float), ('frame_count',0,int), ('landmark_count',0,int), ('frames',None,list)]
	elif usage == 'animation_frame':
		return [('index',0,int),('landmarks',None,list), ('timestamp',0,float)]
	elif usage == 'animation_frame_interpolation':
		return [('landmarks',None,list), ('landmarks_data',None,list), ('timestamp',0,float)]
	elif usage == 'aabb':
		return [('center',None,[]),('min',None,[]),('max',None,[]),('size',None,[])]
	elif usage == 'structrue':
		return [
			('brow_right',None,list),
			('eye_right',None,list),
			('lid_right_upper',None,list),
			('lid_right_lower',None,list),
			('brow_left',None,list),
			('eye_left',None,list),
			('lid_left_upper',None,list),
			('lid_left_lower',None,list),
			('mouth_all',None,list),
			('lip_corner_right',None,list),
			('lip_corner_left',None,list),
			('lip_upper',None,list),
			('lip_upper_left',None,list),
			('lip_upper_center',None,list),
			('lip_upper_right',None,list),
			('lip_lower',None,list),
			('lip_lower_left',None,list),
			('lip_lower_center',None,list),
			('lip_lower_right',None,list),
			('nose_tip',None,list),
			('nose_all',None,list),
			('nostril_right',None,list),
			('nostril_left',None,list)
		]
	else:
		return None

def get_optional_keys( usage = 'index' ):
	if usage == 'index':
		return [ ('pose_euler',None,list), ('gazes',None,list), ('au',None,list) ]
	elif usage == 'frame':
		return [ ('pose_euler',None,list), ('gazes',None,list), ('au',None,list) ]
	elif usage == 'animation':
		return [('action_unit_count',0,int), ('gaze_count',-1,int), ('sound',None,dict), ('video',None,dict), ('fields',None,list), ('aabb',None,dict), ('aabb_total',None,dict), ('scale',1.0,float)]
	elif usage == 'animation_frame':
		return [('pose_euler',None,list), ('au',None,list), ('gazes',None,list)]
	elif usage == 'animation_frame_interpolation':
		return [('pose_euler',None,list), ('au',None,list), ('gazes',None,list), ('gaze_data',None,list)]
	else:
		return None

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

'''
## IMPORT ##
text input manipulation part
'''

def generate_indices( all_indices = True ):
	d = {}
	for k in get_mandatory_keys():
		d[ k[0] ] = k[1]
	if all_indices:
		for k in get_optional_keys():
			d[ k[0] ] = k[1]
	d['all_indices'] = all_indices
	return d

def generate_frame_indices( all_indices = True ):
	d = {}
	for k in get_mandatory_keys( 'frame' ):
		d[ k[0] ] = k[1]
	for k in get_mandatory_keys( 'animation_frame' ):
		d[ k[0] ] = k[1]
	if all_indices:
		for k in get_optional_keys( 'animation_frame' ):
			d[ k[0] ] = k[1]
	for k in get_mandatory_keys( 'aabb' ):
		d[ k[0] ] = k[1]
	d['all_indices'] = all_indices
	d['valid'] = True
	return d

def validate_indices( indices ):
	
	ll = get_mandatory_keys()
	if 'all_indices' in indices.keys():
		ll += get_optional_keys()
	
	err = ''
	for i in range(len(ll)):
		if ll[i][0] not in indices:
			if err != '':
				err += '\n'
			err += "lavatar::validate_indices, error: missing field '%s' in dictionary!" % ll[i][0]
		elif indices[ ll[i][0] ] == None:
			if err != '':
				err += '\n'
			err += "lavatar::validate_indices, error: field '%s' is null!" % ll[i][0]
		# checking type!
		elif type(indices[ ll[i][0] ]) is not ll[i][2]:
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
			for i in range(len(indices['gazes'])):
				for j in range(0,3):
					if indices['gazes'][i][j] == None:
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
	for k in get_mandatory_keys( 'frame' ):
		f[ k[0] ] = k[1]
	if indices['all_indices']:
		for k in get_optional_keys( 'frame' ):
			f[ k[0] ] = k[1]
	return f

def validate_frame( frame, indices ):
	
	ll = get_mandatory_keys( 'frame' )
	if 'all_indices' in indices.keys():
		ll += get_optional_keys( 'frame' )
	
	err = ''
	for i in range(len(ll)):
		if ll[i][0] not in frame:
			if err != '':
				err += '\n'
			err += "lavatar::validate_frame, error: missing field '%s' in dictionary!" % ll[i][0]
		elif frame[ ll[i][0] ] == None:
			if err != '':
				err += '\n'
			err += "lavatar::validate_frame, error: field '%s' is null!" % ll[i][0]
		# checking type!
		elif type(frame[ ll[i][0] ]) is not ll[i][2]:
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
			for i in range(len(frame['gazes'])):
				for j in range(0,3):
					if frame['gazes'][i][j] == None:
						if err != '':
							err += '\n'
						err += "lavatar::validate_frame, error: missing data in gaze for position '%i' on axis '%i'!" % (i,j)
	
	if err != '':
		print( err )
		return False
	else:
		frame['valid'] = True
	
	return True

def apply_matrix_position( xyz, matrix ):
	trans = translation_matrix( numpy.array([xyz[0],xyz[1],xyz[2]]) )
	x, y, z = translation_from_matrix( concatenate_matrices( matrix, trans ) )
	return [ x, y, z ]

# provide RADIANS!!!
def apply_matrix_rotation( xyz, matrix ):
	em = euler_matrix( xyz[0], xyz[1], xyz[2], axes='sxyz' )
	rot = euler_from_matrix( concatenate_matrices( matrix, em ), axes='sxyz' ) # godot convention for rotations!!!
	return [rot[0],rot[1],rot[2]]

def parse_osc_frame( of, indices, ts, mat_trans = None, mat_rot = None ):
	
	if not indices['valid']:
		print( "lavatar::parse_osc_frame, error: indices are NOT valid!" )
		return
	
	frame = generate_frame( indices )
	
	frame['index'] = of['ID']
	frame['timestamp'] = ts
	
	if 'center' in indices: 
		frame['center'] = [0,0,0]
		frame['min'] = [0,0,0]
		frame['max'] = [0,0,0]
		frame['size'] = [0,0,0]
		frame['center'][0] = of['head_pos'][0]
		frame['center'][1] = of['head_pos'][1]
		frame['center'][2] = of['head_pos'][2]
		if len(mat_trans) > 0:
			frame['center'] = apply_matrix_position( frame['center'], mat_trans )
		for i in range(3):
			frame['min'][i] = frame['center'][i]
			frame['max'][i] = frame['center'][i]
	
	frame['landmarks'] = [[0,0,0] for i in range( len( of['landmarks']) )]
	for i in range( len( of['landmarks']) ):
		frame['landmarks'][i][0] = of['landmarks'][i][0]
		frame['landmarks'][i][1] = of['landmarks'][i][1]
		frame['landmarks'][i][2] = of['landmarks'][i][2]
		if len(mat_trans) > 0:
			frame['landmarks'][i] = apply_matrix_position( frame['landmarks'][i], mat_trans )
		if 'center' in indices: 
			for j in range(3):
				if frame['min'][j] > frame['landmarks'][i][j]:
					frame['min'][j] = frame['landmarks'][i][j]
				if frame['max'][j] < frame['landmarks'][i][j]:
					frame['max'][j] = frame['landmarks'][i][j]
	
	if 'center' in indices:
		for i in range(3):
			frame['size'][i] = frame['max'][i] - frame['min'][i]
		# first frame > adjustment of the center
		if indices['center'] == None or len(indices['center']) != 3:
			indices['center'] = [0,0,0]
			indices['min'] = [0,0,0]
			indices['max'] = [0,0,0]
			indices['size'] = [0,0,0]
			for i in range(3):
				indices['center'][i] = frame['center'][i]
				indices['min'][i] = frame['min'][i]
				indices['max'][i] = frame['max'][i]
				indices['size'][i] = frame['size'][i]
		for i in range( len( of['landmarks']) ):
			for j in range(3):
				frame['landmarks'][i][j] = ( frame['landmarks'][i][j] - frame['center'][j] ) / frame['size'][j]
	
	if indices['all_indices']:
		
		frame['gazes'] = [[0,0,0] for i in range( 2 )]
		frame['gazes'][0][0] = of['gaze_0'][0]
		frame['gazes'][0][1] = of['gaze_0'][1]
		frame['gazes'][0][2] = of['gaze_0'][2]
		frame['gazes'][1][0] = of['gaze_1'][0]
		frame['gazes'][1][1] = of['gaze_1'][1]
		frame['gazes'][1][2] = of['gaze_1'][2]
		
		frame['pose_euler'] = [0,0,0]
		frame['pose_euler'][0] = of['head_rot'][0]
		frame['pose_euler'][1] = of['head_rot'][1]
		frame['pose_euler'][2] = of['head_rot'][2]
		if len(mat_rot) > 0:
			frame['pose_euler'] = apply_matrix_rotation( frame['pose_euler'], mat_rot )
	
	return frame

def parse_text_frame( words, indices, mat_trans = None, mat_rot = None ):
	
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
		if len(mat_trans) > 0:
			frame['landmarks'][i] = apply_matrix_position( frame['landmarks'][i], mat_trans )
			
	if indices['all_indices']:
		
		frame['gazes'] = [[0,0,0] for i in range( len(indices['gazes']) )]
		for i in range( len(indices['gazes']) ):
			for j in range(0,3):
				frame['gazes'][i][j] = parse_float( words[ indices['gazes'][i][j] ] )
			if len(mat_rot) > 0:
				frame['gazes'][i] = apply_matrix_rotation( frame['gazes'][i], mat_rot )
		
		frame['au'] = [None for i in range( len(indices['au']) )]
		for i in range( len(indices['au']) ):
			frame['au'][i] = parse_float( words[ indices['au'][i] ] )
		
		frame['pose_euler'] = [None for i in range( len(indices['pose_euler']) )]
		for i in range( len(indices['pose_euler']) ):
			frame['pose_euler'][i] = parse_float( words[ indices['pose_euler'][i] ] )
		if len(mat_rot) > 0:
			frame['pose_euler'] = apply_matrix_rotation( frame['pose_euler'], mat_rot )
	
	validate_frame( frame, indices )
	
	return frame

'''
## EXPORT ##t
'''

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

'''
## ANIMATION ##
'''

def generate_aabb( frame = None, center = None ):
	
	if frame == None:
		return { 'center':[0,0,0], 'min':[0,0,0], 'max':[0,0,0], 'size':[0,0,0] }
	
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

def generate_sound_ref():
	return { 'path': None, 'bits_per_sample': 16, 'sample_rate': 44100, 'channels': 2 }

def generate_video_ref():
	return { 'path': None, 'width': None, 'height': None }

def generate_structure():
	
	out = {}
	keys = get_mandatory_keys( 'structrue' )
	for k in keys:
		if k[2] is list:
			out[k[0]] = []
		if k[2] is dict:
			out[k[0]] = {}
		if k[2] is float:
			out[k[0]] = 0.0
		if k[2] is int:
			out[k[0]] = 0
	return out

def accumulate_aabb( src, dst ):
	
	for j in range(3):
		dst['center'][j] += src['center'][j]
		if dst['min'][j] > src['min'][j]:
			dst['min'][j] = src['min'][j]
		if dst['max'][j] < src['max'][j]:
			dst['max'][j] = src['max'][j]
	return dst

def blank_animation( indices ):
	
	animation = {}
	animation['duration'] = 0
	animation['frame_count'] = 0
	animation['action_unit_count'] = 0
	animation['action_unit_count'] = 0
	animation['gaze_count'] = 0
	animation['sound'] = generate_sound_ref()
	animation['video'] = generate_video_ref()
	animation['fields'] = []
	for k in indices.keys():
		if k == 'valid' or k == 'all_indices':
			continue
		animation['fields'].append( k )
	animation['aabb'] = generate_aabb()
	animation['aabb_total'] = generate_aabb()
	animation['scale'] = 1
	
	animation['frames'] = []
	
	return animation

def pack_animation( frames, indices ):
	
	if len(frames) == 0 or not indices['valid']:
		return None
	
	animation = blank_animation( indices )
	
	animation['duration'] = frames[len(frames)-1]['timestamp'] - frames[0]['timestamp']
	animation['frame_count'] = len(frames)
	animation['landmark_count'] = len(indices['landmarks'])
	animation['action_unit_count'] = len(indices['au'])
	animation['gaze_count'] = len(indices['gazes'])
	animation['structure'] = generate_structure()
	animation['aabb'] = generate_aabb( frames[0] )
	
	animation['scale'] = float( 1.0 / animation['aabb']['size'][0] )
	if animation['aabb']['size'][1] > animation['aabb']['size'][0]:
		animation['scale'] = float( 1.0 / animation['aabb']['size'][1] )
	if animation['aabb']['size'][2] > animation['aabb']['size'][1]:
		animation['scale'] = float( 1.0 / animation['aabb']['size'][2] )
		
	animation['frames'] = []
	for f in frames:
		newf = dict(f)
		newf.pop('valid', None)
		newf['index'] = len(animation['frames'])
		newf['aabb'] = generate_aabb( f, animation['aabb']['center'] )
		for i in range(len(newf['landmarks'])):
			for j in range(3):
				newf['landmarks'][i][j] -= animation['aabb']['center'][j]
				newf['landmarks'][i][j] *= animation['scale']
		animation['aabb_total'] = accumulate_aabb( newf['aabb'], animation['aabb_total'] )
		animation['frames'].append( newf )
	
	for j in range(3):
		animation['aabb_total']['center'][j] /= len( animation['frames'] )		
	for j in range(3):
		animation['aabb_total']['min'][j] -= animation['aabb_total']['center'][j]
		animation['aabb_total']['max'][j] -= animation['aabb_total']['center'][j]
		animation['aabb_total']['size'][j] = animation['aabb_total']['max'][j] - animation['aabb_total']['min'][j]
		
	return animation

def add_structure( anim, struct ):
	
	if not validate_animation( anim ):
		print( "lavatar::add_structure, animation is not valid" )
		return
	
	if type( struct ) is not dict:
		print( "lavatar::add_structure, error: provide a dict with valid keys" )
		return
	
	validf = get_mandatory_keys( 'structrue' )
	sks = struct.keys()
	for f in validf:
		if f[0] in sks:
			if type( struct[f[0]] ) is not f[2]:
				print( "lavatar::add_structure, warning: field '%s' does not have the right type and will be ignored" % f[0] )
				continue
			if f[2] is list:
				anim['structure'][f[0]] = list( struct[f[0]] )
			elif f[2] is float:
				anim['structure'][f[0]] = float( struct[f[0]] )
			elif f[2] is int:
				anim['structure'][f[0]] = int( struct[f[0]] )
			elif f[2] is dict:
				anim['structure'][f[0]] = dict( struct[f[0]] )

def validate_animation( anim ):
	
	if type( anim ) is not dict:
		return False, False
	
	err = ''
	warn = ''
	
	akeys = anim.keys()
	mfields = get_mandatory_keys( 'animation' )
	ofields = get_optional_keys( 'animation' )
	
	for f in mfields:
		if not f[0] in akeys:
			if err != '':
				err += '\n'
			err += "lavatar::validate_animation, error: missing animation field '%s'!" % f[0]
		elif anim[f[0]] == None:
			if err != '':
				err += '\n'
			err += "lavatar::validate_animation, error: animation field '%s' is null!" % f[0]
		# checking type!
		elif type(anim[f[0]]) is not f[2]:
			if err != '':
				err += '\n'
			err += "lavatar::validate_animation, error: animation field '%s' is not of the right type!" % f[0]
	
	for f in ofields:
		if not f[0] in akeys:
			if warn != '':
				warn += '\n'
			warn += "lavatar::validate_animation, warning: missing animation field '%s'!" % f[0]
		elif anim[f[0]] == None:
			if warn != '':
				warn += '\n'
			warn += "lavatar::validate_animation, warning: animation field '%s' is null!" % f[0]
		# checking type!
		elif type(anim[f[0]]) is not f[2]:
			if warn != '':
				warn += '\n'
			warn += "lavatar::validate_animation, warning: animation field '%s' is not of the right type!" % f[0]
	
	mfields = get_mandatory_keys( 'animation_frame' )
	ofields = get_optional_keys( 'animation_frame' )
	
	fi = 0
	for frame in anim['frames']:
		
		if type(frame) is not dict:
			if err != '':
				err += '\n'
			err += "lavatar::validate_animation, error: frame '%i' is invalid!" % fi
		
		akeys = frame.keys()
		for f in mfields:
			if not f[0] in akeys:
				if err != '':
					err += '\n'
				err += "lavatar::validate_animation, error: missing field '%s' in frame '%i'!" % (f[0],fi)
			elif frame[f[0]] == None:
				if err != '':
					err += '\n'
				err += "lavatar::validate_animation, error: field '%s' in frame '%i' is null!" % (f[0],fi)
			# checking type!
			elif type(frame[f[0]]) is not f[2]:
				if err != '':
					err += '\n'
				err += "lavatar::validate_animation, error: field '%s' in frame '%i' is not of the right type!" % (f[0],fi)

		for f in ofields:
			if not f[0] in akeys:
				if warn != '':
					warn += '\n'
				warn += "lavatar::validate_animation, warning: missing field '%s' in frame '%i'!" % (f[0],fi)
			elif frame[f[0]] == None:
				if warn != '':
					warn += '\n'
				warn += "lavatar::validate_animation, warning: field '%s' in frame '%i' is null!" % (f[0],fi)
			# checking type!
			elif type(frame[f[0]]) is not f[2]:
				if warn != '':
					warn += '\n'
				warn += "lavatar::validate_animation, warning: field '%s' in frame '%i' is not of the right type!" % (f[0],fi)
		
		fi += 1
	
	if err != '':
		print( err )
		print( warn )
		return False, False
	elif warn != '':
		print( warn )
		return True, False
	else:
		return True, True

def add_sound( anim, sound_path ):
	
	if not validate_animation( anim ):
		print( "lavatar::add_sound, animation is not valid" )
		return
	
	if not 'sound' in anim.keys():
		print( "lavatar::add_sound, no sound slot in this animation, use optional params" )
		return
	
	if not os.path.exists( sound_path ):
		print( "lavatar::add_sound, file '%s' not found on the disk, check your path" % sound_path )
		return
	
	abs_path = os.path.abspath(sound_path)
	anim['sound']['path'] = abs_path

def add_video( anim, video_path ):
	
	if not validate_animation( anim ):
		print( "lavatar::add_video, animation is not valid" )
		return
	
	if not 'video' in anim.keys():
		print( "lavatar::add_video, no video slot in this animation, use optional params" )
		return
	
	if not os.path.exists( video_path ):
		print( "lavatar::add_video, file '%s' not found on the disk, check your path" % video_path )
		return
	
	abs_path = os.path.abspath(video_path)
	anim['video']['path'] = abs_path

'''
## PLAYBACK ##
'''

def generate_interpolation_frame( fields ):
	
	frame = {}
	for f in fields:
		frame[f[0]] = f[1]
	return frame

def frame_interpolation( anim, fields, index, elapsed ):
	
	out = generate_interpolation_frame( fields )
	
	if index == 0:
		index = 1
	
	diff_time = anim['frames'][index]['timestamp'] - anim['frames'][index-1]['timestamp']
	rel_time = elapsed - anim['frames'][index-1]['timestamp']
	pc = rel_time / diff_time
	if pc < 0:
		pc = 0
	elif pc > 1:
		pc = 1
	pci = 1 - pc
	
	prevf = anim['frames'][index-1]
	currf = anim['frames'][index]
	
	for f in fields:
		if f[0] == 'timestamp':
			out[f[0]] = prevf[f[0]] * pci + currf[f[0]] * pc
		elif f[0] == 'landmarks':
			out[f[0]] = []
			out['landmarks_data'] = []
			for i in range(anim['landmark_count']):
				v3 = [0,0,0]
				for j in range(3):
					v3[j] = prevf[f[0]][i][j] * pci + currf[f[0]][i][j] * pc
				out[f[0]].append( v3 )
				out['landmarks_data'] += v3
		elif f[0] == 'au':
			out[f[0]] = []
			for i in range(anim['action_unit_count']):
				out[f[0]].append( prevf[f[0]][i] * pci + currf[f[0]][i] * pc )
		elif f[0] == 'gazes':
			out[f[0]] = []
			out['gaze_data'] = []
			for i in range(anim['gaze_count']):
				v3 = [0,0,0]
				for j in range(3):
					v3[j] = prevf[f[0]][i][j] * pci + currf[f[0]][i][j] * pc
				out[f[0]].append( v3 )
				out['gaze_data'] += v3
	
	return out

def play_animation( anim, callback = None, fps = 100, speed = 1, loop = True, interpolation = True ):
	
	valid, optional = validate_animation( anim )
	
	if not valid:
		return
	
	frame_fields = []
	if interpolation:
		frame_fields = get_mandatory_keys( 'animation_frame_interpolation' )
		if optional:
			frame_fields += get_optional_keys( 'animation_frame_interpolation' )
	
	last_time = time.time()
	idle_time = 1.0 / fps

	elapsed_time = 0
	total_time = 0
	current_index = 0
	
	print( "playing animation" )
	
	while( True ):
		
		now = time.time()
		delta_time = now - last_time
		last_time = now

		elapsed_time += delta_time * speed
		total_time += delta_time
		
		if elapsed_time >= anim['frames'][current_index]['timestamp']:
			#print( elapsed_time, ' -> ', anim['frames'][current_index]['index'] )
			if callback != None and not interpolation:
				newf = dict(anim['frames'][current_index])
				newf['now'] = total_time
				callback( anim['frames'][current_index] )
			current_index += 1

		if current_index >= anim['frame_count']:
			if not loop:
				break
			print( "animation loop" )
			elapsed_time -= anim['frames'][current_index-1]['timestamp']
			current_index = 0
		
		if callback != None and interpolation:
			interframe = frame_interpolation( anim, frame_fields, current_index, elapsed_time )
			interframe['now'] = total_time
			callback( interframe )
		
		time.sleep( idle_time )

'''
## OSC ##
'''

def init_osc_sender( ip, port ):
	print( "starting emission to " + ip + ":" + str( port ) )
	return udp_client.SimpleUDPClient( ip, port )

def send_full_frame( osc_sender, frame, marker_prefix = None ):
	
	if marker_prefix == None:
		marker_prefix = ''
	
	keys = frame.keys()
	data = [ frame['index'], frame['timestamp'] ]

	if 'landmarks' in keys:
		data += ['landmarks']
		for i in range( len( frame['landmarks'] ) ):
			data += frame['landmarks'][i]
		
	if 'gazes' in keys:
		data += ['gazes']
		for i in range( len( frame['gazes'] ) ):
			data += frame['gazes'][i]
	
	if 'pose_euler' in keys:
		data += ['pose_euler']
		data += frame['pose_euler']
	
	if 'center' in keys:
		data += ['center']
		data += frame['center']
	
	if 'min' in keys:
		data += ['min']
		data += frame['min']
	
	if 'max' in keys:
		data += ['max']
		data += frame['max']
	
	if 'size' in keys:
		data += ['size']
		data += frame['size']
	
	osc_sender.send_message( marker_prefix+'/ff', data )

def send_frame( osc_sender, frame, marker_prefix = None ):
	
	if marker_prefix == None:
		marker_prefix = ''
	
	keys = frame.keys()
	ts = [ frame['now'], frame['timestamp'] ]
	if 'landmarks_data' in keys:
		data = []
		data += ts
		data += frame['landmarks_data']
		osc_sender.send_message( marker_prefix+'/landmarks', data )
	if 'au' in keys:
		data = []
		data += ts
		data += frame['au']
		osc_sender.send_message( marker_prefix+'/actionunits', data )
	if 'gaze_data' in keys:
		data = []
		data += ts
		data += frame['gaze_data']
		osc_sender.send_message( marker_prefix+'/gaze', data )
	