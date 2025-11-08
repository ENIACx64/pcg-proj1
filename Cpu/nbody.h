/**
 * @file      nbody.h
 *
 * @author    Oliver Kunik \n
 *            Faculty of Information Technology \n
 *            Brno University of Technology \n
 *            ikunik@fit.vutbr.cz
 *
 * @author    Jiri Jaros \n
 *            Faculty of Information Technology \n
 *            Brno University of Technology \n
 *            jarosjir@fit.vutbr.cz
 *
 * @brief     PCG - Assignment 1 / CPU
 *
 * @version   2025
 *
 * @date      04 October   2023, 09:00 (created) \n
 * @date      02 October   2025, 14:43 (revised) \n
 */

#ifndef NBODY_H
#define NBODY_H

#include <vector_types.h>

#include "h5Helper.h"

constexpr std::size_t dataAlignment{64};

/**
 * Particles data structure
 */
struct Particles
{
  float* posX;
  float* posY;
  float* posZ;
  
  float* velX;
  float* velY;
  float* velZ;

  float* weight;
};

/**
 * Velocities data structure (to be used as buffer for partial results)
 */
struct Velocities
{
  float* x;
  float* y;
  float* z;
};

/**
 * Kernel to calculate gravitation velocity
 * @param p      - particles
 * @param tmpVel - temp array for velocities
 * @param N      - Number of particles
 * @param dt     - Size of the time step
 */
void calculateGravitationVelocity(const Particles& p,
                                  const Velocities& tmpVel,
                                  unsigned   N,
                                  float      dt);

/**
 * Kernel to calculate collision velocity
 * @param p      - particles
 * @param tmpVel - temp array for velocities
 * @param N      - Number of particles
 */
void calculateCollisionVelocity(const Particles& p,
                                const Velocities& tmpVel,
                                unsigned   N);

/**
 * Kernel to update particles
 * @param p      - particles
 * @param tmpVel - temp array for velocities
 * @param N      - Number of particles
 * @param dt     - Size of the time step
 */
void updateParticle(const Particles& p,
                    const Velocities& tmpVel,
                    unsigned   N,
                    float      dt);

/**
 * Kernel to calculate particles center of mass
 * @param p    - particles
 * @param N    - Number of particles
 */
float4 centerOfMass(const Particles& p, unsigned N);

/**
 * CPU implementation of the Center of Mass calculation
 * @param memDesc - Memory descriptor of particle data on CPU side
 */
float4 centerOfMassRef(const MemDesc& memDesc);

#endif /* NBODY_H */
