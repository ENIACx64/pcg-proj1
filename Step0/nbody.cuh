/**
 * @file      nbody.cuh
 *
 * @author    Name Surname \n
 *            Faculty of Information Technology \n
 *            Brno University of Technology \n
 *            xlogin00@fit.vutbr.cz
 *
* @brief     PCG - Assignment 1 / GPU Step 0
 *
 * @version   2025
 *
 * @date      02 October   2025, 09:00 (created) \n
 */

#ifndef NBODY_CUH
#define NBODY_CUH

#include "h5Helper.h"

/**
 * Particles data structure
 */
struct Particles
{
  /********************************************************************************************************************/
  /*                             TODO: Particle data structure optimized for use on GPU                               */
  /********************************************************************************************************************/



  /********************************************************************************************************************/
};

/**
 * Velocities data structure (to be used as buffer for partial results)
 */
struct Velocities
{
  /********************************************************************************************************************/
  /*                             TODO: Velocities data structure optimized for use on GPU                             */
  /********************************************************************************************************************/



  /********************************************************************************************************************/
};


/**
 * CUDA kernel to calculate gravitation velocity
 * @param p      - particles
 * @param tmpVel - temp array for velocities
 * @param N      - Number of particles
 * @param dt     - Size of the time step
 */
__global__ void calculateGravitationVelocity(Particles      p,
                                             Velocities     tmpVel,
                                             unsigned   N,
                                             float          dt);

/**
 * CUDA kernel to calculate collision velocity
 * @param p      - particles
 * @param tmpVel - temp array for velocities
 * @param N      - Number of particles
 */
__global__ void calculateCollisionVelocity(Particles      p,
                                           Velocities     tmpVel,
                                           unsigned   N);

/**
 * CUDA kernel to update particles
 * @param p      - particles
 * @param tmpVel - temp array for velocities
 * @param N      - Number of particles
 * @param dt     - Size of the time step
 */
__global__ void updateParticles(Particles      p,
                                Velocities     tmpVel,
                                unsigned   N,
                                float          dt);

#endif /* NBODY_CUH */
