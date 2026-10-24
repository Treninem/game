extends RefCounted

# Physical implementation geometry inside the existing canonical canal district.
# The lake/sluice and broader capital composition remain separate work.
const GEOGRAPHY:=preload("res://scripts/world_geography.gd")
const CENTER:=GEOGRAPHY.ASTERN_CAPITAL+Vector2(1180,-120)
const HALF_LENGTH:=300.0
const HALF_WIDTH:=18.0
const BANK_WIDTH:=30.0
const WATER_LEVEL:=0.0
const DEPTH:=1.2
const BRIDGE_Z:Array[float]=[-320,-160,0,160]
const BRIDGE_HALF_LENGTH:=48.0
const BRIDGE_HALF_WIDTH:=8.0
const BRIDGE_DECK_TOP:=2.2
const BRIDGE_APPROACH_TOP:=.025
const GEOMETRY_REVISION:=1

static func has_current_revision(value:Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and float(value)>=GEOMETRY_REVISION

static func distance_to_channel(pos:Vector2) -> float:
    var offset:=pos-CENTER
    return Vector2(offset.x,offset.y-clampf(offset.y,-HALF_LENGTH,HALF_LENGTH)).length()

static func wet_at(pos:Vector2) -> bool:
    return distance_to_channel(pos)<HALF_WIDTH

static func near_channel(pos:Vector2) -> bool:
    return distance_to_channel(pos)<BANK_WIDTH

static func carve_height(pos:Vector2,original:float) -> float:
    var distance:=distance_to_channel(pos)
    if distance>=BANK_WIDTH:return original
    if distance<=HALF_WIDTH:
        return lerpf(WATER_LEVEL-DEPTH,WATER_LEVEL,smoothstep(HALF_WIDTH*.65,HALF_WIDTH,distance))
    # The small positive bank meets the existing zero plateau. Keeping water
    # at zero avoids misclassifying a dry below-sea bank as ocean water.
    var t:=(distance-HALF_WIDTH)/(BANK_WIDTH-HALF_WIDTH)
    return lerpf(0.,original,smoothstep(0.,1.,t))+.03*sin(PI*t)

static func bridges() -> Array[Vector2]:
    var result:Array[Vector2]=[]
    for z:float in BRIDGE_Z:result.append(GEOGRAPHY.ASTERN_CAPITAL+Vector2(1180,z))
    return result

static func deck_height(local_x:float) -> float:
    var x:=absf(local_x)
    if x<=24:return BRIDGE_DECK_TOP
    if x>=48:return BRIDGE_APPROACH_TOP
    # Match the actual Blender deck's3m piecewise planar stations.
    var lo:=floorf((x-24)/3)*3+24
    var hi:=lo+3
    var a:=lerpf(BRIDGE_DECK_TOP,BRIDGE_APPROACH_TOP,smoothstep(24.,48.,lo))
    var b:=lerpf(BRIDGE_DECK_TOP,BRIDGE_APPROACH_TOP,smoothstep(24.,48.,hi))
    return lerpf(a,b,(x-lo)/3)

static func bridge_at(pos:Vector2) -> Vector2:
    for bridge:Vector2 in bridges():
        var offset:=pos-bridge
        if absf(offset.x)<=BRIDGE_HALF_LENGTH and absf(offset.y)<=BRIDGE_HALF_WIDTH:return bridge
    return Vector2.INF

static func affects_rect(rect:Rect2,margin:float=0.) -> bool:
    return rect.intersects(Rect2(CENTER-Vector2(BANK_WIDTH+margin,HALF_LENGTH+BANK_WIDTH+margin),Vector2(2*(BANK_WIDTH+margin),2*(HALF_LENGTH+BANK_WIDTH+margin))),true)

static func water_polygon() -> PackedVector2Array:
    var polygon:=PackedVector2Array()
    for index in range(64):
        var angle:=TAU*float(index)/64.
        var c:=cos(angle)
        polygon.append(CENTER+Vector2(sin(angle)*HALF_WIDTH,(HALF_LENGTH if c>=0 else -HALF_LENGTH)+c*HALF_WIDTH))
    return polygon

static func supported_height(pos:Vector2,actor_y:float,terrain_y:float) -> float:
    var bridge:=bridge_at(pos)
    if is_inf(bridge.x):return terrain_y
    var deck:=deck_height(pos.x-bridge.x)
    # Keep legitimate wading below the vaults; do not pull every water actor up.
    return deck if actor_y>=deck-.20 else terrain_y

static func legacy_bridge_position(pos:Vector3) -> Vector3:
    var point:=Vector2(pos.x,pos.z)
    var bridge:=bridge_at(point)
    # Old road saves can be made during a jump too. Leaving their feet inside
    # the new vault/deck makes support acquisition wait forever. Current-revision
    # underarch saves never call this migration; positions above the deck stay.
    if not is_inf(bridge.x) and pos.y>=-.12:
        pos.y=maxf(pos.y,deck_height(point.x-bridge.x)+.08)
    return pos

static func navigation_target(start:Vector2,goal:Vector2) -> Vector2:
    # A crossing is chosen from the current goal, not an authored patrol loop.
    # Far-away residents pay only this bounding-box test.
    if not affects_rect(Rect2(start,Vector2.ZERO).expand(goal),2):return goal
    var current_bridge:=bridge_at(start)
    if not is_inf(current_bridge.x) and absf(start.x-current_bridge.x)<BRIDGE_HALF_LENGTH-.8:
        return current_bridge+Vector2((BRIDGE_HALF_LENGTH+1.5)*signf(goal.x-current_bridge.x),0)
    var crossing:=false
    var count:=clampi(ceili(start.distance_to(goal)/6),2,256)
    for index in range(count+1):
        if wet_at(start.lerp(goal,float(index)/count)):
            crossing=true;break
    if not crossing:return goal
    var side:float=-1 if start.x<CENTER.x else 1
    var selected:=Vector2.INF
    var minimum:=INF
    for bridge:Vector2 in bridges():
        var approach:=bridge+Vector2(side*(BRIDGE_HALF_LENGTH+1.5),0)
        var exit:=bridge-Vector2(side*(BRIDGE_HALF_LENGTH+1.5),0)
        var cost:=start.distance_to(approach)+approach.distance_to(exit)+exit.distance_to(goal)
        if cost<minimum:minimum=cost;selected=bridge
    var entry:=selected+Vector2(side*(BRIDGE_HALF_LENGTH+1.5),0)
    if start.distance_to(entry)<1.0 or (absf(start.y-selected.y)<4 and absf(start.x-selected.x)<BRIDGE_HALF_LENGTH+2):
        return selected-Vector2(side*(BRIDGE_HALF_LENGTH+1.5),0)
    return entry
