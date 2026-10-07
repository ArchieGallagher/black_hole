import glfw
import moderngl
import numpy as np

# Moving the camera in the scene
import math

yaw = 0.0
pitch = math.radians(10.0)
distance = 70.0
dragging = False
last_x = last_y = 0.0
sensitivity = 0.005


def mouse_button_cb(window, button, action, mods):
    global dragging, last_x, last_y
    if button == glfw.MOUSE_BUTTON_LEFT:
        dragging = action == glfw.PRESS
        last_x, last_y = glfw.get_cursor_pos(window)


def cursor_pos_cb(window, x, y):
    global yaw, pitch, last_x, last_y
    if dragging:
        yaw -= (x - last_x) * sensitivity
        pitch += (y - last_y) * sensitivity
        limit = math.radians(89.0)
        pitch = max(-limit, min(limit, pitch))  # avoid flipping at the poles
    last_x, last_y = x, y


def scroll_cb(window, xoff, yoff):
    global distance
    distance = max(10.0, min(200.0, distance - yoff * 3.0))


# This part is to help with making an FPS_calculator
import time

current_time = time.perf_counter()
frame = 0.0
frames_per_second = 0.0

# Window
if not glfw.init():
    raise RuntimeError("Failed to initialize .glfw")

glfw.window_hint(glfw.CONTEXT_VERSION_MAJOR, 3)
glfw.window_hint(glfw.CONTEXT_VERSION_MINOR, 3)
glfw.window_hint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

width, height = 640, 480
window = glfw.create_window(width, height, "Black Hole Sim", None, None)
if not window:
    glfw.terminate()
    raise RuntimeError("Failed to create window")

glfw.make_context_current(window)

# Attaches to the context glfw just created
ctx = moderngl.create_context()


# LoadShaders from the file
def load_shader(path):
    with open(path, "r") as f:
        return f.read()


vertex_shader = load_shader("shaderFiles/vertex_shader.glsl")
fragment_shader = load_shader("shaderFiles/fragment_shader.glsl")

program = ctx.program(vertex_shader=vertex_shader, fragment_shader=fragment_shader)

# Mapping the uv to xy coords: in this the formatting broke idk why tho but it doesn't really matter?
quad_data = np.array(
    [
        # x,    y,    u,   v
        -1.0,
        -1.0,
        0.0,
        0.0,
        1.0,
        -1.0,
        1.0,
        0.0,
        -1.0,
        1.0,
        0.0,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
    ],
    dtype="f4",
)

vbo = ctx.buffer(quad_data.tobytes())
vao = ctx.vertex_array(program, [(vbo, "2f 2f", "in_position", "in_uv")])

glfw.set_mouse_button_callback(window, mouse_button_cb)
glfw.set_cursor_pos_callback(window, cursor_pos_cb)
glfw.set_scroll_callback(window, scroll_cb)

# Render loop
while not glfw.window_should_close(window):
    glfw.poll_events()

    # This is part of the FPS_calculation
    previous_time = current_time
    current_time = time.perf_counter()
    frame_time = current_time - previous_time
    frames_per_second = float(1.0 / frame_time)

    glfw.set_window_title(window, f"Black Hole - {frames_per_second:.3f}")
    ctx.clear(0.0, 0.0, 0.0)

    # Update any per-frame uniforms here, e.g.:
    # program['time'].value = glfw.get_time()
    program["resolution"].value = (width, height)
    program["cam_yaw"].value = yaw
    program["cam_pitch"].value = pitch
    program["cam_distance"].value = distance

    vao.render(moderngl.TRIANGLE_STRIP)

    glfw.swap_buffers(window)

glfw.terminate()
