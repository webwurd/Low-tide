class_name DayData extends Resource
## Static description of one day on Gannet Rock.

@export var day := 1
@export var title := ""
@export var weather := ""
@export var barometer := ""            # Arthur's reading, shown as an inner-voice note
@export var fog_density := 0.011
@export var fog_tint := Color("526373")
@export var light_scale := 1.0         # overall daylight strength (storms are dark)
@export var cloud := 0.5               # sky cover: 0 clear .. 1 overcast
@export var rain := false
@export var wave_height := 0.14
@export var wind_db := 0.0             # extra wind loudness
@export var lamp_after := 900.0        # earliest minute the lamp may be lit (15:00)
@export var morning_conv := ""
@export var evening_conv := ""
