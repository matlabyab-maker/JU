extends Node3D

const PlaneScript = preload("res://scripts/plane_controller.gd")
var plane: CharacterBody3D
var camera: Camera3D
var hud_label: Label
var controls := {}
var speed_value := 34.0

func _ready() -> void:
    _make_environment()
    _make_terrain()
    _make_plane()
    _make_camera()
    _make_hud()

func _process(delta: float) -> void:
    if not is_instance_valid(plane):
        return
    var pscript = plane.get_script()
    if pscript:
        speed_value = plane.speed
    camera.global_position = camera.global_position.lerp(plane.global_position + plane.global_basis * Vector3(0, 5.5, 17), 1.8 * delta)
    camera.look_at(plane.global_position + plane.global_basis * Vector3(0, 0, -8), Vector3.UP)
    hud_label.text = "JUNKERS JU 52  |  سرعت: %d km/h  |  ارتفاع: %d m\nW/S یا ↑/↓: اوج‌گیری/نزول    A/D یا ←/→: گردش    Shift/Ctrl: سرعت" % [int(speed_value * 3.6), int(plane.global_position.y)]

func _make_environment() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.16, 0.34, 0.56)
    sky_mat.sky_horizon_color = Color(0.72, 0.82, 0.91)
    sky_mat.ground_bottom_color = Color(0.16, 0.20, 0.22)
    sky_mat.ground_horizon_color = Color(0.63, 0.72, 0.79)
    env.sky.sky_material = sky_mat
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.68, 0.76, 0.88)
    env.ambient_light_energy = 0.8
    env_node.environment = env
    add_child(env_node)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -25, 0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)

func _make_terrain() -> void:
    # Compact procedural terrain: no external textures or large assets.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var extent := 700.0
    var cells := 100
    for z in range(cells):
        for x in range(cells):
            var x0 := -extent + (2.0 * extent * x / cells)
            var x1 := -extent + (2.0 * extent * (x + 1) / cells)
            var z0 := -extent + (2.0 * extent * z / cells)
            var z1 := -extent + (2.0 * extent * (z + 1) / cells)
            var a := Vector3(x0, _height(x0, z0), z0)
            var b := Vector3(x1, _height(x1, z0), z0)
            var c := Vector3(x0, _height(x0, z1), z1)
            var d := Vector3(x1, _height(x1, z1), z1)
            _add_terrain_tri(st, a, c, b)
            _add_terrain_tri(st, b, c, d)
    st.generate_normals()
    var mesh := st.commit()
    var terrain := MeshInstance3D.new()
    terrain.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.roughness = 1.0
    terrain.material_override = mat
    add_child(terrain)
    var body := StaticBody3D.new()
    var col := CollisionShape3D.new()
    var shape := ConcavePolygonShape3D.new()
    shape.set_faces(mesh.get_faces())
    col.shape = shape
    body.add_child(col)
    add_child(body)

func _height(x: float, z: float) -> float:
    var ridge1 := abs(sin(x * 0.006 + sin(z * 0.004) * 1.8))
    var ridge2 := abs(sin(z * 0.008 + x * 0.002))
    var peaks := pow(ridge1, 5.0) * 100.0 + pow(ridge2, 7.0) * 95.0
    var base_h := 7.0 * sin(x * 0.018) * cos(z * 0.016)
    return max(-2.0, peaks + base_h - 5.0)

func _add_terrain_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    for v in [a, b, c]:
        var shade := clamp((v.y + 3.0) / 100.0, 0.0, 1.0)
        var col := Color(0.78, 0.84, 0.88).lerp(Color(0.96, 0.98, 1.0), shade)
        if v.y > 70.0:
            col = Color(0.94, 0.97, 1.0)
        st.set_color(col)
        st.add_vertex(v)

