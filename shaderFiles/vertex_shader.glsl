#version 330

in vec2 in_position;
in vec2 in_uv;

out vec2 uv;

void main(){
  uv = in_uv;
  gl_Position = vec4(in_position, 0.0, 1.0);
}

/*
For the gl_Position it is inherently 4d as:
The 0.0 is the Z component.
And the 1.0 is the w and its just a place holder as it is 
dividing everythin so when 1.0 nothing happens to the values.
*/
