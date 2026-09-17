class_name WaveData
extends Resource

@export var banner: String = ""
@export var duration: float = 30.0
@export var max_alive: int = 4
@export var pulse_interval: float = 3.0
@export_group("Enemy weights")
@export var bee: float = 1.0
@export var fish: float = 0.0
@export var snake: float = 0.0
@export_group("Grouping weights")
@export var drip: float = 1.0
@export var pair: float = 0.0
@export var wall: float = 0.0
@export var ring: float = 0.0
@export var ambush: float = 0.0
@export var escort: float = 0.0
@export_group("Set pieces")
@export var opener: String = ""
@export var boss: String = ""
@export var boss_at: float = 0.0
