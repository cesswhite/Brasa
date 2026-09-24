extends SceneTree
const Cosmetics = preload("res://scripts/cosmetic_catalog.gd")
func _init() -> void:
	var file := FileAccess.open("res://data/cosmetic_catalog.json", FileAccess.WRITE)
	if file == null: quit(1); return
	file.store_string(JSON.stringify(Cosmetics.export_catalog(), "\t", true, true) + "\n")
	file.close()
	print("Cosmetic catalog exported");quit()
