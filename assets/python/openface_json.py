import lavatar.lavatar as lavatar
from openface_configuration import *

CSV_PATH = "../openface/laugh_1_300.csv"
JSON_PATH = "../json/laugh_1_300.json"

indices = None
frames = []

def load_csv( path ):
	
	global indices
	
	raw_file = open( path )
	
	for line in raw_file:
		line = line.strip()
		if len(line) == 0:
			continue
		if indices == None:
			indices = extract_indices( line )
			if indices == None:
				return
		else:
			f = lavatar.parse_text_frame( line.split( FIELD_SEPARATOR ), indices, CORRECTION_MATRIX )
			if not f['valid']:
				continue
			frames.append( f )

load_csv( CSV_PATH )

animation = lavatar.pack_animation( frames, indices )
lavatar.save_animation_json( animation, JSON_PATH )