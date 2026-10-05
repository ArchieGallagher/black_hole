#version 330 core

//The MAX_STEPS is subject to change dependant on whether or not the black hole looks proper.
#define MAX_STEPS 500

const float accretion_disk_max = 18.0;
const float accretion_disk_min = 3.0;

in vec2 uv;
out vec4 f_color;

uniform vec2 resolution;
uniform float cam_yaw;
uniform float cam_pitch;
uniform float cam_distance;


void ray_march(in vec3 start_position, in vec3 start_direction, out vec4 colour);
void rk4(inout vec3 ray_position, inout vec3 ray_direction, float dt, float h2);
bool accretion_disk(in vec3 old_ray_position, in vec3 ray_position, out float distance_from_centre, out vec3 average_position, out float height_bound);
float getStepSize(float r);
bool red_object(in vec3 ray_position, in vec3 old_ray_position);


/*
This is the description of where in my 3D space all of the objects resides.

Black Hole (0,0,0) - This is at the origin mostly just to simplify some calculations.
Image(meaning that this is not the camera but part of the generation of the perspective)
Camera(Origin of the rays of light, in order to generate a perspective view the camera will be "fairly" close behind the Image.)

The black hole classification I'm basing this off of an Intermediate-mass black hole. - Info from wikipedia
mass = 10^5
radius = 10^6 metres   ---> This equates to a radius of a singular unit(arbitrary)

All of the data on the accretion disk is just arbitrary and "made up" by me.
*/

void main(){
  vec3 cam_pos = cam_distance * vec3(cos(cam_pitch) * sin(cam_yaw), sin(cam_pitch), -cos(cam_pitch) * cos(cam_yaw));

  vec3 forward = normalize(-cam_pos);
  vec3 right   = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
  vec3 up      = cross(forward, right);

  vec2 screen = (uv - 0.5) * resolution / resolution.y;

  float fov = radians(60.0);
  float scale = tan(fov * 0.5);

  vec3 start_direction = normalize(forward + (screen.x * right + screen.y * up) * scale);
  vec3 start_position  = cam_pos;

  ray_march(start_position, start_direction, f_color);
}

void ray_march(in vec3 start_position, in vec3 start_direction, out vec4 colour){
  vec3 ray_position = start_position;
  vec3 ray_direction = normalize(start_direction);
  colour = vec4(0.0, 1.0, 0.0, 1.0); //This is just so i don't get cought with any bugs from a ray not knowing what happened, essentially a visual error message. --> Bright Green
  /*
  The explaination for the h2 assignment below is;
  The dot product is being used to square the magnitude of the vector.
  The cross product is to produce a vector perpendicular to both inputs.
  */
  float h2 = dot(cross(ray_position, ray_direction), cross(ray_position, ray_direction));
  float distance_from_centre;
  vec3 average_position;
  float height_bound;

  for (int i = 0; i < MAX_STEPS; i++){
    float r = length(ray_position);

    vec3 old_ray_position = ray_position;
    vec3 old_ray_direction = ray_direction;

    float dt = getStepSize(r);
    rk4(ray_position, ray_direction, dt, h2);

    if (r <= 1.0){ //1.0 is the black_hole radius slash event horizon
      colour = vec4(0.0,0.0,0.0,1.0);
      break;
    }
    else if (accretion_disk(old_ray_position, ray_position, distance_from_centre, average_position, height_bound) == true){
      vec3 near_colour = vec3(1.0, 0.9,0.6);
      vec3 far_colour = vec3(0.6, 0.1,0.0);
      
      float temp_grad = (distance_from_centre - accretion_disk_min) / (accretion_disk_max - accretion_disk_min);
      temp_grad = clamp(temp_grad, 0.0, 1.0);
      vec3 accretion_disk_colour = mix(near_colour, far_colour, temp_grad);

      colour = vec4(accretion_disk_colour, 1.0);
      break;
    }

    else if (red_object(ray_position, old_ray_position) == true){
      colour = vec4(1.0, 0.0, 0.0, 1.0);
      break;
    }

    else if (i == (MAX_STEPS - 1)){
      colour = vec4(0.0, 0.0, 0.0, 0.99);// A dark grey just so the black hole stands out more.
      break; //Not sure if i need this, as if its on the last step it should end after this anyways.
    }
  }
  return;
}

