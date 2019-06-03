def get_mandatory_indices( usage = 'index' ):
	if usage == 'index':
		return [ ('valid',False,bool), ('all_indices',False,bool), ('timestamp',None,int), ('landmarks',None,list) ]
	elif usage == 'frame':
		return [ ('valid',False,bool), ('timestamp',None,float), ('landmarks',None,list) ]

def get_optional_indices( usage = 'index' ):
	if usage == 'index':
		return [ ('gaze_0',None,list), ('gaze_1',None,list), ('au',None,list) ]
	elif usage == 'frame':
		return [ ('gaze_0',None,list), ('gaze_1',None,list), ('au',None,list) ]

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
			for i in range(0,3):
				if indices['gaze_0'][i] == None:
					if err != '':
						err += '\n'
					err += "lavatar::validate_indices, error: missing data in gaze_0 on axis '%i'!" % i
			for i in range(0,3):
				if indices['gaze_1'][i] == None:
					if err != '':
						err += '\n'
					err += "lavatar::validate_indices, error: missing data in gaze_0 on axis '%i'!" % i
	
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
			for i in range(0,3):
				if frame['gaze_0'][i] == None:
					if err != '':
						err += '\n'
					err += "lavatar::validate_frame, error: missing data in gaze_0 on axis '%i'!" % i
			for i in range(0,3):
				if frame['gaze_1'][i] == None:
					if err != '':
						err += '\n'
					err += "lavatar::validate_frame, error: missing data in gaze_0 on axis '%i'!" % i
	
	if err != '':
		print( err )
		return False
	else:
		frame['valid'] = True
	
	return True

def parse_int( txt ):
	return int( txt.strip() )

def parse_float( txt ):
	return float( txt.strip() )

def parse_text_frame( words, indices ):
	
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
	
	if indices['all_indices']:
		frame['gaze_0'] = [0,0,0] 
		for i in range(0,3):
			frame['gaze_0'][i] = parse_float( words[ indices['gaze_0'][i] ] )
		frame['gaze_1'] = [0,0,0] 
		for i in range(0,3):
			frame['gaze_1'][i] = parse_float( words[ indices['gaze_1'][i] ] )
		frame['au'] = [None for i in range( len(indices['au']) )]
		for i in range( len(indices['au']) ):
			frame['au'][i] = parse_float( words[ indices['au'][i] ] )
	
	validate_frame( frame, indices )
	
	return frame