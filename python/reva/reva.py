import os
import math
import numpy
import time
import json
import argparse
from .transformations import *
from pythonosc import osc_message_builder
from pythonosc import udp_client

'''
## UTILS ##
all general & utility functions
'''

def mat( data ):
	return numpy.matrix( data )

def mat_euler( x, y, z ):
	'''
	alpha, beta, gamma = 0.123, -1.234, 2.345
	origin, xaxis, yaxis, zaxis = [0, 0, 0], [1, 0, 0], [0, 1, 0], [0, 0, 1]
	I = identity_matrix()
	Rx = rotation_matrix(alpha, xaxis)
	print(Rx)
	Ry = rotation_matrix(beta, yaxis)
	print(Ry)
	Rz = rotation_matrix(gamma, zaxis)
	print(Rz)
	R = concatenate_matrices(Rx, Ry, Rz)
	euler = euler_from_matrix(R, 'rxyz')
	numpy.allclose([alpha, beta, gamma], euler)
	Re = euler_matrix(alpha, beta, gamma, 'rxyz')
	print(Re)
	print(is_same_transform(R, Re))
	'''
	return euler_matrix( x, y, z, 'rxyz')

def parse_int( txt ):
	try:
		return int( txt.strip() )
	except Exception as e:
		print( e )
		return None

def parse_float( txt ):
	try:
		return float( txt.strip() )
	except Exception as e:
		print( e )
		return None

def apply_matrix_position( xyz, matrix ):
	trans = translation_matrix( numpy.array([xyz[0],xyz[1],xyz[2]]) )
	x, y, z = translation_from_matrix( concatenate_matrices( matrix, trans ) )
	return [ x, y, z ]

# provide euler angles in RADIANS!!! (if degree, use a/180*PI)
def apply_matrix_rotation( xyz, matrix ):
	em = euler_matrix( xyz[0], xyz[1], xyz[2], axes='sxyz' )
	rot = euler_from_matrix( concatenate_matrices( matrix, em ), axes='sxyz' ) # godot convention for rotations!!!
	return [rot[0],rot[1],rot[2]]