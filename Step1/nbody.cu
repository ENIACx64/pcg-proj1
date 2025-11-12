/**
 * @file      nbody.cu
 *
 * @author    Jindrich Vodak \n
 *            Faculty of Information Technology \n
 *            Brno University of Technology \n
 *            xvodak06@stud.fit.vutbr.cz
 *
 * @brief     PCG - Assignment 1 / GPU Step 1
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
 * CUDA kernel to calculate new particles velocity and position
 * @param pIn  - particles in
 * @param pOut - particles out
 * @param N    - Number of particles
 * @param dt   - Size of the time step
 */
__global__ void calculateVelocity(Particles pIn, Particles pOut, const unsigned N, const float dt)
{
  /********************************************************************************************************************/
  /*          TODO: CUDA kernel to calculate new particles velocity and position, collapse previous kernels           */
  /********************************************************************************************************************/
  // getting thread ID
  int globalThreadIdx = blockIdx.x * blockDim.x + threadIdx.x;

  // if in range, continue
  if (globalThreadIdx < N)
  {
    float posX = pIn.posX[globalThreadIdx];
    float posY = pIn.posY[globalThreadIdx];
    float posZ = pIn.posZ[globalThreadIdx];

    float velX = pIn.velX[globalThreadIdx];
    float velY = pIn.velY[globalThreadIdx];
    float velZ = pIn.velZ[globalThreadIdx];

    float weight = pIn.weight[globalThreadIdx];

    float newVelX = 0;
    float newVelY = 0;
    float newVelZ = 0;

    for (int i = 0; i < N; i++)
    {
      // calculating position differences
      float dx = posX - pIn.posX[i];
      float dy = posY - pIn.posY[i];
      float dz = posZ - pIn.posZ[i];

      // calculating r as shown in the CPU version
      float r2 = dx * dx + dy * dy + dz * dz;
      float r  = sqrt(r2);

      // calculating f
      float f = -G * weight * pIn.weight[i] / (r2 + FLT_MIN);

      // precalculating redundant computations
      float dtw = dt / weight;

      // calculating gravitation velocity
      if (r > COLLISION_DISTANCE)
      {
        newVelX += (f * dx / (r + FLT_MIN)) * dtw;
        newVelY += (f * dy / (r + FLT_MIN)) * dtw;
        newVelZ += (f * dz / (r + FLT_MIN)) * dtw;
      }

      // preloading certain important values
      float iVelX = pIn.velX[i];
      float iVelY = pIn.velY[i];
      float iVelZ = pIn.velZ[i];

      float iWeight = pIn.weight[i];

      // precalculating redundant computations
      float weightsSum = weight + iWeight;
      float weightsDifference = weight - iWeight;

      if (r > 0.f && r < COLLISION_DISTANCE)
      {
        newVelX += ((velX * weightsDifference + iWeight * 2 * iVelX) / weightsSum) - velX;
        newVelY += ((velY * weightsDifference + iWeight * 2 * iVelY) / weightsSum) - velY;
        newVelZ += ((velZ * weightsDifference + iWeight * 2 * iVelZ) / weightsSum) - velZ;
      }
    
    }

    pOut.posX[globalThreadIdx] = posX + ((velX + newVelX) * dt);
    pOut.posY[globalThreadIdx] = posY + ((velY + newVelY) * dt);
    pOut.posZ[globalThreadIdx] = posZ + ((velZ + newVelZ) * dt);

    pOut.velX[globalThreadIdx] = velX + newVelX;
    pOut.velY[globalThreadIdx] = velY + newVelY;
    pOut.velZ[globalThreadIdx] = velZ + newVelZ;
  }

  /********************************************************************************************************************/
  
}// end of calculate_gravitation_velocity
//----------------------------------------------------------------------------------------------------------------------
