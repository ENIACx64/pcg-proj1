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
  // getting thread ID
  int globalThreadIdx = blockIdx.x * blockDim.x + threadIdx.x;

  // if in range, continue
  if (globalThreadIdx < N)
  {
    float posX = p.posX[globalThreadIdx];
    float posY = p.posY[globalThreadIdx];
    float posZ = p.posZ[globalThreadIdx];

    float newVelX{};
    float newVelY{};
    float newVelZ{};

    for (int i = 0; i < N; i++)
    {
      float dx = posX - p.posX[i];
      float dy = posY - p.posY[i];
      float dz = posZ - p.posZ[i];

      // calculating r as shown in the CPU version
      float r2 = dx * dx + dy * dy + dz * dz;
      float r  = std::sqrt(r2);

      // calculating f
      float f = -G * p.weight[globalThreadIdx] * p.weight[i] / (r2 + FLT_MIN);

      newVelX += r > COLLISION_DISTANCE ? (f * dx / (r + FLT_MIN)) * (dt / p.weight[globalThreadIdx]) : 0.f;
      newVelY += r > COLLISION_DISTANCE ? (f * dx / (r + FLT_MIN)) * (dt / p.weight[globalThreadIdx]) : 0.f;
      newVelZ += r > COLLISION_DISTANCE ? (f * dx / (r + FLT_MIN)) * (dt / p.weight[globalThreadIdx]) : 0.f;
    }

    tmpVel.x[globalThreadIdx] = newVelX;
    tmpVel.y[globalThreadIdx] = newVelY;
    tmpVel.z[globalThreadIdx] = newVelZ;
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
  // getting thread ID
  int globalThreadIdx = blockIdx.x * blockDim.x + threadIdx.x;

  // if in range, continue
  if (globalThreadIdx < N)
  {
    float posX = p.posX[globalThreadIdx];
    float posY = p.posY[globalThreadIdx];
    float posZ = p.posZ[globalThreadIdx];
    
    float velX = p.velX[globalThreadIdx];
    float velY = p.velY[globalThreadIdx];
    float velZ = p.velZ[globalThreadIdx];

    float weight = p.weight[globalThreadIdx];

    for (int i = 0; i < N; i++)
    {
      
    }
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
