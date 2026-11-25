"""Generate the small 3D props used by the Godot prototype.

Run from the repository root with:
  blender --background --python tools/generate_3d_assets.py

The supplied storyboard image is not used as a runtime texture. This script
creates actual meshes and PBR materials for the fruit, basket, jar, and cup.
The orange-segment mesh is built in Godot so it can be placed and animated per slice.
"""

import math
import os
import random

import bpy

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MODEL_DIR = os.path.join(ROOT, "assets", "models")
TEXTURE_DIR = os.path.join(ROOT, "assets", "textures")
os.makedirs(MODEL_DIR, exist_ok=True)
os.makedirs(TEXTURE_DIR, exist_ok=True)


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.images):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def rgba(hex_color, alpha=1.0):
    value = hex_color.lstrip("#")
    return tuple(int(value[i:i + 2], 16) / 255.0 for i in (0, 2, 4)) + (alpha,)


def make_material(name, color, roughness=0.45, metallic=0.0, alpha=1.0):
    material = bpy.data.materials.new(name)
    material.diffuse_color = color
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Roughness"].default_value = roughness
    principled.inputs["Metallic"].default_value = metallic
    if "Alpha" in principled.inputs:
        principled.inputs["Alpha"].default_value = alpha
    if alpha < 1.0:
        material.blend_method = "BLEND"
        material.show_transparent_back = True
        if "Transmission" in principled.inputs:
            principled.inputs["Transmission"].default_value = 0.28
    return material


def make_orange_texture(path):
    width, height = 768, 384
    image = bpy.data.images.new("OrangeSkinTexture", width=width, height=height, alpha=False)
    pixels = [0.0] * (width * height * 4)
    random.seed(46)
    for y in range(height):
        v = y / height
        for x in range(width):
            u = x / width
            noise = random.uniform(-0.035, 0.035)
            grain = 0.025 * math.sin(u * 58.0 + math.sin(v * 13.0)) + 0.018 * math.sin(v * 44.0 + u * 9.0)
            # Fine, deterministic high-frequency pores without a quadratic pixel loop.
            pore = -0.018 * abs(math.sin(u * 930.0 + math.sin(v * 270.0)))
            pore -= 0.014 * abs(math.sin(v * 810.0 + u * 190.0))
            value = noise + grain + pore
            index = (y * width + x) * 4
            pixels[index] = max(0.0, min(1.0, 0.96 + value))
            pixels[index + 1] = max(0.0, min(1.0, 0.31 + value * 0.55))
            pixels[index + 2] = max(0.0, min(1.0, 0.025 + value * 0.18))
            pixels[index + 3] = 1.0
    image.pixels.foreach_set(pixels)
    image.filepath_raw = path
    image.file_format = "PNG"
    image.save()
    return image


def make_orange_material(texture):
    material = make_material("Orange Peel | PBR", rgba("F47A12"), 0.38)
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    principled = nodes.get("Principled BSDF")
    image_node = nodes.new("ShaderNodeTexImage")
    image_node.name = "Orange Peel Texture"
    image_node.image = texture
    links.new(image_node.outputs["Color"], principled.inputs["Base Color"])
    subsurface = principled.inputs.get("Subsurface Weight") or principled.inputs.get("Subsurface")
    if subsurface is not None:
        subsurface.default_value = 0.035
    coat = principled.inputs.get("Coat Weight") or principled.inputs.get("Clearcoat")
    if coat is not None:
        coat.default_value = 0.12
    coat_roughness = principled.inputs.get("Coat Roughness") or principled.inputs.get("Clearcoat Roughness")
    if coat_roughness is not None:
        coat_roughness.default_value = 0.28
    return material


