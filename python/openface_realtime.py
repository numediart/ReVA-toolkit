import time
import keyboard
import _thread
# import configuration before PyOpenfaceVideo or sys.path will not be loaded
from openface_configuration import *
import lavatar.lavatar as lavatar
from PyOpenfaceVideo import *

IP = '127.0.0.1'
PORT = 25000
osc_sender = lavatar.init_osc_sender( IP, PORT )

last_time = time.time()
elapsed_time = 0

frame_indices = lavatar.generate_frame_indices()
print( frame_indices )

def ov_runner():
	global ov
	ov.start()

def frame_raw( f ):
	print( "\tgaze_0: ", f['gaze_0'][0], ',', f['gaze_0'][1], ',', f['gaze_0'][2] )
	print( "\tgaze_1: ", f['gaze_1'][0], ',', f['gaze_1'][1], ',', f['gaze_1'][2] )
	print( "\thead_rot: ", f['head_rot'][0], ',', f['head_rot'][1], ',', f['head_rot'][2] )
	print( "\thead_pos: ", f['head_pos'][0], ',', f['head_pos'][1], ',', f['head_pos'][2] )
	print( "\tlandmarks: " )
	for i in range( len(f['landmarks']) ):
		print( "\t\t", i, ':', f['landmarks'][i][0], ',', f['landmarks'][i][1], ',', f['landmarks'][i][2] )

def frame_lavatar( f ):
	keys = f.keys()
	print( "frame: ", f['index'] )
	print( "\ttimestamp: ", f['timestamp'] )
	if 'landmarks' in keys:
		print( "\tlandmarks: " )
		for i in range( len( f['landmarks'] ) ):
			print( "\t\t", i, ':', f['landmarks'][i][0], ',', f['landmarks'][i][1], ',', f['landmarks'][i][2] )
	if 'gazes' in keys:
		for i in range( len( f['gazes'] ) ):
			print( "\tgaze_%s: "%i, f['gazes'][i][0], ',', f['gazes'][i][1], ',', f['gazes'][i][2] )
	if 'pose_euler' in keys:
		print( "\tpose_euler: ", f['pose_euler'][0], ',', f['pose_euler'][1], ',', f['pose_euler'][2] )
	if 'center' in keys:
		print( "\tcenter: ", f['center'][0], ',', f['center'][1], ',', f['center'][2] )
	if 'min' in keys:
		print( "\tmin: ", f['min'][0], ',', f['min'][1], ',', f['min'][2] )
	if 'max' in keys:
		print( "\tmax: ", f['max'][0], ',', f['max'][1], ',', f['max'][2] )
	if 'size' in keys:
		print( "\tsize: ", f['size'][0], ',', f['size'][1], ',', f['size'][2] )
		
def frame_parsing( frame ):
	
	global last_time
	global elapsed_time
	
	now = time.time()
	delta = now - last_time
	last_time = now
	elapsed_time += delta
	# enable to print raw info of OpenfaceVideo
	#frame_raw( frame )
	f = lavatar.parse_osc_frame( frame, frame_indices, elapsed_time, MAT_TRANSLATION, MAT_ROTATION )
	# enable to print lavatar ready frame
	#frame_lavatar( f )
	lavatar.send_full_frame( osc_sender, f, '/of' )

ov = OpenfaceVideo()
ov.device = 0
# set model path: mandatory to start tracking
print( ">> ", OFV_LANDMARK )
print( ">> ", OFV_HAAR )
print( ">> ", OFV_MTCNN )
print( ">> ", OFV_AU )
ov.landmark_model = OFV_LANDMARK
ov.HAAR = OFV_HAAR
ov.MTCNN = OFV_MTCNN

ov.callback_frame( frame_parsing )

# waiting for the OpenfaceVideo to be stopped by pressing 'q'
print( "Press 'q' in the window to stop OpenfaceVideo" )
ov.start()