import lavatar.lavatar as lavatar
from openface_configuration import *

CSV_PATH = "../openface/smile.csv"
WAV_PATH = ""
VIDEO_PATH = ""
JSON_PATH = "../godot/assets/json/smile.json"

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
			f = lavatar.parse_text_frame( line.split( FIELD_SEPARATOR ), indices, MAT_TRANSLATION, MAT_ROTATION )
			if not f['valid']:
				continue
			frames.append( f )

load_csv( CSV_PATH )

animation = lavatar.pack_animation( frames, indices )
lavatar.add_structure( animation, STRUCTURE )
lavatar.add_sound( animation, WAV_PATH )
#lavatar.add_video( animation, VIDEO_PATH )
lavatar.save_animation_json( animation, JSON_PATH )