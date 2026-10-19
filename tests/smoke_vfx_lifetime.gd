extends Node3D

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    get_tree().current_scene = self
    var owner := Node3D.new()
    add_child(owner)
    # Actual composed effects schedule child timers. Destroying their owner
    # before those timers fire reproduced native callback conversion errors.
    var early := VFXLibrary.spawn("magic_fire", Vector3.ZERO, owner)
    var early_ref: WeakRef = weakref(early)
    owner.queue_free()
    var natural := VFXLibrary.spawn("magic_arcane", Vector3.ZERO, self)
    var natural_ref: WeakRef = weakref(natural)
    await get_tree().create_timer(VFXLibrary.FX_LIFETIME_MAX + 0.5).timeout
    if early_ref.get_ref() != null or natural_ref.get_ref() != null:
        push_error("Composed effects did not retire with owner deletion/natural expiry")
        get_tree().quit(1)
        return
    print("VFX_LIFETIME_OK owner_freed_early=safe child_timers=safe natural_expiry=bounded")
    get_tree().quit(0)