def make_leaf_mesh(name, center_z=0.57, angle=0.0, length=0.52, width=0.20):
    verts = []
    faces = []
    steps = 12
    for i in range(steps + 1):
        t = i / steps
        longitudinal = (t - 0.5) * length
        half_width = math.sin(math.pi * t) * width
        lift = center_z + 0.11 * math.sin(math.pi * t)
        for side in (-1.0, 0.0, 1.0):
            lateral = half_width * side
            x = longitudinal
            y = lateral
            xr = x * math.cos(angle) - y * math.sin(angle)
            yr = x * math.sin(angle) + y * math.cos(angle)
            verts.append((xr, yr, lift + (0.035 if side == 0.0 else 0.0)))
    for i in range(steps):
        a = i * 3
        b = a + 3
        faces.append((a, b, b + 1, a + 1))
        faces.append((a + 1, b + 1, b + 2, a + 2))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(make_material("Leaf green", rgba("368D2F"), 0.56))
    mesh.update()
    leaf = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(leaf)
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    solidify = leaf.modifiers.new("Leaf thickness", "SOLIDIFY")
    solidify.thickness = 0.018
    return leaf


def export_selected(path, objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
    )
    print("Generated:", path)


def make_orange(texture):
    orange_material = make_orange_material(texture)
    stem_material = make_material("Orange stem", rgba("68401B"), 0.72)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=64, ring_count=48, radius=0.62)
    fruit = bpy.context.object
    fruit.name = "OrangeFruit"
    for vertex in fruit.data.vertices:
        x, y, z = vertex.co
        pole = abs(z) / 0.62
        dimple = 0.035 * math.exp(-((x * x + y * y) / 0.020)) * min(1.0, pole * 1.7)
        vertex.co.z = z - math.copysign(dimple, z)
        vertex.co.z += 0.008 * math.sin(x * 18.0 + y * 9.0) * math.cos(y * 13.0)
    fruit.scale = (1.0, 1.0, 0.92)
    fruit.data.materials.append(orange_material)
    for polygon in fruit.data.polygons:
        polygon.use_smooth = True
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.055, depth=0.13, location=(0.0, 0.0, 0.57))
    stem = bpy.context.object
    stem.name = "Stem"
    stem.data.materials.append(stem_material)
    for polygon in stem.data.polygons:
        polygon.use_smooth = True
    leaf_a = make_leaf_mesh("LeafA", 0.58, 0.25, 0.52, 0.20)
    leaf_b = make_leaf_mesh("LeafB", 0.59, 2.35, 0.42, 0.17)
    bpy.ops.object.select_all(action="DESELECT")
    fruit.select_set(True)
    stem.select_set(True)
    leaf_a.select_set(True)
    leaf_b.select_set(True)
    bpy.context.view_layer.objects.active = fruit
    bpy.ops.object.join()
    fruit.name = "Orange"
    export_selected(os.path.join(MODEL_DIR, "orange.glb"), [fruit])


def lathe_mesh(name, profile, segments=64, material=None, caps=True):
    verts = []
    faces = []
    for z, radius in profile:
        for i in range(segments):
            angle = math.tau * i / segments
            verts.append((radius * math.cos(angle), radius * math.sin(angle), z))
    for ring in range(len(profile) - 1):
        for i in range(segments):
            a = ring * segments + i
            b = ring * segments + (i + 1) % segments
            c = (ring + 1) * segments + (i + 1) % segments
            d = (ring + 1) * segments + i
            faces.append((a, b, c, d))
    if caps:
        faces.append(tuple(range(segments - 1, -1, -1)))
        last = (len(profile) - 1) * segments
        faces.append(tuple(last + i for i in range(segments)))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    if material:
        mesh.materials.append(material)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    return obj


