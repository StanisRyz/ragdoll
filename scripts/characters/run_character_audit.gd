extends SceneTree

const CharacterAuditTool := preload("res://scripts/characters/character_audit_tool.gd")

func _initialize() -> void:
	var audit: Dictionary = CharacterAuditTool.audit_all()
	print(JSON.stringify(audit, "\t"))
	quit(0)

