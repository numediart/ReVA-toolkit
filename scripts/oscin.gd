#tool

extends OSCreceiver

func _ready():
	start()

func _process(delta):
	# osc emits signals, no need to parse messages here
	return
	while( has_waiting_messages() ):
		var msg = get_next_message()
		var s = msg.address()  + " | " + str(msg.arg_num()) + " | "
		for i in msg.arg_num():
			s += str( msg.arg(i)) + " | "
		print( s )