def make_curve(name, points, bevel_depth, material, cyclic=False):
    curve = bpy.data.curves.new(name + "Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 16
    curve.bevel_depth = bevel_depth
    curve.bevel_resolution = 4
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, co in zip(spline.points, points):
        point.co = (*co, 1.0)
    spline.use_cyclic_u = cyclic
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    return obj


def make_basket():
    reset_scene()
    wicker = make_material("Wicker honey", rgba("A9652E"), 0.64)
    wicker_light = make_material("Wicker highlight", rgba("C7833F"), 0.60)
    wicker_dark = make_material("Wicker shadow", rgba("70401F"), 0.72)
    objects = []
    objects.append(lathe_mesh("Basket bowl", [(0.0, 0.40), (0.06, 0.48), (0.18, 0.58), (0.38, 0.72), (0.55, 0.82)], material=wicker, caps=True))
    for idx, (z, radius) in enumerate([(0.10, 0.50), (0.22, 0.61), (0.34, 0.70), (0.46, 0.78), (0.55, 0.83)]):
        bpy.ops.mesh.primitive_torus_add(major_radius=radius, minor_radius=0.035, major_segments=64, minor_segments=10, location=(0.0, 0.0, z))
        ring = bpy.context.object
        ring.name = "Woven ring %02d" % idx
        ring.data.materials.append(wicker_light if idx % 2 == 0 else wicker_dark)
        for polygon in ring.data.polygons:
            polygon.use_smooth = True
        objects.append(ring)
    for idx in range(16):
        angle = math.tau * idx / 16
        points = []
        for step in range(9):
            t = step / 8
            z = 0.04 + t * 0.51
            radius = 0.43 + t * 0.38
            a = angle + 0.018 * math.sin(t * math.pi * 4 + idx)
            points.append((radius * math.cos(a), radius * math.sin(a), z))
        objects.append(make_curve("Basket stave %02d" % idx, points, 0.024, wicker_light if idx % 2 else wicker_dark))
    export_selected(os.path.join(MODEL_DIR, "basket.glb"), objects)


def make_jar():
    reset_scene()
    glass = make_material("Clear blue glass", rgba("D8F4FF", 0.26), 0.12, alpha=0.26)
    lip = make_material("Glass edge", rgba("B8E7F7", 0.48), 0.12, alpha=0.48)
    jar = lathe_mesh(
        "Glass jar",
        [(0.00, 0.52), (0.04, 0.64), (0.11, 0.70), (0.22, 0.74), (0.74, 0.76), (0.95, 0.72), (1.11, 0.61), (1.18, 0.49), (1.27, 0.49), (1.31, 0.58)],
        material=glass,
        caps=False,
    )
    objects = [jar]
    for name, z, radius, tube in [("Jar base", 0.07, 0.64, 0.045), ("Jar lip", 1.29, 0.56, 0.055)]:
        bpy.ops.mesh.primitive_torus_add(major_radius=radius, minor_radius=tube, major_segments=64, minor_segments=12, location=(0.0, 0.0, z))
        edge = bpy.context.object
        edge.name = name
        edge.data.materials.append(lip)
        for polygon in edge.data.polygons:
            polygon.use_smooth = True
        objects.append(edge)
    export_selected(os.path.join(MODEL_DIR, "glass_jar.glb"), objects)


def make_cup():
    reset_scene()
    glass = make_material("Cup glass", rgba("C7F0FF", 0.34), 0.1, alpha=0.34)
    rim_material = make_material("Cup rim", rgba("E2FAFF", 0.55), 0.1, alpha=0.55)
    cup = lathe_mesh("Glass cup", [(0.0, 0.35), (0.04, 0.44), (0.12, 0.48), (0.55, 0.59), (0.70, 0.61)], material=glass, caps=False)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.60, minor_radius=0.035, major_segments=56, minor_segments=10, location=(0.0, 0.0, 0.69))
    rim = bpy.context.object
    rim.name = "Cup rim"
    rim.data.materials.append(rim_material)
    export_selected(os.path.join(MODEL_DIR, "glass_cup.glb"), [cup, rim])


def main():
    reset_scene()
    texture_path = os.path.join(TEXTURE_DIR, "orange_skin.png")
    texture = make_orange_texture(texture_path)
    make_orange(texture)
    make_basket()
    make_jar()
    make_cup()
    print("3D prop generation complete")


if __name__ == "__main__":
    main()
