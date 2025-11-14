/**
 * @file      main.cu
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

#include <chrono>
#include <cmath>
#include <cstdio>
#include <memory>
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
  float4*   hCenterOfMass{};

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

  hCenterOfMass = (float4 *) malloc(sizeof(float4));

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
  float4*   dCenterOfMass{};
  int*      dLock{};

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

  cudaMalloc<float4>(&dCenterOfMass, (size_t) sizeof(float4));
  cudaMalloc<int>(&dLock, (size_t) sizeof(int));

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
  /*                                     TODO: Clear GPU center of mass                                               */
  /********************************************************************************************************************/
  cudaMemset(dCenterOfMass, 0, sizeof(float4));
  cudaMemset(dLock, 0, sizeof(int));

  /********************************************************************************************************************/
  /*                           TODO: Declare and create necessary CUDA streams and events                             */
  /********************************************************************************************************************/
  // CUDA streams for individual tasks
  cudaStream_t calculateNewPos;
  cudaStream_t copyData;
  cudaStream_t calculateCenterOfMass;

  cudaStreamCreate(&calculateNewPos);
  cudaStreamCreate(&copyData);
  cudaStreamCreate(&calculateCenterOfMass);

  // CUDA events for stream synchronization
  cudaEvent_t newPosCalculated;
  cudaEvent_t centerOfMassCalculated;

  cudaEventCreateWithFlags(&newPosCalculated, cudaEventDisableTiming);
  cudaEventCreateWithFlags  (&centerOfMassCalculated, cudaEventDisableTiming);

  /********************************************************************************************************************/

  // Get CUDA device warp size
  int device;
  int warpSize;

  CUDA_CALL(cudaGetDevice(&device));
  CUDA_CALL(cudaDeviceGetAttribute(&warpSize, cudaDevAttrWarpSize, device));

  /********************************************************************************************************************/
  /*                                  TODO: Set dynamic shared memory computation                                     */
  /********************************************************************************************************************/

  const std::size_t sharedMemSize    = 7 * sizeof(float) * simBlockDim;
  const std::size_t redSharedMemSize = redBlockDim * sizeof(float4);   // you can use warpSize variable

  /********************************************************************************************************************/

  // Lambda for checking if we should write current step to the file
  auto shouldWrite = [writeFreq](const unsigned s) -> bool
  {
    return writeFreq > 0u && (s % writeFreq == 0u);
  };

  // Lamda for getting record number
  auto getRecordNum = [writeFreq](const unsigned s) -> unsigned
  {
    return s / writeFreq;
  };

  /********************************************************************************************************************/
  /*                   TODO: Prepare structures and host callback functions for asynchronous output.                  */
  /*                    Define helper structs to hold arguments for particle data and COM writing.                    */
  /*                     Implement host callback lambdas (or functions) that will be launched with                    */
  /*                    cudaLaunchHostFunc to write particle data and center of mass into the file.                   */
  /********************************************************************************************************************/
  // helper struct for holding arguments for particle data
  struct ParticleCallbackArgs
  {
      H5Helper* helper;
      unsigned recordNum;
  };

  // helper struct for holding arguments for COM data
  struct ComCallbackArgs
  {
      H5Helper* helper;
      float4* hCom;
      unsigned recordNum;
  };
  
  // callback function for writing particle data
  auto writeParticleData = [](void* userData) -> void
  {
    ParticleCallbackArgs* args = static_cast<ParticleCallbackArgs*>(userData);
    args->helper->writeParticleData(args->recordNum);
    delete args;
  };

  // callback function for writing COM data
  auto writeComData = [](void* userData) -> void
  {
    ComCallbackArgs* args = static_cast<ComCallbackArgs*>(userData);
    args->helper->writeCom(*args->hCom, args->recordNum);
    delete args;
  };

  /********************************************************************************************************************/

  // Start measurement
  const auto start = std::chrono::steady_clock::now();

  /********************************************************************************************************************/
  /*            TODO: Edit the loop to work asynchronously and overlap computation with data transfers.               */
  /*                  Use shouldWrite lambda to determine if data should be outputted to file.                        */
  /*                           if (shouldWrite(s, writeFreq)) { ... }                                                 */
  /*                        Use getRecordNum lambda to get the record number.                                         */
  /********************************************************************************************************************/
  for (unsigned s = 0u; s < steps; ++s)
  {
    const unsigned srcIdx = s % 2;        // source particles index
    const unsigned dstIdx = (s + 1) % 2;  // destination particles index
    const unsigned currentRecordNum = getRecordNum(s);
    const bool shouldOutput = shouldWrite(s);

    /******************************************************************************************************************/
    /*                TODO: GPU kernels invocation with correctly set dynamic memory size and stream                  */
    /******************************************************************************************************************/
    calculateVelocity<<<simGridDim, simBlockDim, sharedMemSize, calculateNewPos>>>(dParticles[srcIdx], dParticles[dstIdx], N, dt);

    if (shouldOutput)
    {
      // recording newPosCalculated event (safe to read)
      cudaEventRecord(newPosCalculated, calculateNewPos);

      // waiting for the new position calculation to be finished
      cudaStreamWaitEvent(calculateCenterOfMass, newPosCalculated, 0);

      // clearing COM data
      cudaMemsetAsync(dCenterOfMass, 0, sizeof(float4), calculateCenterOfMass);
      cudaMemsetAsync(dLock, 0, sizeof(int), calculateCenterOfMass);

      // calculating center of mass
      centerOfMass<<<redGridDim, redBlockDim, redSharedMemSize, calculateCenterOfMass>>>(dParticles[dstIdx], dCenterOfMass, dLock, N);

      // recording centerOfMassCalculated event
      cudaEventRecord(centerOfMassCalculated, calculateCenterOfMass);

      // waiting for the new position calculation to be finished
      cudaStreamWaitEvent(copyData, newPosCalculated, 0);

      // asynchronously copying new pos data from GPU
      cudaMemcpyAsync(hParticles.posX, dParticles[dstIdx].posX, (N * sizeof(float)), cudaMemcpyDeviceToHost, copyData);
      cudaMemcpyAsync(hParticles.posY, dParticles[dstIdx].posY, (N * sizeof(float)), cudaMemcpyDeviceToHost, copyData);
      cudaMemcpyAsync(hParticles.posZ, dParticles[dstIdx].posZ, (N * sizeof(float)), cudaMemcpyDeviceToHost, copyData);

      // waiting for the center of mass calculation to be finished
      cudaStreamWaitEvent(copyData, centerOfMassCalculated, 0);

      // asynchronously copying center of mass data from GPU
      cudaMemcpyAsync(hCenterOfMass, dCenterOfMass, sizeof(float4), cudaMemcpyDeviceToHost, copyData);

      // writing particle data
      ParticleCallbackArgs* pArgs = new ParticleCallbackArgs
      {
        &h5Helper,
        currentRecordNum
      };
      cudaLaunchHostFunc(copyData, writeParticleData, pArgs);

      // writing COM data
      ComCallbackArgs* cArgs = new ComCallbackArgs
      {
        &h5Helper,
        hCenterOfMass,
        currentRecordNum
      };
      cudaLaunchHostFunc(copyData, writeComData, cArgs);

    }

    /******************************************************************************************************************/
  }

  const unsigned resIdx = steps % 2;    // result particles index

  /********************************************************************************************************************/
  /*                          TODO: Invocation of center of mass kernel, do not forget to add                         */
  /*                              additional synchronization and set appropriate stream                               */
  /********************************************************************************************************************/
  cudaDeviceSynchronize();

  // clearing COM
  cudaMemsetAsync(dCenterOfMass, 0, sizeof(float4), calculateCenterOfMass); 
  cudaMemsetAsync(dLock, 0, sizeof(int), calculateCenterOfMass);
  
  // last COM kernel invocation
  centerOfMass<<<redGridDim, redBlockDim, redSharedMemSize, calculateCenterOfMass>>>(dParticles[resIdx], dCenterOfMass, dLock, N);

  /********************************************************************************************************************/

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
  cudaMemcpy(hParticles.posX, dParticles[resIdx].posX, (N * sizeof(float)), cudaMemcpyDeviceToHost);
  cudaMemcpy(hParticles.posY, dParticles[resIdx].posY, (N * sizeof(float)), cudaMemcpyDeviceToHost);
  cudaMemcpy(hParticles.posZ, dParticles[resIdx].posZ, (N * sizeof(float)), cudaMemcpyDeviceToHost);
  cudaMemcpy(hParticles.velX, dParticles[resIdx].velX, (N * sizeof(float)), cudaMemcpyDeviceToHost);
  cudaMemcpy(hParticles.velY, dParticles[resIdx].velY, (N * sizeof(float)), cudaMemcpyDeviceToHost);
  cudaMemcpy(hParticles.velZ, dParticles[resIdx].velZ, (N * sizeof(float)), cudaMemcpyDeviceToHost);
  cudaMemcpy(hParticles.weight, dParticles[resIdx].weight, (N * sizeof(float)), cudaMemcpyDeviceToHost);

  cudaMemcpy(hCenterOfMass, dCenterOfMass, sizeof(float4), cudaMemcpyDeviceToHost);

  /********************************************************************************************************************/

  // Compute reference center of mass on CPU
  const float4 refCenterOfMass = centerOfMassRef(md);

  std::printf("Reference center of mass: %f, %f, %f, %f\n",
              refCenterOfMass.x,
              refCenterOfMass.y,
              refCenterOfMass.z,
              refCenterOfMass.w);

  std::printf("Center of mass on GPU: %f, %f, %f, %f\n",
              hCenterOfMass->x,
              hCenterOfMass->y,
              hCenterOfMass->z,
              hCenterOfMass->w);

  // Writing final values to the file
  h5Helper.writeComFinal(*hCenterOfMass);
  h5Helper.writeParticleDataFinal();

  /********************************************************************************************************************/
  /*                                  TODO: CUDA streams and events destruction                                       */
  /********************************************************************************************************************/
  cudaStreamDestroy(calculateNewPos);
  cudaStreamDestroy(copyData);
  cudaStreamDestroy(calculateCenterOfMass);

  cudaEventDestroy(newPosCalculated);
  cudaEventDestroy(centerOfMassCalculated);

  /********************************************************************************************************************/
  /*                                     TODO: GPU side memory deallocation                                           */
  /********************************************************************************************************************/
  cudaFree(dParticles[0].posX);
  cudaFree(dParticles[0].posY);
  cudaFree(dParticles[0].posZ);

  cudaFree(dParticles[0].velX);
  cudaFree(dParticles[0].velY);
  cudaFree(dParticles[0].velZ);

  cudaFree(dParticles[0].weight);

  cudaFree(dParticles[1].posX);
  cudaFree(dParticles[1].posY);
  cudaFree(dParticles[1].posZ);

  cudaFree(dParticles[1].velX);
  cudaFree(dParticles[1].velY);
  cudaFree(dParticles[1].velZ);

  cudaFree(dParticles[1].weight);

  cudaFree(dCenterOfMass);
  cudaFree(dLock);

  /********************************************************************************************************************/
  /*                                     TODO: CPU side memory deallocation                                           */
  /********************************************************************************************************************/
  free(hParticles.posX);
  free(hParticles.posY);
  free(hParticles.posZ);

  free(hParticles.velX);
  free(hParticles.velY);
  free(hParticles.velZ);

  free(hParticles.weight);

  free(hCenterOfMass);

  /********************************************************************************************************************/
}// end of main
//----------------------------------------------------------------------------------------------------------------------