float getStepSize(float r){
  return clamp(r * 0.1, 0.01, 1.0);
}

void acceleration_func(in vec3 ray_position, out vec3 ray_acceleration, float h2){ // The inputted variables should be in the format of an array.
  float r = length(ray_position);
  ray_acceleration.x = -1.5 * h2 * ray_position.x / pow(r, 5.0);
  ray_acceleration.y = -1.5 * h2 * ray_position.y / pow(r, 5.0);
  ray_acceleration.z = -1.5 * h2 * ray_position.z / pow(r, 5.0);  // h2 is the angular momentum squared, calculated at the very beginning of the ray.
}

void rk4(inout vec3 ray_position, inout vec3 ray_direction, float dt, float h2){ // This function is to increase the accuracy of the simulation.
  float r = length(ray_position);

  //k1
  vec3 position_k1 = ray_direction;
  vec3 direction_k1;
  acceleration_func(ray_position, direction_k1, h2);
  //k2
  vec3 k2_position = ray_position + position_k1 * (dt * 0.5);
  vec3 k2_direction = ray_direction + direction_k1 * (dt * 0.5);

  vec3 position_k2 = k2_direction;
  vec3 direction_k2;
  acceleration_func(k2_position, direction_k2, h2);
  //k3
  vec3 k3_position = ray_position + position_k2 * (dt * 0.5);
  vec3 k3_direction = ray_direction + direction_k2 * (dt * 0.5);

  vec3 position_k3 = k3_direction;
  vec3 direction_k3;
  acceleration_func(k3_position, direction_k3, h2);
  //k4
  vec3 k4_position = ray_position + position_k3 * dt;
  vec3 k4_direction = ray_direction + direction_k3 * dt;

  vec3 position_k4 = k4_direction;
  vec3 direction_k4;
  acceleration_func(k4_position, direction_k4, h2);

  //Weighted Average
  ray_position += (dt / 6.0) * (position_k1 + 2.0 * position_k2 + 2.0 * position_k3 + position_k4);
  ray_direction += (dt / 6.0) * (direction_k1 + 2.0 * direction_k2 + 2.0 * direction_k3 + direction_k4);

  ray_direction = normalize(ray_direction);
}

bool accretion_disk(in vec3 old_ray_position, in vec3 ray_position, out float distance_from_centre, out vec3 average_position, out float height_bound){
  distance_from_centre = 0.0;
  height_bound = 0.0;
  average_position = (old_ray_position + ray_position) / 2.0;


  if (sign(ray_position.y) != sign(old_ray_position.y)){
    float m = -old_ray_position.y / (ray_position.y - old_ray_position.y);
    vec3 crossing = mix(old_ray_position, ray_position, m);
    distance_from_centre = length(crossing.xz);
    if (distance_from_centre <= accretion_disk_max && distance_from_centre >= accretion_disk_min){
      return true;
    }
  }

  distance_from_centre = length(average_position.xz);
  height_bound = 0.15 * pow((0.5 * (1.0 + cos((clamp((distance_from_centre - accretion_disk_min) / (accretion_disk_max - accretion_disk_min), 0.0, 1.0)) * 3.14159))), 2.0);

  if (average_position.y >= (height_bound * (-1.0)) && average_position.y <= height_bound){
      if (distance_from_centre <= accretion_disk_max && distance_from_centre >= accretion_disk_min){
        return true;
    }
  }
  return false;
}

bool red_object(in vec3 ray_position, in vec3 old_ray_position){
  vec3 sphere_location = vec3(0.0, 0.0, 35.0);
  float sphere_radius = 5.0;
  vec3 average_ray_position = (ray_position + old_ray_position) / 2.0;
  float distance_to_sphere = length(average_ray_position - sphere_location);

  if (distance_to_sphere <= sphere_radius){
    return true;
  }
  return false;
}
