/**
 * @file      h5Helper.h
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
 * @brief     PCG - Assignment 1 / HDF5 Helper
 *
 * @version   2025
 *
 * @date      04 October   2023, 09:00 (created) \n
 * @date      02 October   2025, 13:22 (revised) \n
 */

#ifndef H5_HELPER_H
#define H5_HELPER_H

#include <cstddef>
#include <iostream>
#include <string>
#include <vector>

#include <hdf5.h>
#include <vector_types.h>

/// Forward definition for the H5Helper
class H5Helper;

/**
 * @class MemDesc
 * Memory descriptor class
 */
class MemDesc
{
  public:
    /**
     * Constructor
     * parameters:
     *                     Stride of two              Offset of the first
     *      Data pointer   consecutive elements       element in floats
     *                     in floats (not bytes)      (not bytes)
     */
    MemDesc(float* pos_x,  std::size_t  pos_x_stride, std::size_t  pos_x_offset,
            float* pos_y,  std::size_t  pos_y_stride, std::size_t  pos_y_offset,
            float* pos_z,  std::size_t  pos_z_stride, std::size_t  pos_z_offset,
            float* vel_x,  std::size_t  vel_x_stride, std::size_t  vel_x_offset,
            float* vel_y,  std::size_t  vel_y_stride, std::size_t  vel_y_offset,
            float* vel_z,  std::size_t  vel_z_stride, std::size_t  vel_z_offset,
            float* weight, std::size_t weight_stride, std::size_t weight_offset,
            std::size_t N, std::size_t      steps);

    /// Default constructor is not allowed
    MemDesc() = delete;

    /// Getter for the i-th particle's position in X
    [[nodiscard]] float getPosX(const std::size_t i) const
    {
      return mDataPtr[kPosX][i * mStride[kPosX] + mOffset[kPosX]];
    }

    /// Getter for the i-th particle's position in Y
    [[nodiscard]] float getPosY(const std::size_t i) const
    {
      return mDataPtr[kPosY][i * mStride[kPosY] + mOffset[kPosY]];
    }

    /// Getter for the i-th particle's position in Z
    [[nodiscard]] float getPosZ(const std::size_t i) const
    {
      return mDataPtr[kPosZ][i * mStride[kPosZ] + mOffset[kPosZ]];
    }

    /// Getter for the i-th particle's weight
    [[nodiscard]] float getWeight(const std::size_t i) const
    {
      return mDataPtr[kWeight][i * mStride[kWeight] + mOffset[kWeight]];
    }

    /// Getter for the data size
    [[nodiscard]] std::size_t getDataSize() const { return mSize; }

  protected:
    /// Vector of data pointers
    std::vector<float*> mDataPtr;

    /// Stride of two consecutive elements in memory pointed to by data pointers (in floats, not bytes)
    std::vector<std::size_t> mStride;

    /// Offset of the first element in the memory pointed to by data pointers (in floats, not bytes)
    std::vector<std::size_t> mOffset;

    // Data size
    std::size_t mSize;

    std::size_t mRecordsNum;

  private:
    friend H5Helper;

    /// Enum for dataset names
    enum Atr : std::size_t
    {
      /// Position in X axis
      kPosX,
      /// Position in Y axis
      kPosY,
      /// Position in Z axis
      kPosZ,
      /// Velocity in X axis
      kVelX,
      /// Velocity in Y axis
      kVelY,
      /// Velocity in Z axis
      kVelZ,
      /// Weight in X axis
      kWeight,
      /// Number of datasets
      kAttrNum
    };
}; // end of MemDesc
//----------------------------------------------------------------------------------------------------------------------

/**
 * @class H5Helper
 *
 * HDF5 file format reader and writer
 *
 * @param inputFile
 * @param outputFile
 * @param md
 */
class H5Helper
{
  public:
    /**
     * Constructor requires file names and memory layout descriptor
     * @param inputFile
     * @param outputFile
     * @param md - memory descriptor
     */
    H5Helper(std::string inputFile,
             std::string outputFile,
             MemDesc     md);

    /// Default constructor is not allowed
    H5Helper() = delete;

    /// Destructor
    ~H5Helper();

    /// Initialize helper
    void init();

    /// Read input data to the memory according to the memory descriptor
    void readParticleData() const;

    /// Write simulation data to the output file according to the memory descriptor and record number
    void writeParticleData(std::size_t record) const;

    /// Write final simulation data to the output file according to the memory descriptor
    void writeParticleDataFinal() const;

    /// Write center-of-mass to the output file according record number
    void writeCom(const float4& com, std::size_t record) const;

    /// Write final center-of-mass to the output file
    void writeComFinal(const float4& com) const;

  private:
    /// Memory descriptor
    MemDesc mMd;

    /// File names
    std::string mInputFile;

    std::string mOutputFile;

    /// File handles
    hid_t mInputFileId;

    hid_t mOutputFileId;

    /// Input size
    std::size_t mInputSize{};

    /// Vector of dataset names
    static const std::vector<std::string> mDatasetNames;
}; // end of H5Helper
//----------------------------------------------------------------------------------------------------------------------

#endif /* H5_HELPER_H */
