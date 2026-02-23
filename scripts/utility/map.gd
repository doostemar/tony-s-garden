class_name Map
extends Resource

var _map: Dictionary

func init():
	_map = {}

func add( key, value ):
	if _map.is_empty() or _map[ key ] == null:
		_map[ key ] = value
		
func remove( key ) -> bool:
	if _map[ key ]:
		_map.erase( key )
		return true
	return false

func get_value( key ):
	return _map.get( key )
	
func get_dict():
	return _map

func is_empty():
	return _map.is_empty()
