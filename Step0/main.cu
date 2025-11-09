/**
 * @file      main.cu
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

#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <iterator>
#include <string>

#include "h5Helper.h"
#include "nbody.cuh"

/**
 * @brief CUDA error checking macro
 * @param call CUDA API call
 */
#define CUDA_CALL(call) \
  do { \
    const cudaError_t _error = (call); \
    if (_error != cudaSuccess) \
    { \
      std::fprintf(stderr, "CUDA error (%s:%d): %s\n", __FILE__, __LINE__, cudaGetErrorString(_error)); \
      std::exit(EXIT_FAILURE); \
    } \
  } while(0)

/**
 * Main routine
 */
int main(const int argc, char **argv)
{
  if (argc != 10)
  {
    std::printf("Usage: nbody <N> <dt> <steps> <threads/block> <write intensity> <reduction threads> <reduction threads/block> <input> <output>\n");
    std::exit(1);
  }

  // Number of particles
  const unsigned N                   = static_cast<unsigned>(std::stoul(argv[1]));
  // Length of time step
  const float    dt                  = std::stof(argv[2]);
  // Number of steps
  const unsigned steps               = static_cast<unsigned>(std::stoul(argv[3]));
  // Number of thread blocks
  const unsigned simBlockDim         = static_cast<unsigned>(std::stoul(argv[4]));
  // Write frequency
  const unsigned writeFreq           = static_cast<unsigned>(std::stoul(argv[5]));
  // number of reduction threads
  const unsigned redTotalThreadCount = static_cast<unsigned>(std::stoul(argv[6]));
  // Number of reduction threads/blocks
  const unsigned redBlockDim         = static_cast<unsigned>(std::stoul(argv[7]));

  // Size of the simulation CUDA grid - number of blocks
  const unsigned simGridDim = (N + simBlockDim - 1) / simBlockDim;
  // Size of the reduction CUDA grid - number of blocks
  const unsigned redGridDim = (redTotalThreadCount + redBlockDim - 1) / redBlockDim;

  // Log benchmark setup
  std::printf("       NBODY GPU simulation\n"
              "N:                       %u\n"
              "dt:                      %f\n"
              "steps:                   %u\n"
              "threads/block:           %u\n"
              "blocks/grid:             %u\n"
              "reduction threads/block: %u\n"
              "reduction blocks/grid:   %u\n",
              N, dt, steps, simBlockDim, simGridDim, redBlockDim, redGridDim);

  const std::size_t recordsCount = (writeFreq > 0) ? (steps + writeFreq - 1) / writeFreq : 0;

  Particles hParticles{};

  /********************************************************************************************************************/
  /*                              TODO: CPU side memory allocation (pinned)                                           */
  /********************************************************************************************************************/
  hParticles.posX = (float *) malloc(N * sizeof(float));
  hParticles.posY = (float *) malloc(N * sizeof(float));
  hParticles.posZ = (float *) malloc(N * sizeof(float));

  hParticles.velX = (float *) malloc(N * sizeof(float));
  hParticles.velY = (float *) malloc(N * sizeof(float));
  hParticles.velZ = (float *) malloc(N * sizeof(float));

  hParticles.weight = (float *) malloc(N * sizeof(float));

  /********************************************************************************************************************/
  /*                              TODO: Fill memory descriptor layout                                                 */
  /********************************************************************************************************************/
  /*
   * Caution! Create only after CPU side allocation
   * parameters:
   *                        Stride of two          Offset of the first
   *         Data pointer   consecutive elements   element in FLOATS
   *                        in FLOATS (not bytes)  (not bytes)
   */
  MemDesc md(hParticles.posX,       1,                     0,
             hParticles.posY,       1,                     0,
             hParticles.posZ,       1,                     0,
             hParticles.velX,       1,                     0,
             hParticles.velY,       1,                     0,
             hParticles.velZ,       1,                     0,
             hParticles.weight,     1,                     0,
             N,
             recordsCount);
  /********************************************************************************************************************/

  // Initialisation of helper class and loading of input data
  H5Helper h5Helper(argv[8], argv[9], md);

  try
  {
    h5Helper.init();
    h5Helper.readParticleData();
  }
  catch (const std::exception& e)
  {
    std::fprintf(stderr, "Error: %s\n", e.what());
    return EXIT_FAILURE;
  }

  Particles dParticles{};
  Velocities dTmpVelocities{};

  /********************************************************************************************************************/
  /*                                     TODO: GPU side memory allocation                                             */
  /********************************************************************************************************************/
  cudaMalloc<float>(&(dParticles.posX), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles.posY), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles.posZ), (size_t) (N * sizeof(float)));

  cudaMalloc<float>(&(dParticles.velX), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles.velY), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles.velZ), (size_t) (N * sizeof(float)));

  cudaMalloc<float>(&(dParticles.weight), (size_t) (N * sizeof(float)));
  
  /********************************************************************************************************************/
  /*                                     TODO: Memory transfer CPU -> GPU                                             */
  /********************************************************************************************************************/
  cudaMemCpy(dParticles.posX, hParticles.posX, N * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemCpy(dParticles.posY, hParticles.posY, N * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemCpy(dParticles.posZ, hParticles.posZ, N * sizeof(float), cudaMemcpyHostToDevice);

  cudaMemCpy(dParticles.velX, hParticles.velX, N * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemCpy(dParticles.velY, hParticles.velY, N * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemCpy(dParticles.velZ, hParticles.velZ, N * sizeof(float), cudaMemcpyHostToDevice);

  cudaMemCpy(dParticles.weight, hParticles.weight, N * sizeof(float), cudaMemcpyHostToDevice);

  /********************************************************************************************************************/

  // Start measurement
  const auto start = std::chrono::steady_clock::now();

  for (unsigned s = 0u; s < steps; ++s)
  {
    /******************************************************************************************************************/
    /*                                     TODO: GPU kernels invocation                                               */
    /******************************************************************************************************************/
    calculateGravitationVelocity<<<simGridDim, simBlockDim>>>(dParticles, dTmpVelocities, N, dt);
    calculateCollisionVelocity<<<simGridDim, simBlockDim>>>(dParticles, dTmpVelocities, N);
    updateParticles<<<simGridDim, simBlockDim>>>(dParticles, dTmpVelocities, N, dt);

    /******************************************************************************************************************/
  }

  // Wait for all CUDA kernels to finish
  CUDA_CALL(cudaDeviceSynchronize());

  // End measurement
  const auto end = std::chrono::steady_clock::now();

  // Approximate simulation wall time
  const float elapsedTime = std::chrono::duration<float>(end - start).count();
  std::printf("Time: %f s\n", elapsedTime);

  /********************************************************************************************************************/
  /*                                     TODO: Memory transfer GPU -> CPU                                             */
  /********************************************************************************************************************/
  cudaMemCpy(hParticles.posX, dParticles.posX, N * sizeof(float), cudaMemCpyDeviceToHost);
  cudaMemCpy(hParticles.posY, dParticles.posY, N * sizeof(float), cudaMemCpyDeviceToHost);
  cudaMemCpy(hParticles.posZ, dParticles.posZ, N * sizeof(float), cudaMemCpyDeviceToHost);

  cudaMemCpy(hParticles.velX, dParticles.velX, N * sizeof(float), cudaMemCpyDeviceToHost);
  cudaMemCpy(hParticles.velY, dParticles.velY, N * sizeof(float), cudaMemCpyDeviceToHost);
  cudaMemCpy(hParticles.velZ, dParticles.velZ, N * sizeof(float), cudaMemCpyDeviceToHost);

  cudaMemCpy(hParticles.weight, dParticles.weight, N * sizeof(float), cudaMemCpyDeviceToHost);

  /********************************************************************************************************************/

  // Writing final values to the file
  h5Helper.writeParticleDataFinal();

  /********************************************************************************************************************/
  /*                                     TODO: GPU side memory deallocation                                           */
  /********************************************************************************************************************/

  

  /********************************************************************************************************************/
  /*                                     TODO: CPU side memory deallocation                                           */
  /********************************************************************************************************************/



  /********************************************************************************************************************/
}// end of main
//----------------------------------------------------------------------------------------------------------------------
