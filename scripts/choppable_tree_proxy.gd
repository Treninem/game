extends StaticBody3D

# Keep undamaged forest trees in shared draw batches. Only a struck tree gets
# its own animated model; other trees keep their original draw calls.
const RESOURCE := preload("res://scripts/streamed_resource.gd")
var persistent_id := ""
var tree_scene: PackedScene
var tree_scale := 1.0
var batch_index := -1
var promoted := false

func interact(_player: Node) -> void:
    GameState.notify("Рубка: экипируйте топор (I), подойдите к стволу и бейте ЛКМ.")

func receive_melee_hit(player: Node3D) -> void:
    if promoted:
        return
    if InventorySystem.equipped_item(InventorySystem.SLOT_WEAPON) != "starter_axe":
        GameState.notify("Для рубки нужен топор. Он продаётся у торговцев.")
        return
    promoted = true
    var parent := get_parent()
    for child in parent.get_children():
        if child is MultiMeshInstance3D and String(child.get_meta("tree_source", "")) == tree_scene.resource_path:
            # Dummy/headless rendering does not retain MultiMesh transforms.
            # Construct the hidden transform without reading renderer state.
            var batch_transform := Transform3D(Basis.from_scale(Vector3.ONE * 0.00001), position)
            child.multimesh.set_instance_transform(batch_index, batch_transform)
            var hidden: Array = child.get_meta("chopped_indices", [])
            hidden.append(batch_index)
            child.set_meta("chopped_indices", hidden)
    var resource := RESOURCE.new()
    resource.configure(persistent_id, "wood", 6)
    resource.tree_scene = tree_scene
    resource.tree_scale = tree_scale
    resource.transform = transform
    parent.add_child(resource)
    collision_layer = 0
    resource.receive_melee_hit(player)
    queue_free()
