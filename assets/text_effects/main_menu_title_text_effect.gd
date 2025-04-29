# Stolen from: https://www.youtube.com/watch?v=8CZfqdUd3bM&list=PLvy2hkfDK8JqvCAev_czR3CPriX0ViVwC&index=2
# Various changes made from source.

extends RichTextEffect
class_name MainMenuTitle 

var bbcode = "main_menu_title"

var red_range = [0.3, 0.8]
var green_range = [0.3, 0.7]
var blue_range = [0.3, 0.6]

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var time = float(Time.get_ticks_msec()) / 400
	var red = remap(sin(time), -1, 1, red_range[0], red_range[1])
	var green = remap(sin(time * 2), -1, 1, green_range[0], green_range[1])
	var blue = remap(cos(time), -1, 1, blue_range[0], blue_range[1])
	char_fx.color = Color(red, green, blue)
	return true
