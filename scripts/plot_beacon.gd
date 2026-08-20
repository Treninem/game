extends StaticBody3D

var plot_id := ""
var plot_type := "normal"

func configure(id: String, kind: String) -> void:
    plot_id = id
    plot_type = kind

func interaction_text() -> String:
    return "E — управление участком"

func interact(_actor: Node = null) -> void:
    var runtime := get_tree().get_first_node_in_group("plot_runtime")
    if runtime != null and runtime.has_method("build_owned_structure"):
        runtime.call("build_owned_structure", plot_id)
