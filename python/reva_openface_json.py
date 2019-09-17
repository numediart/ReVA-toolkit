import reva.reva as reva
import copy
import os.path

'''
CSV_PATH = "../assets/openface/smile.csv"
WAV_PATH = "../assets/openface/smile_low.wav"
VIDEO_PATH = ""
JSON_PATH = "../json/anim/smile.json"
'''

CSV_PATH = "../assets/openface/laugh.csv"
WAV_PATH = "../assets/openface/laugh.wav"
VIDEO_PATH = ""
JSON_PATH = "../json/anim/laugh.json"

MAT_CORRECTION = reva.mat([
	[1,0,0,0],
	[0,0,1,0],
	[0,-1,0,0],
	[0,0,0,1]
])

MAT_ROTATION = reva.mat([
	[1,0,0,0],
	[0,1,0,0],
	[0,0,1,0],
	[0,0,0,1]
])

references = []
frames = []

def get_ref_for( field ):
	for i in references:
		if i['field'] == field:
			return i
	return None

def indentify_landmark2d( key ):
	lmid = reva.parse_int( key[2:] )
	if lmid == None:
		print( "failed to parse key", key, "as a landmark 2d"  )
		return None
	else:
		ref = get_ref_for( 'landmarks_2d' )
		if ref == None:
			ref = { 'field': 'landmarks_2d', 'indices': [] }
			references.append( ref )
		while lmid > len( ref['indices'] ) - 1:
			ref['indices'].append( [0,0] )
		return ref['indices'][lmid]

def indentify_landmark3d( key ):
	lmid = reva.parse_int( key[2:] )
	if lmid == None:
		print( "failed to parse key", key, "as a landmark 3d"  )
		return None
	else:
		ref = get_ref_for( 'landmarks_3d' )
		if ref == None:
			ref = { 'field': 'landmarks_3d', 'indices': [] }
			references.append( ref )
		while lmid > len( ref['indices'] ) - 1:
			ref['indices'].append( [0,0,0] )
		return ref['indices'][lmid]

def get_references( line ):
	
	words = line.split( ',' )
	for i in range(0,len(words)):
		w = words[i].strip()
		
		if w == 'timestamp':
			references.append( { 'field': 'timestamp', 'index': i } )
			
		elif w.startswith('gaze_0'):
			ref = get_ref_for( 'gaze_0' )
			if ref == None:
				ref = { 'field': 'gaze_0', 'indices': [0,0,0] }
				references.append( ref )
			if w.find( '_x' ) > 5:
				ref['indices'][0] = i
			elif w.find( '_y' ) > 5:
				ref['indices'][1] = i
			elif w.find( '_z' ) > 5:
				ref['indices'][2] = i
			
		elif w.startswith('gaze_1'):
			ref = get_ref_for( 'gaze_1' )
			if ref == None:
				ref = { 'field': 'gaze_1', 'indices': [0,0,0] }
				references.append( ref )
			if w.find( '_x' ) > 5:
				ref['indices'][0] = i
			elif w.find( '_y' ) > 5:
				ref['indices'][1] = i
			elif w.find( '_z' ) > 5:
				ref['indices'][2] = i
			
		elif w.startswith('pose_T'):
			ref = get_ref_for( 'pose_T' )
			if ref == None:
				ref = { 'field': 'pose_T', 'indices': [0,0,0] }
				references.append( ref )
			if w.find( 'x' ) > 5:
				ref['indices'][0] = i
			elif w.find( 'y' ) > 5:
				ref['indices'][1] = i
			elif w.find( 'z' ) > 5:
				ref['indices'][2] = i
			
		elif w.startswith('pose_R'):
			ref = get_ref_for( 'pose_R' )
			if ref == None:
				ref = { 'field': 'pose_R', 'indices': [0,0,0] }
				references.append( ref )
			if w.find( 'x' ) > 5:
				ref['indices'][0] = i
			elif w.find( 'y' ) > 5:
				ref['indices'][1] = i
			elif w.find( 'z' ) > 5:
				ref['indices'][2] = i
		
		elif w.startswith('x_'):
			indices = indentify_landmark2d( w )
			if indices == None:
				continue
			indices[0] = i
		elif w.startswith('y_'):
			indices = indentify_landmark2d( w )
			if indices == None:
				continue
			indices[1] = i
		
		elif w.startswith('X_'):
			indices = indentify_landmark3d( w )
			if indices == None:
				continue
			indices[0] = i
		elif w.startswith('Y_'):
			indices = indentify_landmark3d( w )
			if indices == None:
				continue
			indices[1] = i
		elif w.startswith('Z_'):
			indices = indentify_landmark3d( w )
			if indices == None:
				continue
			indices[2] = i
		
		else:
			#print( '???', i, w )
			pass

def parse_frame( line ):
	
	frame = copy.deepcopy(reva.FRAME_TEMPLATE)
	
	words = line.split( ',' )
	lw = len( words )
	
	if len(line) == 0 or lw < len(references):
		return
	
	for ref in references:
		
		if ref['field'] == 'timestamp':
			if ref['index'] > lw:
				continue
			frame['timestamp'] = reva.parse_float( words[ref['index']].strip() )
		
		if ref['field'] == 'gaze_0':
			if len( frame['gazes'] ) == 0:
				 frame['gazes'].append( [0,0,0] )
			ax = 0
			for i in ref['indices']:
				if i < lw:
					frame['gazes'][0][ax] = reva.parse_float( words[i].strip() )
				ax += 1
		
		if ref['field'] == 'gaze_1':
			while len( frame['gazes'] ) < 2:
				 frame['gazes'].append( [0,0,0] )
			ax = 0
			for i in ref['indices']:
				if i < lw:
					frame['gazes'][1][ax] = reva.parse_float( words[i].strip() )
				ax += 1
		
		if ref['field'] == 'pose_R':
			ax = 0
			for i in ref['indices']:
				if i < lw:
					frame['pose_euler'][ax] = reva.parse_float( words[i].strip() )
				ax += 1
		
		if ref['field'] == 'pose_T':
			ax = 0
			for i in ref['indices']:
				if i < lw:
					frame['pose_translation'][ax] = reva.parse_float( words[i].strip() )
				ax += 1
		
		if ref['field'] == 'landmarks_3d':
			frame['points'] = [ [0,0,0] for i in range( len( ref['indices'] ) ) ]
			for pt in range(len(ref['indices'])):
				for ax in range( len(ref['indices'][pt]) ):
					if ref['indices'][pt][ax] >= lw:
						continue
					frame['points'][pt][ax] = reva.parse_float( words[ref['indices'][pt][ax]].strip() )
	
	frames.append( frame )

with open( CSV_PATH ) as csv:
	line = csv.readline()
	get_references( line )
	print( references )
	while line:
		line = csv.readline()
		parse_frame( line )
	csv.close()

animation = reva.pack_animation( frames, os.path.splitext(os.path.basename(JSON_PATH))[0], MAT_CORRECTION )

reva.animation_add_sound( animation, WAV_PATH, JSON_PATH )
reva.animation_add_video( animation, VIDEO_PATH, JSON_PATH )

reva.save_animation_json( animation, JSON_PATH )