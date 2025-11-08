/**
 * @file      nbody.cu
 *
 * @author    Jindrich Vodak \n
 *            Faculty of Information Technology \n
 *            Brno University of Technology \n
 *            xvodak06@stud.fit.vutbr.cz
 *
 * @brief     PCG - Assignment 1 / GPU Step 0
 *
 * @version   2025
 *
 * @date      02 October   2025, 09:00 (created) \n
 */

#include <cfloat>

#include <device_launch_parameters.h>

#include "nbody.cuh"

/* Constants */
constexpr float G                  = 6.67384e-11f;
constexpr float COLLISION_DISTANCE = 0.01f;

/**
 * CUDA kernel to calculate gravitation velocity
 * @param p      - particles
 * @param tmpVel - temp array for velocities
 * @param N      - Number of particles
 * @param dt     - Size of the time step
 */
__global__ void calculateGravitationVelocity(Particles p, const Velocities tmpVel, const unsigned N, const float dt)
{
  /********************************************************************************************************************/
  /*              TODO: CUDA kernel to calculate gravitation velocity, see reference CPU version                      */
  /********************************************************************************************************************/



  /********************************************************************************************************************/
  
}// end of calculate_gravitation_velocity
//----------------------------------------------------------------------------------------------------------------------

/**
 * CUDA kernel to calculate collision velocity
 * @param p      - particles
 * @param tmpVel - temp array for velocities
 * @param N      - Number of particles
 */
__global__ void calculateCollisionVelocity(Particles p, const Velocities tmpVel, const unsigned N)
{
  /********************************************************************************************************************/
  /*              TODO: CUDA kernel to calculate collision velocity, see reference CPU version                        */
  /********************************************************************************************************************/



  /********************************************************************************************************************/

}// end of calculate_collision_velocity
//----------------------------------------------------------------------------------------------------------------------

/**
 * CUDA kernel to update particles
 * @param p      - particles
 * @param tmpVel - temp array for velocities
 * @param N      - Number of particles
 * @param dt     - Size of the time step
 */
__global__ void updateParticles(Particles p, const Velocities tmpVel, const unsigned N, const float dt)
{
  /********************************************************************************************************************/
  /*             TODO: CUDA kernel to update particles velocities and positions, see reference CPU version            */
  /********************************************************************************************************************/



  /********************************************************************************************************************/

}// end of update_particle
//----------------------------------------------------------------------------------------------------------------------
