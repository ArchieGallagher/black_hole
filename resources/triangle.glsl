#version (3, 3)

#if defined VERTEX_SHADER
in vec2 in_vert;
void main() {
    gl_Postion = vec4(in_vert, 0.0, 1.0);
}
#elif defined FRAGMENT_SHADER
out vec4 f_color;
void main() {
    f_color = vec4(1.0, 0.0, 0.0, 1.0);
}
#endif