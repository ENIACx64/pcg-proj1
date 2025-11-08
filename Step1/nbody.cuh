/**
 * @file      nbody.cuh
 *
 * @author    Name Surname \n
 *            Faculty of Information Technology \n
 *            Brno University of Technology \n
 *            xlogin00@fit.vutbr.cz
 *
 * @brief     PCG - Assignment 1 / GPU Step 1
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
 * CUDA kernel to calculate new particles velocity and position
 * @param pIn  - particles in
 * @param pOut - particles out
 * @param N    - Number of particles
 * @param dt   - Size of the time step
 */
__global__ void calculateVelocity(Particles      pIn,
                                  Particles      pOut,
                                  unsigned  N,
                                  float          dt);

#endif /* NBODY_CUH */
