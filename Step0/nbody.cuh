/**
 * @file      nbody.cuh
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
  // positions
  float *posX;
  float *posY;
  float *posZ;

  // velocities
  float *velX;
  float *velY;
  float *velZ;

  // masses
  float *mass;

  // strides
  std::size_t posXStride{1};
  std::size_t posYStride{1};
  std::size_t posZStride{1};
  std::size_t velXStride{1};
  std::size_t velYStride{1};
  std::size_t velZStride{1};
  std::size_t massStride{1};

  // offsets
  std::size_t posXOffset{0};
  std::size_t posYOffset{0};
  std::size_t posZOffset{0};
  std::size_t velXOffset{0};
  std::size_t velYOffset{0};
  std::size_t velZOffset{0};
  std::size_t massOffset{0};

  // particle count
  std::size_t N{0};

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
  // deltas
  float *deltaX;
  float *deltaY;
  float *deltaZ;

  // strides
  std::size_t deltaXStride{1};
  std::size_t deltaYStride{1};
  std::size_t deltaZStride{1};

  // offsets
  std::size_t deltaXOffset{0};
  std::size_t deltaYOffset{0};
  std::size_t deltaZOffset{0};

  // offsets

  // count
  std::size_z N{0};

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
