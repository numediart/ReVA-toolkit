'''
-- REQUIREMENTS --

this script requires python-osc mnodule!
install it with 
$ sudo pip3 install python-osc

-- USAGE --

displaying the configuration arguments recognised by this script:
	$ python3 osc_streamer.py -h

loading a custom CSV file, speed at 50% + eanbling interpolation and emission verbose 
	$ python3 osc_streamer.py --start 1 --vf 0 --ve 1 --speed 0.5 --i 1 --csv ../openface/sad_1_96.csv

loading a custom CSV file, and verifying the fields and their index in the OSC messages 
	$ python3 osc_streamer.py --start 0 --vf 1 --csv ../openface/sad_1_96.csv

reconfiguration of the OSC emission
	$ python3 osc_streamer.py --ip 192.168.1.5 --port 8000

'''

import time
import argparse
from pythonosc import osc_message_builder
from pythonosc import udp_client

'''
-- CONFIGURATION --
'''

IP = '127.0.0.1'
PORT = 25000
MARKER = '/openface'
AUTOSTART = True

VERBOSE_FIELD = False
VERBOSE_EMISSION = False

CSV_PATH = "../openface/laugh_1_300.csv"
FIELD_SEPARATOR = ','
IDLE_TIME = 0.015 # idle time of main loop, equivalent to fps
SPEED = 1
INTERPOLATION = False

'''
-- ARGUMENTS --
'''

parser = argparse.ArgumentParser(description='Openface CSV streamer')
parser.add_argument('--ip', type=str, help='OSC ip, "127.0.0.1" by default')
parser.add_argument('--port', type=int, help='OSC port, 25000 by default')
parser.add_argument('--marker', type=str, help='OSC marker, "/openface" by default')
parser.add_argument('--start', type=int, help='OSC emission autostart, false by default')
parser.add_argument('--vf', type=int, help='verbose fields, false by default')
parser.add_argument('--ve', type=int, help='verbose emission, false by default')
parser.add_argument('--speed', type=float, help='emission speed, 1 by default')
parser.add_argument('--i', type=float, help='enabling interpolation, false by default')
parser.add_argument('--csv', type=str, help='csv path to load')
parser.add_argument('--sep', type=str, help='separator character for csv, "," by default')
parser.add_argument('--idle', type=str, help='idle time of main loop, ' + str(IDLE_TIME) + ' by default')

args = parser.parse_args()
if args.ip != None:
	IP = args.ip
if args.port != None:
	PORT = args.port
if args.marker != None:
	MARKER = args.marker
if args.start != None:
	AUTOSTART = bool(args.start)
if args.vf != None:
	VERBOSE_FIELD = bool(args.vf)
if args.ve != None:
	VERBOSE_EMISSION = bool(args.ve)
if args.speed != None:
	SPEED = args.speed
if args.i != None:
	INTERPOLATION = bool(args.i)
if args.csv != None:
	CSV_PATH = args.csv
if args.sep != None:
	FIELD_SEPARATOR = args.sep
if args.idle != None:
	IDLE_TIME = args.idle

'''
-- GLOBALS --
'''

raw_file = open( CSV_PATH )
fields = []
frames = []
frame_count = 0
duration = 0
client = None

def decompress_fields( l ):
	
	words = l.split( FIELD_SEPARATOR )
	for w in words:
		w = w.strip()
		fields.append( w )
	
	if VERBOSE_FIELD:
		for i in range( 0, len(fields) ):
			s = "field[" + str(i) + "]"
			if i > 3:
				s += " (data[" + str(i-4) + "])"
			s += " : " + fields[i]
			print( s )

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
	duration = frames[len(frames)-1]['timestamp'] - frames[0]['timestamp']
	
	if frame_count > 0:
		print( "succesfully decompressed " + str( frame_count ) + " frame(s), total duration: " + str( duration ) + " sec" )
	else:
		print( "no available frames..." )

def interpolate( index, t ):
	
	global client
	
	if index == 0:
		client.send_message( MARKER, frames[index]['data'] )
		return
	
	diff_time = frames[index]['timestamp'] - frames[index-1]['timestamp']
	rel_time = t - frames[index-1]['timestamp']
	pc = rel_time / diff_time
	if pc < 0:
		pc = 0
	elif pc > 1:
		pc = 1
	pci = 1 - pc
	
	# mixing data
	prevf = frames[index-1]
	currf = frames[index]
	data = []
	dnum = len( prevf['data'] )
	for d in range(0,dnum):
		data.append( prevf['data'][d] * pci + currf['data'][d] * pc )
	
	client.send_message( MARKER, data )

def main_loop():
	
	global client
	
	if not AUTOSTART:
		return
	
	print( "starting emission to " + IP + ":" + str( PORT ) )
	
	client = udp_client.SimpleUDPClient( IP, PORT )
	
	if frame_count > 1:

		last_time = time.time()
		
		elapsed_time = 0
		current_index = 0

		while( True ):

			now = time.time()
			delta_time = now - last_time
			last_time = now

			elapsed_time += delta_time * SPEED
			
			if elapsed_time >= frames[current_index]['timestamp']:
				if VERBOSE_EMISSION:
					print( elapsed_time, ' -> ', frames[current_index]['num'] )
				if not INTERPOLATION:
					client.send_message( MARKER, frames[current_index]['data'] )
				current_index += 1

			if current_index >= frame_count:
				if VERBOSE_EMISSION:
					print( "the last frame reached!" )
				elapsed_time -= frames[current_index-1]['timestamp']
				current_index = 0
			
			if INTERPOLATION:
				interpolate( current_index, elapsed_time )

			time.sleep( IDLE_TIME )

'''
-- PROCESS --
'''

parse_csv()

main_loop()