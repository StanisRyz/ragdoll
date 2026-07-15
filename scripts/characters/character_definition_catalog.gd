class_name CharacterDefinitionCatalog
extends Resource

@export var definitions: Array[CharacterDefinition] = []

func get_enabled_definitions() -> Array[CharacterDefinition]:
	var enabled_definitions: Array[CharacterDefinition] = []
	for definition: CharacterDefinition in definitions:
		if definition != null and definition.enabled:
			enabled_definitions.append(definition)
	return enabled_definitions

