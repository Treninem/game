extends RefCounted

# One retained canvas mesh preserves painter order and per-marker colors.
# Hundreds of independent draw_circle/polygon commands otherwise submit
# hundreds of GL draws on every frame, even between map redraws.
const CIRCLE_SEGMENTS := 24
var mesh := ArrayMesh.new()
var vertices := PackedVector2Array()
var colors := PackedColorArray()
var indices := PackedInt32Array()

func clear() -> void:
    vertices.clear()
    colors.clear()
    indices.clear()

func polygon(points: PackedVector2Array, color: Color) -> void:
    if points.size() < 3: return
    var offset := vertices.size()
    for point in points:
        vertices.append(point)
        colors.append(color)
    # Callers provide convex, clockwise screen polygons (including clipped
    # building rectangles); no triangulation work is repeated by the renderer.
    for i in range(1,points.size()-1):
        indices.append_array(PackedInt32Array([offset,offset+i,offset+i+1]))

func circle(center: Vector2, radius: float, color: Color, width: float = 0.0) -> void:
    var offset := vertices.size()
    if width <= 0.0:
        vertices.append(center)
        colors.append(color)
        for i in range(CIRCLE_SEGMENTS):
            vertices.append(center+Vector2.from_angle(TAU*float(i)/CIRCLE_SEGMENTS)*radius)
            colors.append(color)
        for i in range(CIRCLE_SEGMENTS):
            indices.append_array(PackedInt32Array([offset,offset+1+i,offset+1+(i+1)%CIRCLE_SEGMENTS]))
    else:
        var inner := maxf(0.0,radius-width*0.5)
        var outer := radius+width*0.5
        for i in range(CIRCLE_SEGMENTS):
            var direction := Vector2.from_angle(TAU*float(i)/CIRCLE_SEGMENTS)
            vertices.append(center+direction*inner)
            vertices.append(center+direction*outer)
            colors.append_array(PackedColorArray([color,color]))
        for i in range(CIRCLE_SEGMENTS):
            var a := offset+i*2
            var b := offset+((i+1)%CIRCLE_SEGMENTS)*2
            indices.append_array(PackedInt32Array([a,a+1,b,a+1,b+1,b]))

func outline(points: PackedVector2Array, color: Color, width: float) -> void:
    for i in range(points.size()):
        var a := points[i]
        var b := points[(i+1)%points.size()]
        if a.is_equal_approx(b): continue
        var side := (b-a).normalized().orthogonal()*width*0.5
        polygon(PackedVector2Array([a+side,b+side,b-side,a-side]),color)

func draw(control: Control) -> void:
    mesh.clear_surfaces()
    if vertices.is_empty(): return
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_COLOR] = colors
    arrays[Mesh.ARRAY_INDEX] = indices
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
    control.draw_mesh(mesh,null)
