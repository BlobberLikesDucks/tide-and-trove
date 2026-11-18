class_name Credits
extends Resource
## The game's credits (res://data/credits.tres). Open that file in the Godot
## editor and change the names/roles in the Inspector - the Credits screen in the
## main menu reads it, nothing else needs to change.

@export var title: String = "Tide & Trove"
@export var entries: Array[CreditEntry] = []

const PATH := "res://data/credits.tres"


static func load_default() -> Credits:
	var c := load(PATH) as Credits
	return c if c else Credits.new()
