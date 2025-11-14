/**
 * @file      nbody.cu
 *
 * @author    Jindrich Vodak \n
 *            Faculty of Information Technology \n
 *            Brno University of Technology \n
 *            xvodak06@stud.fit.vutbr.cz
 *
 * @brief     PCG - Assignment 1 / GPU Step 4
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
  /*  TODO: CUDA kernel to calculate new particles velocity and position, use shared memory to minimize memory access */
  /********************************************************************************************************************/
  // getting thread ID
  int globalThreadIdx = blockIdx.x * blockDim.x + threadIdx.x;

  // shared memory
  extern __shared__ float sharedMemory[];

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

    float *posXShared = sharedMemory;
    float *posYShared = &sharedMemory[blockDim.x * 1];
    float *posZShared = &sharedMemory[blockDim.x * 2];

    float *velXShared = &sharedMemory[blockDim.x * 3];
    float *velYShared = &sharedMemory[blockDim.x * 4];
    float *velZShared = &sharedMemory[blockDim.x * 5];

    float *weightShared = &sharedMemory[blockDim.x * 6];

    float newVelX = 0;
    float newVelY = 0;
    float newVelZ = 0;
    
    // looping by block width
    for (int i = 0; i < N; i += blockDim.x)
    {
      // tile index
      int tileIndex = i + threadIdx.x;

      if (tileIndex < N)
      {
        // transfering data to shared memory
        posXShared[threadIdx.x] = pIn.posX[tileIndex];
        posYShared[threadIdx.x] = pIn.posY[tileIndex];
        posZShared[threadIdx.x] = pIn.posZ[tileIndex];

        velXShared[threadIdx.x] = pIn.velX[tileIndex];
        velYShared[threadIdx.x] = pIn.velY[tileIndex];
        velZShared[threadIdx.x] = pIn.velZ[tileIndex];

        weightShared[threadIdx.x] = pIn.weight[tileIndex];
      }

      // necessary synchronization because of shared memory
      __syncthreads();

      for (int j = 0; j < blockDim.x; j++)
      {
        // calculating position differences
        float dx = posX - posXShared[j];
        float dy = posY - posYShared[j];
        float dz = posZ - posZShared[j];

        // calculating r as shown in the CPU version
        float r2 = dx * dx + dy * dy + dz * dz;
        float r  = sqrt(r2);

        // calculating f
        float f = -G * weight * weightShared[j] / (r2 + FLT_MIN);

        // precalculating redundant computations
        float dtw = dt / weight;

        // calculating gravitation velocity
        if (r > COLLISION_DISTANCE)
        {
          newVelX += (f * dx / (r + FLT_MIN)) * dtw;
          newVelY += (f * dy / (r + FLT_MIN)) * dtw;
          newVelZ += (f * dz / (r + FLT_MIN)) * dtw;
        }

        // precalculating redundant computations
        float weightsSum = weight + weightShared[j];
        float weightsDifference = weight - weightShared[j];

        if (r > 0.f && r < COLLISION_DISTANCE)
        {
          newVelX += ((velX * weightsDifference + weightShared[j] * 2 * velXShared[j]) / weightsSum) - velX;
          newVelY += ((velY * weightsDifference + weightShared[j] * 2 * velYShared[j]) / weightsSum) - velY;
          newVelZ += ((velZ * weightsDifference + weightShared[j] * 2 * velZShared[j]) / weightsSum) - velZ;
        }
      }

      // synchronization
      __syncthreads();
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

/**
 * CUDA kernel to calculate particles center of mass
 * @param p    - particles
 * @param com  - pointer to a center of mass
 * @param lock - pointer to a user-implemented lock
 * @param N    - Number of particles
 */
__global__ void centerOfMass(Particles p, float4* com, int* lock, const unsigned N)
{
  /********************************************************************************************************************/
  /*           TODO: CUDA kernel to calculate particles center of mass, see reference CPU implementation,             */
  /*                                 use CUDA predefined warpSize variable                                            */
  /********************************************************************************************************************/
  extern __shared__ float4 redSharedMemory[];

  float4 *comShared = redSharedMemory;

  comShared[threadIdx.x] = {0.0f, 0.0f, 0.0f, 0.0f};
  float4 comLocal = {0.0f, 0.0f, 0.0f, 0.0f};

  // synchronizing to ensure all threads have initialized shared memory
  __syncthreads();

  // getting thread ID
  int globalThreadIdx = blockIdx.x * blockDim.x + threadIdx.x;

  int gridStride = blockDim.x * gridDim.x;

  for (int i = globalThreadIdx; i < N; i += gridStride)
  {
    comLocal.x += p.posX[i] * p.weight[i];
    comLocal.y += p.posY[i] * p.weight[i];
    comLocal.z += p.posZ[i] * p.weight[i];
    comLocal.w += p.weight[i];
  }

  // writing accumulated result into shared memory
  comShared[threadIdx.x] = comLocal;

  // synchronizing so every thread has the same shared memory
  __syncthreads();

  // reduction
  for (int i = blockDim.x / 2; i > 0; i >>= 1)
  {
    if (threadIdx.x < i)
    {
      comShared[threadIdx.x].x += comShared[threadIdx.x + i].x;
      comShared[threadIdx.x].y += comShared[threadIdx.x + i].y;
      comShared[threadIdx.x].z += comShared[threadIdx.x + i].z;
      comShared[threadIdx.x].w += comShared[threadIdx.x + i].w;
    }
    __syncthreads();
  }

  // writing to center of mass (only thread 0 can write)
  if (threadIdx.x == 0)
  {
    while (atomicCAS(lock, 0, 1));
    com->x += comShared[0].x;
    com->y += comShared[0].y;
    com->z += comShared[0].z;
    com->w += comShared[0].w;
    atomicExch(lock, 0);
  }

  /********************************************************************************************************************/

}// end of centerOfMass
//----------------------------------------------------------------------------------------------------------------------

/**
 * CPU implementation of the Center of Mass calculation
 */
__host__ float4 centerOfMassRef(const MemDesc& memDesc)
{
  float4 com{};

  for (std::size_t i{}; i < memDesc.getDataSize(); i++)
  {
    const float3 pos = {memDesc.getPosX(i), memDesc.getPosY(i), memDesc.getPosZ(i)};
    const float  w   = memDesc.getWeight(i);

    // Calculate the vector on the line connecting current body and most recent position of center-of-mass
    // Calculate weight ratio only if at least one particle isn't massless
    const float4 d = {pos.x - com.x,
                      pos.y - com.y,
                      pos.z - com.z,
                      ((memDesc.getWeight(i) + com.w) > 0.0f)
                        ? ( memDesc.getWeight(i) / (memDesc.getWeight(i) + com.w))
                        : 0.0f};

    // Update position and weight of the center-of-mass according to the weight ration and vector
    com.x += d.x * d.w;
    com.y += d.y * d.w;
    com.z += d.z * d.w;
    com.w += w;
  }

  return com;
}// enf of centerOfMassRef
//----------------------------------------------------------------------------------------------------------------------
