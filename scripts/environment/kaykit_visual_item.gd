class_name KayKitVisualItem
extends Node3D

@export var category: StringName = &"structure"
@export var minimum_quality: StringName = &"low"
@export var allow_shadows: bool = true

func _ready() -> void:
	add_to_group("environment_quality_item")

func apply_quality_profile(profile: EnvironmentQualityProfile) -> void:
	if profile == null:
		visible = true
		_set_shadows_enabled(true)
		return
	var visible_for_profile: bool = profile.show_kaykit_visuals and _meets_quality(profile.profile_id)
	if category == &"background":
		visible_for_profile = visible_for_profile and profile.show_background_decoration
	elif category == &"small_prop":
		visible_for_profile = visible_for_profile and profile.show_small_props
	elif category == &"foliage":
		visible_for_profile = visible_for_profile and profile.show_foliage
	visible = visible_for_profile
	_set_shadows_enabled(profile.enable_shadows and allow_shadows)

func _meets_quality(profile_id: StringName) -> bool:
	if minimum_quality == &"low":
		return true
	return profile_id != &"low"

func _set_shadows_enabled(enabled: bool) -> void:
	var shadow_mode: int = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_apply_shadow_mode(self, shadow_mode)

func _apply_shadow_mode(node: Node, shadow_mode: int) -> void:
	if node is GeometryInstance3D:
		node.cast_shadow = shadow_mode
	for child: Node in node.get_children():
		_apply_shadow_mode(child, shadow_mode)

