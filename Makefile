# Disable all the default make stuff
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

.PHONY: default
default:
	# Please provide a valid make target

## Generate types
.PHONY: generate
generate:
# Then the second modification is to remove the array version of the container files and volumes. Anything based on score-go will just handle the map type.
# For files and volumes, we keep the string shorthand (oneOf[0]) and the object form (oneOf[1]) but simplify the allOf to just the $ref.
	jq '. as $$a | ."$$defs".container.properties.files |= $$a."$$defs".container.properties.files.oneOf[1] | ."$$defs".container.properties.files.additionalProperties.oneOf[1] |= $$a."$$defs".container.properties.files.oneOf[1].additionalProperties.oneOf[1].allOf[1] | ."$$defs".container.properties.volumes |= $$a."$$defs".container.properties.volumes.oneOf[1] | ."$$defs".container.properties.volumes.additionalProperties.oneOf[1] |= $$a."$$defs".container.properties.volumes.oneOf[1].additionalProperties.oneOf[1].allOf[1] | del(."$$defs".containerFile.properties.target) | del(."$$defs".containerVolume.properties.target)' schema/files/score-v1b1.json > schema/files/score-v1b1.json.for-validation
# For code generation, strip the string shorthand from additionalProperties since Go types only handle the object form.
# The shorthand is expanded by ApplyCommonUpgradeTransforms before mapping to structs.
	jq '."$$defs".container.properties.files.additionalProperties |= .oneOf[1] | ."$$defs".container.properties.volumes.additionalProperties |= .oneOf[1]' schema/files/score-v1b1.json.for-validation > schema/files/score-v1b1.json.for-generation.tmp
# Unfortunately struct generators don't know how to handle mixed properties and additional properties so we have to strip these out before we generate the structs.
# We still validate with the original specification though.
	jq 'walk(if type == "object" and .type == "object" and .additionalProperties == true and (.properties | type) == "object" then (del(.required) | del(.properties)) else . end)' schema/files/score-v1b1.json.for-generation.tmp > schema/files/score-v1b1.json.for-generation
	rm -f schema/files/score-v1b1.json.for-generation.tmp
	go generate -v ./...