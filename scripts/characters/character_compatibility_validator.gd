class_name CharacterCompatibilityValidator
extends RefCounted

const CharacterAuditTool := preload("res://scripts/characters/character_audit_tool.gd")

static func validate_definitions(definitions: Array[CharacterDefinition]) -> Dictionary:
	var errors: PackedStringArray = []
	var warnings: PackedStringArray = []
	var notes: PackedStringArray = []
	var audit: Dictionary = CharacterAuditTool.audit_all()
	errors.append_array(audit.compatibility.errors)
	warnings.append_array(audit.compatibility.warnings)
	notes.append_array(audit.compatibility.get("notes", PackedStringArray()))
	for definition: CharacterDefinition in definitions:
		if definition == null:
			errors.append("Null CharacterDefinition in validation set.")
			continue
		if definition.model_scene == null:
			errors.append("%s has no model_scene." % definition.id)
		if definition.animation_set == null:
			errors.append("%s has no animation_set." % definition.id)
		elif not definition.animation_set.get_missing_required_actions().is_empty():
			errors.append("%s missing required actions: %s" % [definition.id, ", ".join(definition.animation_set.get_missing_required_actions())])
		if definition.default_loadout == null:
			warnings.append("%s has no default_loadout." % definition.id)
	return {"errors": errors, "warnings": warnings, "notes": notes, "audit": audit}
