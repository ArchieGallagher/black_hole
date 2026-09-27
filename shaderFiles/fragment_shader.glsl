#version 330 core

//The MAX_STEPS is subject to change dependant on whether or not the black hole looks proper.
#define MAX_STEPS 50


in vec2 uv;
out vec4 f_color;

uniform vec2 resolution;


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
  /*
  In here we are going to need to setup converting the uv coords into the pixels that they represent.
  Then work out the ray_position + ray_direction at the initial point seesntially on the image view window.
  Then plug that into the start_position + start_direction into the ray_march function.
  */

  //FOV slash direction the ray is travelling at each
  vec3 cam_pos = vec3(0.0, 0.0, -45.0); //z represents distacne from image + image from center of black hole.
  vec3 start_position;
  vec3 start_direction;
  vec2 pixel = uv * resolution
  vec2 centered_pixel = pixel - (resolution * 0.5);
  vec2 centered_uv = uv - 0.5;
  
  //Fixing the aspect-ratio
  vec2 screen = centered_pixel / resolution.y;
  screen.x *= resolution.x / resolution.y;
  
  float fov = radians(60.0);
  float scale = tan(fov * 0.5);

  vec3 start_direction = normalize(vec3(screen.x * scale, screen.y * scale, 1.0))
  
  vec3 image_pos = vec3(camera_pos.xy, camera_pos.z - 3.0);//3.0 represnts the distance behind the image.
  
  vec3 start_position = vec3(centered_uv.x, centered_uv.y, image_pos.z)
  ray_march(start_position, start_direction)

  vec4 f_color = vec4()
}

void ray_march(in vec3 start_position, in vec3 start_direction, out vec4 colour){
  vec3 ray_position = start_position;
  vec3 ray_direction = normalize(start_direction);
  vec4 colour = vec4(0.0, 1.0, 0.0, 1.0) //This is just so i don't get cought with any bugs from a ray not knowing what happened, essentially a visual error message. --> Bright Green
  /*
  The explaination for the h2 assignment below is;
  The dot product is being used to square the magnitude of the vector.
  The cross product is to produce a vector perpendicular to both inputs.
  */
  float h2 = dot(cross(ray_position, ray_direction), cross(ray_position, ray_direction));

  for (int i = 0; i < MAX_STEPS; i++){
    float r = length(ray_position);

    vec3 old_ray_position = ray_position;
    vec3 old_ray_direction = ray_direction;

    float dt = getStepSize(r);
    rk4(ray_position, ray_direction, dt, h2);

    if (r <= 1.0){ //1.0 is the black_hole radius slash event horizon
      vec4 colour = vec4(0.0,0.0,0.0,1.0);
      break;
    }
    else if (accretion_disk(old_ray_position, ray_position) == true){
      vec3 near_colour = vec3(1.0, 0.9,0.6);
      vec3 far_colour = vec3(0.6, 0.1,0.0);
      
      float temp_grad = (distance_from_centre - 2.0) / (13.0);
      temp_grad = clamp(temp_grad, 0.0, 1.0);
      vec3 accretion_disk_colour = mix(near_colour, far_colour, temp_grad);

      vec4 colour = vec4(accretion_disk_colour, 1.0);
      break;
    }
    else if (i == (MAX_STEPS - 1)){
      vec4 colour = vec4(0.24, 0.24, 0.24, 1.0)// A dark grey just so the black hole stands out more.
      break; //Not sure if i need this, as if its on the last step it should end after this anyways.
    }
  }
  return vec4(colour);
}

void acceleration_func(in vec3 ray_position, out vec3 ray_acceleration, float h2){ // The inputted variables should be in the format of an array.
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
  vec3 direction_k2 = acceleration_func(k2_position, h2);
  //k3
  vec3 k3_position = ray_position + position_k2 * (dt * 0.5);
  vec3 k3_direction = ray_direction + direction_k2 * (dt * 0.5);

  vec3 position_k3 = k3_direction;
  vec3 direction_k3 = acceleration_func(k3_position, h2);
  //k4
  vec3 k4_position = ray_position + position_k3 * dt;
  vec3 k4_direction = ray_direction + direction_k3 * dt;

  vec3 position_k4 = k4_direction;
  vec3 direction_k4 = acceleration_func(k4_position, h2);

  //Weighted Average
  ray_position += (dt / 6.0) * (position_k1 + 2.0 * position_k2 + 2.0 * position_k3 + position_k4);
  ray_direction += (dt / 6.0) * (direction_k1 + 2.0 * direction_k2 + 2.0 * direction_k3 + direction_k4);

  ray_direction = normalize(ray_direction);
}

void accretion_disk(in vec3 old_ray_position, in vec3 ray_position, out float distance_from_centre){ //currently it is infinitely thin, soon ill make it thicker.
  float distance_from_centre = 0.0
  if (sign(old_ray_position.y) != sign(ray_position.y)){ // i dont want to have to do an else statement because it might mess up error handling.
    float t = -(old_ray_position.y) / (ray_position.y - old_ray_position.y); //where "t" is the fraction of the distance between the 2 points that the crossing point is.
    vec3 crossing_point;
    crossingpoint.x = old_ray_position.x + (t * (ray_position.x - old_ray_position.x));
    crossingpoint.y = 0.0; // should just be zero
    crossingpoint.z = old_ray_position.z + (t * (ray_position.z - old_ray_position.z));

    distance_from_centre = length(crossingpoint.xz);
    if (distance_from_centre <= (15.0 * r_s) && distance_from_centre >= (3.0 * r_s))//15.0 is the edge of the outer disk and the 3.0 is because of the little area in between the event horizon and the accretion disk where only light can pass through.
     return true;
  }
}
