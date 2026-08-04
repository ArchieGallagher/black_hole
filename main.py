import moderngl
import moderngl_window as mglw

from array import array

class Viewer(mglw.WindowConfig):
    gl_version = (3, 3)
    window_size = (640, 480)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Do initialization here
        self.prog = self.ctx.program(   # Making a triangle.
            vertex_shader='''
                #version 330
                in vec2 in_vert;
                void main() { gl_Position = vec4(in_vert, 1.0, 1.0); } 
            ''',
            fragment_shader='''
                #version 330
                out vec4 f_color;
                void main() { f_color = vec4(0.9, 0.6, 1.0, 1.0); }
            ''',
        )
        vbo = self.ctx.buffer(array('f', [-0.6, -0.6, 0.6, -0.6, 0.0, 0.6]))
        self.vao = self.ctx.vertex_array(self.prog, [(vbo, '2f', 'in_vert')])
        self.texture = self.ctx.texture(self.wnd.size, 4)

    def on_render(self, time: float, frametime: float):
        # This method is called every frame
        self.vao.render()

# Blocking call entering rendering/event loop
Viewer.run()