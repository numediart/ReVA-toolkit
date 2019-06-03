import lavatar.lavatar as lavatar

CSV_PATH = "../openface/laugh_1_300.csv"
FIELD_SEPARATOR = ','

TIMESTAMP_FIELD = 'timestamp'
GAZE_FIELDS = [ ['gaze_0_x','gaze_0_y','gaze_0_z'], ['gaze_1_x','gaze_1_y','gaze_1_z'] ]
LANDMARKS_FIELDS = [['X_0','Y_0','Z_0'], ['X_1','Y_1','Z_1'], ['X_2','Y_2','Z_2'], ['X_3','Y_3','Z_3'], ['X_4','Y_4','Z_4'], ['X_5','Y_5','Z_5'], ['X_6','Y_6','Z_6'], ['X_7','Y_7','Z_7'], ['X_8','Y_8','Z_8'], ['X_9','Y_9','Z_9'], ['X_10','Y_10','Z_10'], ['X_11','Y_11','Z_11'], ['X_12','Y_12','Z_12'], ['X_13','Y_13','Z_13'], ['X_14','Y_14','Z_14'], ['X_15','Y_15','Z_15'], ['X_16','Y_16','Z_16'], ['X_17','Y_17','Z_17'], ['X_18','Y_18','Z_18'], ['X_19','Y_19','Z_19'], ['X_20','Y_20','Z_20'], ['X_21','Y_21','Z_21'], ['X_22','Y_22','Z_22'], ['X_23','Y_23','Z_23'], ['X_24','Y_24','Z_24'], ['X_25','Y_25','Z_25'], ['X_26','Y_26','Z_26'], ['X_27','Y_27','Z_27'], ['X_28','Y_28','Z_28'], ['X_29','Y_29','Z_29'], ['X_30','Y_30','Z_30'], ['X_31','Y_31','Z_31'], ['X_32','Y_32','Z_32'], ['X_33','Y_33','Z_33'], ['X_34','Y_34','Z_34'], ['X_35','Y_35','Z_35'], ['X_36','Y_36','Z_36'], ['X_37','Y_37','Z_37'], ['X_38','Y_38','Z_38'], ['X_39','Y_39','Z_39'], ['X_40','Y_40','Z_40'], ['X_41','Y_41','Z_41'], ['X_42','Y_42','Z_42'], ['X_43','Y_43','Z_43'], ['X_44','Y_44','Z_44'], ['X_45','Y_45','Z_45'], ['X_46','Y_46','Z_46'], ['X_47','Y_47','Z_47'], ['X_48','Y_48','Z_48'], ['X_49','Y_49','Z_49'], ['X_50','Y_50','Z_50'], ['X_51','Y_51','Z_51'], ['X_52','Y_52','Z_52'], ['X_53','Y_53','Z_53'], ['X_54','Y_54','Z_54'], ['X_55','Y_55','Z_55'], ['X_56','Y_56','Z_56'], ['X_57','Y_57','Z_57'], ['X_58','Y_58','Z_58'], ['X_59','Y_59','Z_59'], ['X_60','Y_60','Z_60'], ['X_61','Y_61','Z_61'], ['X_62','Y_62','Z_62'], ['X_63','Y_63','Z_63'], ['X_64','Y_64','Z_64'], ['X_65','Y_65','Z_65'], ['X_66','Y_66','Z_66'], ['X_67','Y_67','Z_67']]
ACTION_UNIT_FIELDS = [ 'AU01_r','AU02_r','AU04_r','AU05_r','AU06_r','AU07_r','AU09_r','AU10_r','AU12_r','AU14_r','AU15_r','AU17_r','AU20_r','AU23_r','AU25_r','AU26_r','AU45_r','AU01_c','AU02_c','AU04_c','AU05_c','AU06_c','AU07_c','AU09_c','AU10_c','AU12_c','AU14_c','AU15_c','AU17_c','AU20_c','AU23_c','AU25_c','AU26_c','AU28_c','AU45_c' ]
CORRECTION_MATRIX = lavatar.get_matrix([
	[1,0,0,0],
	[0,0,1,0],
	[0,1,0,0],
	[0,0,0,1]
])

indices = lavatar.generate_indices( True ) # False to only extract timestamp & landmarks indices
frames = []

raw_file = open( CSV_PATH )

def extract_indices( l ):
	
	global FIELD_SEPARATOR
	global GAZE_FIELDS
	global LANDMARKS_FIELDS
	global FACIAL_ACTION_FIELDS
	global indices
	
	# searching FIELDS
	i = 0
	for word in l.split( FIELD_SEPARATOR ):
		word = word.strip()
		if word == TIMESTAMP_FIELD:
			indices['timestamp'] = i
		else:
			for xyz in LANDMARKS_FIELDS:
				for axis in xyz:
					if axis == word:
						if indices['landmarks'] == None:
							indices['landmarks'] = [[None,None,None] for i in range(len(LANDMARKS_FIELDS))]
						index = int( word[2:] )
						ax = word[:1].lower()
						if ax == 'x':
							indices['landmarks'][index][0] = i
						elif ax == 'y':
							indices['landmarks'][index][1] = i
						elif ax == 'z':
							indices['landmarks'][index][2] = i
			for xyz in GAZE_FIELDS:
				for axis in xyz:
					if axis == word:
						if indices['gaze'] == None:
							indices['gaze'] = [[None,None,None] for i in range(len(GAZE_FIELDS))]
						index = int( word[5:6] )
						ax = word[-1:].lower()
						if ax == 'x':
							indices['gaze'][index][0] = i
						elif ax == 'y':
							indices['gaze'][index][1] = i
						elif ax == 'z':
							indices['gaze'][index][2] = i
			if 'au' in indices.keys():
				for field in ACTION_UNIT_FIELDS:
					if field == word:
						if indices['au'] == None:
							indices['au'] = []
						indices['au'].append( i )
		
		i += 1
	
	return lavatar.validate_indices( indices )

def load_csv():
	
	global indices
	global raw_file
	
	for line in raw_file:
		line = line.strip()
		if len(line) == 0:
			continue
		if not indices['valid']:
			if not extract_indices( line ):
				return
		else:
			f = lavatar.parse_text_frame( line.split( FIELD_SEPARATOR ), indices, CORRECTION_MATRIX )
			if not f['valid']:
				continue
			frames.append( f )

load_csv()

#print( indices )
#print( frames )

animation = lavatar.pack_animation( frames, indices )
lavatar.save_animation_json( animation, 'test.json' )



