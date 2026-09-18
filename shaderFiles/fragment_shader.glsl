#version 330 core

//The MAX_STEPS is subject to change dependant on whether or not the black hole looks proper.
#define MAX_STEPS 50


//This is were the input + output should be! --> I believe the input hsould jsut be the uv coord and the output is jsut a colour asscoiated to where the ray lands/ doesnt.


/*

This is the description of where in my 3D space all of the objects reside.

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
}

void ray_march(vec3 start_position, vec3 start_direction){
  vec3 ray_position = start_position;
  vec3 ray_direction = normalize(start_direction);

  /*
  The explaination for the h2 assignment below is;
  The dot product is being used to square the magnitude of the vector.
  The cross product is to produce a vector perpendicular to both inputs.
  */
  float h2 = dot(cross(ray_position, ray_direction), cross(ray_position, ray_direction));

  for (int i = 0; i < MAX_STEPS; i++){
    float r = length(ray_position);

    /*
    This where i will put the checks to see if the ray either;
    Fell into the black hole,
    Hit the accretion disk,
    Missed it entirely.
    */

    float dt = getStepSize(r);
    rk4(position, direction, dt, h2);
  }
  return vec3(.0);
}

void acceleration_func(in vec3 ray_position, out vec3 ray_acceleration, float h2){ // The inputted variables should be in the format of an array.
  ray_acceleration.x = -1.5 * h2 * ray_position.x / pow(r, 5.);
  ray_acceleration.y = -1.5 * h2 * ray_position.y / pow(r, 5.);
  ray_acceleration.z = -1.5 * h2 * ray_position.z / pow(r, 5.);  // h2 is the angular momentum squared and is calculated at the very beginning of the ray.
}

void rk4(inout vec3 ray_position, inout vec3 ray_direction, float dt, float h2){ // This function is to increase the accuracy of the simulation.
  float r = length(ray_position);

  //k1
  vec3 position_k1 = ray_direction;
  vec3 direction_k1;
  acceleration_func(ray_position, direction_k1, h2);
  //k2
  vec3 k2_position = ray_position + position_k1 * (dt * .5);
  vec3 k2_direction = ray_direction + direction_k1 * (dt * .5);

  vec3 position_k2 = k2_direction;
  vec3 direction_k2 = acceleration_func(k2_position, h2);
  //k3
  vec3 k3_position = ray_position + position_k2 * (dt * .5);
  vec3 k3_direction = ray_direction + direction_k2 * (dt * .5);

  vec3 position_k3 = k3_direction;
  vec3 direction_k3 = acceleration_func(k3_position, h2);
  //k4
  vec3 k4_position = ray_position + position_k3 * dt;
  vec3 k4_direction = ray_direction + direction_k3 * dt;

  vec3 position_k4 = k4_direction;
  vec3 direction_k4 = acceleration_func(k4_position, h2);

  //Weighted Average
  ray_position += (dt / 6.) * (position_k1 + 2. * position_k2 + 2. * position_k3 + position_k4);
  ray_direction += (dt / 6.) * (direction_k1 + 2. * direction_k2 + 2. * direction_k3 + direction_k4);

  ray_direction = normalize(ray_direction);//Ughh, American Spelling can't believe they haven't worked in a British English into this language yet but okay.
}
