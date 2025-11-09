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
  const float* const pPosX = p.posX;
  const float* const pPosY = p.posY;
  const float* const pPosZ = p.posZ;
  const float* const pWeight = p.weight;

  float* const tmpVelX = tmpVel.x;
  float* const tmpVelY = tmpVel.y;
  float* const tmpVelZ = tmpVel.z;

  #pragma omp parallel for firstprivate(pPosX, pPosY, pPosZ, pWeight, tmpVelX, tmpVelY, tmpVelZ, N, dt) default(none)
  for (unsigned i = 0u; i < N; ++i)
  {
    float newVelX{};
    float newVelY{};
    float newVelZ{};

    const float posX   = pPosX[i];
    const float posY   = pPosY[i];
    const float posZ   = pPosZ[i];
    const float mass = pWeight[i];

    #pragma omp simd aligned(pPosX, pPosY, pPosZ, pWeight, tmpVelX, tmpVelY, tmpVelZ: dataAlignment) \
                     reduction(+:newVelX, newVelY, newVelZ)
    for (unsigned j = 0u; j < N; ++j)
    {
      const float otherPosX   = pPosX[j];
      const float otherPosY   = pPosY[j];
      const float otherPosZ   = pPosZ[j];
      const float otherWeight = pWeight[j];

      const float dx = otherPosX - posX;
      const float dy = otherPosY - posY;
      const float dz = otherPosZ - posZ;

      const float r2 = dx * dx + dy * dy + dz * dz;
      const float r  = std::sqrt(r2);

      const float f = G * mass * otherWeight / r2;

      newVelX += r > COLLISION_DISTANCE ? dx / r * f : 0.f;
      newVelY += r > COLLISION_DISTANCE ? dy / r * f : 0.f;
      newVelZ += r > COLLISION_DISTANCE ? dz / r * f : 0.f;
    }

    newVelX *= dt / mass;
    newVelY *= dt / mass;
    newVelZ *= dt / mass;

    tmpVelX[i] = newVelX;
    tmpVelY[i] = newVelY;
    tmpVelZ[i] = newVelZ;
  }


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
  const float* const pPosX   = p.posX;
  const float* const pPosY   = p.posY;
  const float* const pPosZ   = p.posZ;
  const float* const pVelX   = p.velX;
  const float* const pVelY   = p.velY;
  const float* const pVelZ   = p.velZ;
  const float* const pWeight = p.weight;

  float* const tmpVelX = tmpVel.x;
  float* const tmpVelY = tmpVel.y;
  float* const tmpVelZ = tmpVel.z;

  #pragma omp parallel for \
    firstprivate(pPosX, pPosY, pPosZ, pVelX, pVelY, pVelZ, pWeight, tmpVelX, tmpVelY, tmpVelZ, N) \
    default(none)
  for (unsigned i = 0u; i < N; ++i)
  {
    float newVelX{};
    float newVelY{};
    float newVelZ{};

    const float posX   = pPosX[i];
    const float posY   = pPosY[i];
    const float posZ   = pPosZ[i];
    const float velX   = pVelX[i];
    const float velY   = pVelY[i];
    const float velZ   = pVelZ[i];
    const float weight = pWeight[i];

    #pragma omp simd \
      aligned(pPosX, pPosY, pPosZ, pVelX, pVelY, pVelZ, pWeight, tmpVelX, tmpVelY, tmpVelZ: dataAlignment) \
      reduction(+:newVelX, newVelY, newVelZ)
    for (unsigned j = 0u; j < N; ++j)
    {
      const float otherPosX   = pPosX[j];
      const float otherPosY   = pPosY[j];
      const float otherPosZ   = pPosZ[j];
      const float otherVelX   = pVelX[j];
      const float otherVelY   = pVelY[j];
      const float otherVelZ   = pVelZ[j];
      const float otherWeight = pWeight[j];

      const float dx = otherPosX - posX;
      const float dy = otherPosY - posY;
      const float dz = otherPosZ - posZ;

      const float r2 = dx * dx + dy * dy + dz * dz;
      const float r  = std::sqrt(r2);

      newVelX += r > 0.f && r < COLLISION_DISTANCE
                 ? (weight * velX - otherWeight * velX + 2.f * otherWeight * otherVelX) / (weight + otherWeight) - velX
                 : 0.f;
      newVelY += r > 0.f && r < COLLISION_DISTANCE
                 ? (weight * velY - otherWeight * velY + 2.f * otherWeight * otherVelY) / (weight + otherWeight) - velY
                 : 0.f;
      newVelZ += r > 0.f && r < COLLISION_DISTANCE
                 ? (weight * velZ - otherWeight * velZ + 2.f * otherWeight * otherVelZ) / (weight + otherWeight) - velZ
                 : 0.f;
    }

    tmpVelX[i] += newVelX;
    tmpVelY[i] += newVelY;
    tmpVelZ[i] += newVelZ;
  }


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
  float* const pPosX   = p.posX;
  float* const pPosY   = p.posY;
  float* const pPosZ   = p.posZ;
  float* const pVelX   = p.velX;
  float* const pVelY   = p.velY;
  float* const pVelZ   = p.velZ;

  const float* const tmpVelX = tmpVel.x;
  const float* const tmpVelY = tmpVel.y;
  const float* const tmpVelZ = tmpVel.z;

  #pragma omp parallel for simd \
         firstprivate(pPosX, pPosY, pPosZ, pVelX, pVelY, pVelZ, tmpVelX, tmpVelY, tmpVelZ, N, dt) \
         aligned(pPosX, pPosY, pPosZ, pVelX, pVelY, pVelZ, tmpVelX, tmpVelY, tmpVelZ: dataAlignment) \
         default(none)
  for (unsigned i = 0u; i < N; ++i)
  {
    float posX = pPosX[i];
    float posY = pPosY[i];
    float posZ = pPosZ[i];

    float velX = pVelX[i];
    float velY = pVelY[i];
    float velZ = pVelZ[i];

    const float newVelX = tmpVelX[i];
    const float newVelY = tmpVelY[i];
    const float newVelZ = tmpVelZ[i];

    velX += newVelX;
    velY += newVelY;
    velZ += newVelZ;

    posX += velX * dt;
    posY += velY * dt;
    posZ += velZ * dt;

    pPosX[i] = posX;
    pPosY[i] = posY;
    pPosZ[i] = posZ;

    pVelX[i] = velX;
    pVelY[i] = velY;
    pVelZ[i] = velZ;
  }

  /********************************************************************************************************************/

}// end of update_particle
//----------------------------------------------------------------------------------------------------------------------
