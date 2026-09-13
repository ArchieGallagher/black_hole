import glfw
import moderngl
import numpy as np

# This part is to help with making an FPS_calculator
import time

initial_time = time.perf_counter()
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

# Mapping the uv to xy coords: in this the formatting broke idk why?
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


# Render loop
while not glfw.window_should_close(window):
    glfw.poll_events()

    # This is part of the FPS_calculation
    current_time = time.perf_counter()
    time_elapsed = current_time - initial_time
    if time_elapsed >= 1.0:
        frames_per_second = frame / time_elapsed
    frame += 1.0
    glfw.set_window_title(window, f"Black Hole - {frames_per_second:.3f}")
    ctx.clear(0.0, 0.0, 0.0)

    # Update any per-frame uniforms here, e.g.:
    # program['time'].value = glfw.get_time()

    vao.render(moderngl.TRIANGLE_STRIP)

    glfw.swap_buffers(window)

glfw.terminate()