func _make_plane() -> void:
    plane = CharacterBody3D.new()
    plane.name = "Junkers_Ju52_Player"
    plane.position = Vector3(0, 85, 0)
    plane.set_script(PlaneScript)
    add_child(plane)
    _part_box(plane, Vector3(0, 0, 0), Vector3(1.9, 1.7, 8.5), Color(0.43, 0.42, 0.34))
    # Ju 52-like corrugated-metal transport silhouette, simplified for this lightweight prototype.
    _part_cylinder(plane, Vector3(0, 0.15, -0.4), Vector3(0.95, 0.95, 0.95), 4.3, Color(0.54, 0.54, 0.47), Vector3(90, 0, 0))
    _part_box(plane, Vector3(0, 0.0, 0.2), Vector3(18.5, 0.28, 2.5), Color(0.48, 0.49, 0.43))
    _part_box(plane, Vector3(0, 0.35, 4.2), Vector3(6.2, 0.22, 1.4), Color(0.48, 0.49, 0.43))
    _part_box(plane, Vector3(0, 1.0, 4.6), Vector3(0.3, 1.8, 1.0), Color(0.48, 0.49, 0.43))
    # Three engines and propeller disks
    for x in [-5.7, 0.0, 5.7]:
        var zpos := -0.1 if x != 0.0 else -2.2
        _part_cylinder(plane, Vector3(x, -0.05, zpos), Vector3(0.62, 0.62, 0.62), 1.8, Color(0.25, 0.26, 0.25), Vector3(90, 0, 0))
        _part_box(plane, Vector3(x, 0, zpos - 1.05), Vector3(0.12, 2.1, 0.12), Color(0.12, 0.13, 0.13))
    # Small cockpit glazing
    _part_box(plane, Vector3(0, 0.65, -3.65), Vector3(1.45, 0.55, 0.7), Color(0.12, 0.23, 0.29))

func _part_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
    var n := MeshInstance3D.new()
    var m := BoxMesh.new()
    m.size = size
    n.mesh = m
    n.position = pos
    n.material_override = _material(color)
    parent.add_child(n)

func _part_cylinder(parent: Node3D, pos: Vector3, scale_v: Vector3, height: float, color: Color, rot_deg: Vector3) -> void:
    var n := MeshInstance3D.new()
    var m := CylinderMesh.new()
    m.top_radius = 0.5
    m.bottom_radius = 0.5
    m.height = height
    n.mesh = m
    n.position = pos
    n.scale = scale_v
    n.rotation_degrees = rot_deg
    n.material_override = _material(color)
    parent.add_child(n)

func _material(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.82
    return m

func _make_camera() -> void:
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 72
    camera.position = Vector3(0, 92, 20)
    add_child(camera)
    camera.look_at(plane.global_position, Vector3.UP)

func _make_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    hud_label = Label.new()
    hud_label.position = Vector2(18, 14)
    hud_label.add_theme_font_size_override("font_size", 20)
    hud_label.add_theme_color_override("font_color", Color(1, 1, 1))
    hud_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
    hud_label.add_theme_constant_override("shadow_offset_x", 2)
    hud_label.add_theme_constant_override("shadow_offset_y", 2)
    layer.add_child(hud_label)
    var hint := Label.new()
    hint.text = "کنترل لمسی: دکمه‌ها را نگه دارید"
    hint.position = Vector2(18, 66)
    hint.add_theme_font_size_override("font_size", 16)
    hint.add_theme_color_override("font_color", Color(1, 1, 1))
    layer.add_child(hint)
    _add_hold_button(layer, "چپ", Vector2(24, -95), "left")
    _add_hold_button(layer, "راست", Vector2(118, -95), "right")
    _add_hold_button(layer, "اوج", Vector2(-210, -145), "up")
    _add_hold_button(layer, "نزول", Vector2(-210, -75), "down")
    _add_hold_button(layer, "گاز +", Vector2(-110, -145), "faster")
    _add_hold_button(layer, "گاز -", Vector2(-110, -75), "slower")

func _add_hold_button(layer: CanvasLayer, caption: String, offset: Vector2, action: String) -> void:
    var b := Button.new()
    b.text = caption
    b.custom_minimum_size = Vector2(82, 54)
    b.anchor_left = 0.0 if offset.x >= 0 else 1.0
    b.anchor_right = 0.0 if offset.x >= 0 else 1.0
    b.anchor_top = 1.0
    b.anchor_bottom = 1.0
    b.position = offset
    b.add_theme_font_size_override("font_size", 18)
    layer.add_child(b)
    b.button_down.connect(func(): plane.set_control(action, true))
    b.button_up.connect(func(): plane.set_control(action, false))
