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
      // calculating position differences
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

    // saving tmpVel
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

    float newVelX{};
    float newVelY{};
    float newVelZ{};

    for (int i = 0; i < N; i++)
    {
      // preloading certain important values
      float velXi = p.velX[i];
      float velYi = p.velY[i];
      float velZi = p.velZ[i];

      float weighti = p.weight[i];

      // calculating position differences
      float dx = posX - p.posX[i];
      float dy = posY - p.posY[i];
      float dz = posZ - p.posZ[i];

      // calculating r as shown in the CPU version
      float r2 = dx * dx + dy * dy + dz * dz;
      float r  = std::sqrt(r2);

      float weightsSum = weight + weighti;
      float weightsDifference = weight - weighti;

      newVelX += r > COLLISION_DISTANCE ? ((velX * weightsDifference + weighti * 2 * velXi) / weightsSum) : 0.f;
      newVelY += r > COLLISION_DISTANCE ? ((velY * weightsDifference + weighti * 2 * velYi) / weightsSum) : 0.f;
      newVelZ += r > COLLISION_DISTANCE ? ((velZ * weightsDifference + weighti * 2 * velZi) / weightsSum) : 0.f;
    }

    // saving tmpVel
    tmpVel.x[globalThreadIdx] = newVelX;
    tmpVel.y[globalThreadIdx] = newVelY;
    tmpVel.z[globalThreadIdx] = newVelZ;
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
  int globalThreadIdx = blockIdx.x * blockDim.x + threadIdx.x;
  p.velX[globalThreadIdx] += tmpVel.x[globalThreadIdx];
  p.velY[globalThreadIdx] += tmpVel.y[globalThreadIdx];
  p.velZ[globalThreadIdx] += tmpVel.z[globalThreadIdx];

  p.posX[globalThreadIdx] += p.velX[globalThreadIdx] * dt;
  p.posY[globalThreadIdx] += p.velY[globalThreadIdx] * dt;
  p.posZ[globalThreadIdx] += p.velZ[globalThreadIdx] * dt;

  /********************************************************************************************************************/

}// end of update_particle
//----------------------------------------------------------------------------------------------------------------------
