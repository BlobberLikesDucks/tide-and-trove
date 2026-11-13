## Applies JSON-sourced values to Object properties. JSON has no Vector2, Color
## or NodePath, and Object.set() silently ignores a value of the wrong type, so
## each value is converted to the property's declared type first. Accepts the
## {"x":..,"y":..}-style dictionaries GodotMCPJsonRpc emits, plain arrays, and
## Godot constructor strings such as "Vector2(1, 2)".
class_name GodotMCPPropertyValue
extends RefCounted


## Sets `property` on `target`. Returns "" on success, otherwise an error message.
static func apply(target: Object, property: String, value: Variant) -> String:
	var expected_type := _declared_type(target, property)
	if expected_type == -1:
		return "%s has no property '%s'" % [target.get_class(), property]

	var converted: Variant = _convert(value, expected_type)
	if value != null and converted == null:
		return "Cannot convert %s to %s for '%s'" % [JSON.stringify(value), type_string(expected_type), property]

	target.set(property, converted)
	return ""


static func _declared_type(target: Object, property: String) -> int:
	for entry in target.get_property_list():
		if entry["name"] == property:
			return entry["type"]
	return -1


static func _convert(value: Variant, expected_type: int) -> Variant:
	if expected_type == TYPE_NIL or typeof(value) == expected_type:
		return value

	if expected_type == TYPE_OBJECT:
		if value is String and ResourceLoader.exists(value):
			return load(value)
		return value if value is Object else null

	match expected_type:
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			return type_convert(value, expected_type)

	if value is String:
		return _from_string(value, expected_type)
	if value is Dictionary:
		return _from_dictionary(value, expected_type)
	if value is Array:
		return _from_array(value, expected_type)
	return null


static func _from_string(text: String, expected_type: int) -> Variant:
	if expected_type == TYPE_COLOR and Color.html_is_valid(text):
		return Color.html(text)
	var parsed: Variant = str_to_var(text)
	return parsed if typeof(parsed) == expected_type else null


static func _from_dictionary(value: Dictionary, expected_type: int) -> Variant:
	match expected_type:
		TYPE_VECTOR2:
			return Vector2(value.get("x", 0.0), value.get("y", 0.0))
		TYPE_VECTOR2I:
			return Vector2i(value.get("x", 0), value.get("y", 0))
		TYPE_VECTOR3:
			return Vector3(value.get("x", 0.0), value.get("y", 0.0), value.get("z", 0.0))
		TYPE_VECTOR3I:
			return Vector3i(value.get("x", 0), value.get("y", 0), value.get("z", 0))
		TYPE_COLOR:
			return Color(value.get("r", 0.0), value.get("g", 0.0), value.get("b", 0.0), value.get("a", 1.0))
		TYPE_RECT2:
			return Rect2(value.get("x", 0.0), value.get("y", 0.0), value.get("width", 0.0), value.get("height", 0.0))
		TYPE_RECT2I:
			return Rect2i(value.get("x", 0), value.get("y", 0), value.get("width", 0), value.get("height", 0))
	return null


static func _from_array(value: Array, expected_type: int) -> Variant:
	var size := value.size()
	match expected_type:
		TYPE_VECTOR2 when size == 2:
			return Vector2(value[0], value[1])
		TYPE_VECTOR2I when size == 2:
			return Vector2i(value[0], value[1])
		TYPE_VECTOR3 when size == 3:
			return Vector3(value[0], value[1], value[2])
		TYPE_VECTOR3I when size == 3:
			return Vector3i(value[0], value[1], value[2])
		TYPE_COLOR when size == 3:
			return Color(value[0], value[1], value[2])
		TYPE_COLOR when size == 4:
			return Color(value[0], value[1], value[2], value[3])
		TYPE_RECT2 when size == 4:
			return Rect2(value[0], value[1], value[2], value[3])
		TYPE_RECT2I when size == 4:
			return Rect2i(value[0], value[1], value[2], value[3])
	return type_convert(value, expected_type) if expected_type >= TYPE_PACKED_BYTE_ARRAY else null
