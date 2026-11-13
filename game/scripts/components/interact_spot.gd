class_name InteractSpot
extends Node
## Inspector-configured interaction for a placed scene object. Drop it as a
## child of any model in the editor, set the prompt and what it does, and the
## look-ray prompt + Interact key work without any per-object code.
##
## The action is a method call on `target` (default: the World), e.g.
## action_method = "open_panel", action_args = ["shop"].

## Fallback prompt text.
@export var prompt: String = "Interact"
## Optional method on `target` that returns live prompt text (String).
@export var prompt_method: StringName
## Method on `target` called when the player presses Interact.
@export var action_method: StringName
@export var action_args: Array = []
## Node that owns the methods. Empty = the World root.
@export var target: NodePath
## Higher priority wins when several prompts overlap.
@export var priority: int = 1

var interactable: Interactable


func _ready() -> void:
	_attach.call_deferred()  # the host is still adding its children during _ready


func _attach() -> void:
	var host := get_parent() as Node3D
	if host == null:
		push_warning("InteractSpot must be a child of a Node3D: %s" % get_path())
		return
	interactable = Interactable.attach(host, prompt, _activate)
	interactable.prio = priority
	if prompt_method != &"":
		interactable.text_fn = _prompt_text


func _target() -> Node:
	if target.is_empty():
		return World.instance
	return get_node_or_null(target)


func _prompt_text() -> String:
	var t := _target()
	if t and t.has_method(prompt_method):
		return String(t.callv(prompt_method, []))
	return prompt


func _activate() -> void:
	var t := _target()
	if t and action_method != &"" and t.has_method(action_method):
		t.callv(action_method, action_args)
