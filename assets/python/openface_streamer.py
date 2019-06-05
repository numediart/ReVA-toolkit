import lavatar.lavatar as lavatar
from openface_configuration import *

IP = '127.0.0.1'
PORT = 25000

CSV_PATH = "../openface/laugh_1_300.csv"

osc_sender = lavatar.init_osc_sender( IP, PORT )
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
			f = lavatar.parse_text_frame( line.split( FIELD_SEPARATOR ), indices, MAT_TRANSLATION, MAT_ROTATION )			if not f['valid']:
				continue
			frames.append( f )

def animation_callback( frame ):
	lavatar.send_frame( osc_sender, frame )

load_csv( CSV_PATH )

animation = lavatar.pack_animation( frames, indices )
lavatar.play_animation( animation, speed = 0.5, callback = animation_callback )
