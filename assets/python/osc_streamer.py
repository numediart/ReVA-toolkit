import time

CSV_PATH = "../openface/happy_1_77.csv"
FIELD_SEPARATOR = ','
IDLE_TIME = 0.01 # idle time of main loop, equivalent to fps

raw_file = open( CSV_PATH )
fields = []
frames = []
frame_count = 0
duration = 0

def decompress_fields( l ):
	
	words = l.split( FIELD_SEPARATOR )
	for w in words:
		w = w.strip()
		fields.append( w )

def decompress_frame( l ):
	
	frame = {}
	frame['num'] = None
	frame['timestamp'] = None
	frame['confidence'] = None
	frame['success'] = None
	frame['data'] = []
	
	words = l.split( FIELD_SEPARATOR )
	floats = []
	for w in words:
		w = w.strip()
		floats.append( float(w) )
	
	if len( floats ) != len( fields ):
		print( "frame length does not match fields length" )
		return
	
	i = 0
	valid = 0
	for f in fields:
		if f == 'frame':
			frame['num'] = int(floats[i])
			valid += 1
		if f == 'timestamp':
			frame['timestamp'] = floats[i]
			valid += 1
		if f == 'confidence':
			frame['confidence'] = floats[i]
			valid += 1
		if f == 'success':
			frame['success'] = bool( floats[i] )
			valid += 1
		else:
			frame['data'].append( floats[i] )
		i += 1
	
	if frame['num'] == None or frame['timestamp'] == None or frame['confidence'] == None or frame['success'] == None:
		print( "Invalid frame, missing required fields, check your fields on first line!" )
		return
	
	frames.append( frame )

def parse_csv():
	
	global frame_count
	
	for line in raw_file:
		line = line.strip()
		if len(line) == 0:
			continue
		if len(fields) == 0:
			decompress_fields( line )
		else:
			decompress_frame( line )
	
	frame_count = len( frames )

	if frame_count > 0:
		print( "succesfully decompressed " + str( frame_count ) + " frame(s), starting emission" )
	else:
		print( "no available frames..." )

def main_loop():
	
	if frame_count > 0:

		duration = frames[len(frames)-1]['timestamp'] - frames[0]['timestamp']
		print( "total duration: " + str( duration ) )

		last_time = time.time()
		
		elapsed_time = 0
		current_index = 0

		while( True ):

			now = time.time()
			delta_time = now - last_time
			last_time = now

			elapsed_time += 1

			if frames[current_index]['timestamp'] <= elapsed_time:
				print( elapsed_time, ' -> ', frames[current_index]['num'] )
				current_index += 1

			if current_index >= frame_count:
				print( "the last frame reached!" )
				elapsed_time -= frames[current_index-1]['timestamp']
				current_index = 0

			time.sleep( IDLE_TIME )

parse_csv()

main_loop()