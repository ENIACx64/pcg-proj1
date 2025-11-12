/**
 * @file      main.cu
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

#include <chrono>
#include <cmath>
#include <cstdio>
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

  Particles dParticles[2]{};

  /********************************************************************************************************************/
  /*                                     TODO: GPU side memory allocation                                             */
  /********************************************************************************************************************/
  cudaMalloc<float>(&(dParticles[0].posX), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles[0].posY), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles[0].posZ), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles[0].velX), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles[0].velY), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles[0].velZ), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles[0].weight), (size_t) (N * sizeof(float)));

  cudaMalloc<float>(&(dParticles[1].posX), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles[1].posY), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles[1].posZ), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles[1].velX), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles[1].velY), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles[1].velZ), (size_t) (N * sizeof(float)));
  cudaMalloc<float>(&(dParticles[1].weight), (size_t) (N * sizeof(float)));

  /********************************************************************************************************************/
  /*                                     TODO: Memory transfer CPU -> GPU                                             */
  /********************************************************************************************************************/
  cudaMemcpy(dParticles[0].posX, hParticles.posX, (N * sizeof(float)), cudaMemcpyHostToDevice);
  cudaMemcpy(dParticles[0].posY, hParticles.posY, (N * sizeof(float)), cudaMemcpyHostToDevice);
  cudaMemcpy(dParticles[0].posZ, hParticles.posZ, (N * sizeof(float)), cudaMemcpyHostToDevice);
  cudaMemcpy(dParticles[0].velX, hParticles.velX, (N * sizeof(float)), cudaMemcpyHostToDevice);
  cudaMemcpy(dParticles[0].velY, hParticles.velY, (N * sizeof(float)), cudaMemcpyHostToDevice);
  cudaMemcpy(dParticles[0].velZ, hParticles.velZ, (N * sizeof(float)), cudaMemcpyHostToDevice);
  cudaMemcpy(dParticles[0].weight, hParticles.weight, (N * sizeof(float)), cudaMemcpyHostToDevice);
  cudaMemcpy(dParticles[1].weight, hParticles.weight, (N * sizeof(float)), cudaMemcpyHostToDevice);

  /********************************************************************************************************************/

  // Start measurement
  const auto start = std::chrono::steady_clock::now();

  for (unsigned s = 0u; s < steps; ++s)
  {
    const unsigned srcIdx = s % 2;        // source particles index
    const unsigned dstIdx = (s + 1) % 2;  // destination particles index

    /******************************************************************************************************************/
    /*                                     TODO: GPU kernel invocation                                                */
    /******************************************************************************************************************/
    calculateVelocity<<<simGridDim, simBlockDim>>>(dParticles[srcIdx], dParticles[dstIdx], N, dt);

    /******************************************************************************************************************/
  }

  // Wait for all CUDA kernels to finish
  CUDA_CALL(cudaDeviceSynchronize());

  // End measurement
  const auto end = std::chrono::steady_clock::now();

  // Approximate simulation wall time
  const float elapsedTime = std::chrono::duration<float>(end - start).count();
  std::printf("Time: %f s\n", elapsedTime);

  const unsigned resIdx = steps % 2;    // result particles index

  /********************************************************************************************************************/
  /*                                     TODO: Memory transfer GPU -> CPU                                             */
  /********************************************************************************************************************/
  cudaMemcpy(hParticles.posX, dParticles[resIdx].posX, (N * sizeof(float)), cudaMemcpyDeviceToHost);
  cudaMemcpy(hParticles.posY, dParticles[resIdx].posY, (N * sizeof(float)), cudaMemcpyDeviceToHost);
  cudaMemcpy(hParticles.posZ, dParticles[resIdx].posZ, (N * sizeof(float)), cudaMemcpyDeviceToHost);
  cudaMemcpy(hParticles.velX, dParticles[resIdx].velX, (N * sizeof(float)), cudaMemcpyDeviceToHost);
  cudaMemcpy(hParticles.velY, dParticles[resIdx].velY, (N * sizeof(float)), cudaMemcpyDeviceToHost);
  cudaMemcpy(hParticles.velZ, dParticles[resIdx].velZ, (N * sizeof(float)), cudaMemcpyDeviceToHost);
  cudaMemcpy(hParticles.weight, dParticles[resIdx].weight, (N * sizeof(float)), cudaMemcpyDeviceToHost);

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
