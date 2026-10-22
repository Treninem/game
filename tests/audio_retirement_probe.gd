extends RefCounted

# AudioServer stops/fades on its mix thread, then retires playback on the
# main thread. A just-created SceneTreeTimer can consume the current frame's
# older delta, so it cannot measure wall time since an audio stop request.
static func stream_reference(player: Node) -> WeakRef:
    return weakref(player.get("stream")) as WeakRef

static func playback_reference(player: Node) -> WeakRef:
    if not bool(player.call("has_stream_playback")):
        return null
    return weakref(player.call("get_stream_playback")) as WeakRef

static func released(references: Array[WeakRef]) -> bool:
    # Resource-valued temporaries stay inside this synchronous predicate.
    for reference: WeakRef in references:
        if reference != null and reference.get_ref() != null:
            return false
    return true

static func wait_retired(tree: SceneTree, references: Array[WeakRef], timeout_msec: int = 1000) -> bool:
    var start := Time.get_ticks_msec()
    # Ensure queue_free and exit-tree callbacks cross a full frame boundary.
    await tree.process_frame
    await tree.process_frame
    while not released(references):
        if Time.get_ticks_msec() - start >= timeout_msec:
            return false
        await tree.process_frame
    return Time.get_ticks_msec() - start <= timeout_msec
