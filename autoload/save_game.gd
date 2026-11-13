extends Node
## Salvamento em user://. O jogo salva sozinho toda manhã (depois de dormir) e
## "Continuar" volta para esse ponto. Também guarda se a abertura já foi vista.

const VERSION := 1

## Caminhos trocáveis (os testes usam arquivos próprios para não mexer no save real).
var save_path := "user://save.json"
var settings_path := "user://settings.cfg"


func has_save() -> bool:
	return load_data().size() > 0


func delete() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


## Guarda o estado atual. Devolve false se não conseguiu escrever.
func save() -> bool:
	var data := {
		"version": VERSION,
		"day": TimeManager.day,
		"minutes": TimeManager.minutes,
		"economy": Economy.to_save(),
		"player": PlayerStats.to_save(),
		"inventory": Inventory.to_dict(),
		"garden": GardenState.to_save(),
	}
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_warning("Não foi possível salvar em %s" % save_path)
		return false
	f.store_string(JSON.stringify(data))
	return true


## O conteúdo do save, ou {} se não existe, está corrompido ou é de outra versão.
func load_data() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK:
		return {}
	var parsed: Variant = json.data
	if parsed is Dictionary and int(parsed.get("version", 0)) == VERSION and parsed.has("day"):
		return parsed
	return {}


## Aplica o save aos sistemas do jogo. Devolve false se não há save válido.
## Quem chamou carrega o mapa da casa depois.
func load_game() -> bool:
	var d := load_data()
	if d.is_empty():
		return false
	Inventory.restore(d.get("inventory", {}))
	GardenState.restore(d.get("garden", {}))
	PlayerStats.restore(d.get("player", {}))
	Economy.restore(d.get("economy", {}), int(d["day"]))
	TimeManager.restore(int(d["day"]), int(d.get("minutes", TimeManager.DAY_START)))
	return true


# --- configurações -------------------------------------------------------------

func intro_seen() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(settings_path) == OK and bool(cfg.get_value("game", "intro_seen", false))


func mark_intro_seen() -> void:
	var cfg := ConfigFile.new()
	cfg.load(settings_path)
	cfg.set_value("game", "intro_seen", true)
	cfg.save(settings_path)
