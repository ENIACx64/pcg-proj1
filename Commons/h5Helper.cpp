/**
 * @file      h5Helper.cpp
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
 * @date      02 October   2025, 13:45 (revised) \n
 */

#include <utility>
#include <vector>

#include "h5Helper.h"

/// Dataset names
const std::vector<std::string> H5Helper::mDatasetNames =
{
  "pos_x",
  "pos_y",
  "pos_z",
  "vel_x",
  "vel_y",
  "vel_z",
  "weight",
}; // end of mDatasetNames initialization
//----------------------------------------------------------------------------------------------------------------------

/**
 * Constructor.
 */
MemDesc::MemDesc(float*            pos_x, const std::size_t  pos_x_stride, const std::size_t  pos_x_offset,
                 float*            pos_y, const std::size_t  pos_y_stride, const std::size_t  pos_y_offset,
                 float*            pos_z, const std::size_t  pos_z_stride, const std::size_t  pos_z_offset,
                 float*            vel_x, const std::size_t  vel_x_stride, const std::size_t  vel_x_offset,
                 float*            vel_y, const std::size_t  vel_y_stride, const std::size_t  vel_y_offset,
                 float*            vel_z, const std::size_t  vel_z_stride, const std::size_t  vel_z_offset,
                 float*            weight, const std::size_t weight_stride, const std::size_t weight_offset,
                 const std::size_t N,
                 const std::size_t steps)
  : mDataPtr(kAttrNum), mStride(kAttrNum), mOffset(kAttrNum), mSize(N), mRecordsNum(steps)
{
  mDataPtr[kPosX] = pos_x;
  mStride[kPosX]  = pos_x_stride;
  mOffset[kPosX]  = pos_x_offset;

  mDataPtr[kPosY] = pos_y;
  mStride[kPosY]  = pos_y_stride;
  mOffset[kPosY]  = pos_y_offset;

  mDataPtr[kPosZ] = pos_z;
  mStride[kPosZ]  = pos_z_stride;
  mOffset[kPosZ]  = pos_z_offset;

  mDataPtr[kVelX] = vel_x;
  mStride[kVelX]  = vel_x_stride;
  mOffset[kVelX]  = vel_x_offset;

  mDataPtr[kVelY] = vel_y;
  mStride[kVelY]  = vel_y_stride;
  mOffset[kVelY]  = vel_y_offset;

  mDataPtr[kVelZ] = vel_z;
  mStride[kVelZ]  = vel_z_stride;
  mOffset[kVelZ]  = vel_z_offset;

  mDataPtr[kWeight] = weight;
  mStride[kWeight]  = weight_stride;
  mOffset[kWeight]  = weight_offset;
} // end of MemDesc
//----------------------------------------------------------------------------------------------------------------------

/**
 * Constructor.
 */
H5Helper::H5Helper(std::string inputFile,
                   std::string outputFile,
                   MemDesc     md)
  : mMd(std::move(md)),
    mInputFile(std::move(inputFile)),
    mOutputFile(std::move(outputFile)),
    mInputFileId(H5I_INVALID_HID),
    mOutputFileId(H5I_INVALID_HID) {} // end of H5Helper
//----------------------------------------------------------------------------------------------------------------------

/**
 * Destructor.
 */
H5Helper::~H5Helper()
{
  if (mInputFileId != H5I_INVALID_HID)
  {
    H5Fclose(mInputFileId);
  }

  if (mOutputFileId != H5I_INVALID_HID)
  {
    H5Fclose(mOutputFileId);
  }
} // end of ~H5Helper
//----------------------------------------------------------------------------------------------------------------------

/**
 * Initialize helper
 */
void H5Helper::init()
{
  // Open HDF5 files
  mInputFileId = H5Fopen(mInputFile.c_str(), H5F_ACC_RDONLY, H5P_DEFAULT);

  if (mInputFileId == H5I_INVALID_HID)
  {
    throw std::runtime_error("Could not open input file!");
  }

  // Open dataset
  hid_t dataset   = H5Dopen2(mInputFileId, mDatasetNames[0].c_str(), H5P_DEFAULT);
  hid_t dataSpace = H5Dget_space(dataset);

  const int nDims = H5Sget_simple_extent_ndims(dataSpace);

  std::vector<hsize_t> dims(nDims);
  H5Sget_simple_extent_dims(dataSpace, dims.data(), nullptr);

  mInputSize = 1;
  for (int i = 0; i < nDims; ++i)
  {
    mInputSize *= dims[i];
  }

  if (mInputSize < mMd.mSize)
  {
    throw std::runtime_error("Input file contains less elements than required!");
  }

  if (mInputSize > mMd.mSize)
  {
    std::cout << "Input file contains more elements than required! Ignoring the rest." << std::endl;
  }
  H5Sclose(dataSpace);
  H5Dclose(dataset);

  // Create output file
  mOutputFileId = H5Fcreate(mOutputFile.c_str(), H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);

  if (mOutputFileId < 0)
  {
    throw std::runtime_error("Could not create output file!");
  }

  if (mMd.mRecordsNum > 0)
  {
    for (int i = 0; i < MemDesc::kAttrNum; ++i)
    {
      const hsize_t aDims[2]   = {mMd.mSize, mMd.mRecordsNum};
      const hid_t   aDataSpace = H5Screate_simple(2, aDims, nullptr);
      const hid_t   aDataset   = H5Dcreate2(mOutputFileId, mDatasetNames[i].c_str(), H5T_NATIVE_FLOAT, aDataSpace,
                                        H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

      H5Sclose(aDataSpace);
      H5Dclose(aDataset);
    }
  }

  for (std::size_t i = 0; i < MemDesc::kAttrNum; ++i)
  {
    std::string suffix = "_final";

    const hsize_t aDims = mMd.mSize;
    const hid_t aDataSpace = H5Screate_simple(1, &aDims, nullptr);
    const hid_t aDataset = H5Dcreate2(mOutputFileId, (mDatasetNames[i] + suffix).c_str(), H5T_NATIVE_FLOAT, aDataSpace,
                                      H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

    H5Sclose(aDataSpace);
    H5Dclose(aDataset);
  }

  if (mMd.mRecordsNum > 0)
  {
    const hsize_t dim = mMd.mRecordsNum;
    dataSpace         = H5Screate_simple(1, &dim, nullptr);

    dataset = H5Dcreate2(mOutputFileId, "com_x", H5T_NATIVE_FLOAT, dataSpace, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    H5Dclose(dataset);

    dataset = H5Dcreate2(mOutputFileId, "com_y", H5T_NATIVE_FLOAT, dataSpace, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    H5Dclose(dataset);

    dataset = H5Dcreate2(mOutputFileId, "com_z", H5T_NATIVE_FLOAT, dataSpace, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    H5Dclose(dataset);

    dataset = H5Dcreate2(mOutputFileId, "com_w", H5T_NATIVE_FLOAT, dataSpace, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    H5Dclose(dataset);

    H5Sclose(dataSpace);
  }

  constexpr hsize_t dim = 1;
  dataSpace             = H5Screate_simple(1, &dim, nullptr);

  dataset = H5Dcreate2(mOutputFileId, "com_x_final", H5T_NATIVE_FLOAT, dataSpace, H5P_DEFAULT, H5P_DEFAULT,
                       H5P_DEFAULT);
  H5Dclose(dataset);

  dataset = H5Dcreate2(mOutputFileId, "com_y_final", H5T_NATIVE_FLOAT, dataSpace, H5P_DEFAULT, H5P_DEFAULT,
                       H5P_DEFAULT);
  H5Dclose(dataset);

  dataset = H5Dcreate2(mOutputFileId, "com_z_final", H5T_NATIVE_FLOAT, dataSpace, H5P_DEFAULT, H5P_DEFAULT,
                       H5P_DEFAULT);
  H5Dclose(dataset);

  dataset = H5Dcreate2(mOutputFileId, "com_w_final", H5T_NATIVE_FLOAT, dataSpace, H5P_DEFAULT, H5P_DEFAULT,
                       H5P_DEFAULT);
  H5Dclose(dataset);

  H5Sclose(dataSpace);
} // end of init
//----------------------------------------------------------------------------------------------------------------------


/**
 * Rad particles
 */
void H5Helper::readParticleData() const
{
  for (std::size_t i = 0; i < MemDesc::kAttrNum; i++)
  {
    const hid_t dataset = H5Dopen2(mInputFileId, mDatasetNames[i].c_str(), H5P_DEFAULT);

    const hid_t       dataspace = H5Dget_space(dataset);
    constexpr hsize_t dStart    = 0;
    constexpr hsize_t dStride   = 1;
    const hsize_t     dCount    = mMd.mSize;
    constexpr hsize_t dBlock    = 1;

    H5Sselect_hyperslab(dataspace, H5S_SELECT_SET, &dStart, &dStride, &dCount, &dBlock);

    const hsize_t dim      = mMd.mStride[i] * mMd.mSize;
    const hid_t   memSpace = H5Screate_simple(1, &dim, nullptr);

    const hsize_t     start  = mMd.mOffset[i];
    const hsize_t     stride = mMd.mStride[i];
    const hsize_t     count  = mMd.mSize;
    constexpr hsize_t block  = 1;

    H5Sselect_hyperslab(memSpace, H5S_SELECT_SET, &start, &stride, &count, &block);

    H5Dread(dataset, H5T_NATIVE_FLOAT, memSpace, dataspace, H5P_DEFAULT, mMd.mDataPtr[i]);

    H5Sclose(memSpace);
    H5Sclose(dataspace);
    H5Dclose(dataset);
  }
} // end of readParticleData
//----------------------------------------------------------------------------------------------------------------------

/**
 * Write particles.
 */
void H5Helper::writeParticleData(const size_t record) const
{
  for (std::size_t i = 0; i < MemDesc::kAttrNum; i++)
  {
    const hid_t dataset = H5Dopen2(mOutputFileId, mDatasetNames[i].c_str(), H5P_DEFAULT);

    const hid_t dataspace = H5Dget_space(dataset);

    const hsize_t dStart[2] = {0, record};
    const hsize_t dCount[2] = {mMd.mSize, 1};

    H5Sselect_hyperslab(dataspace, H5S_SELECT_SET, dStart, nullptr, dCount, nullptr);

    const hsize_t dim      = mMd.mStride[i] * mMd.mSize;
    const hid_t   memSpace = H5Screate_simple(1, &dim, nullptr);

    const     hsize_t start  = mMd.mOffset[i];
    const     hsize_t stride = mMd.mStride[i];
    const     hsize_t count  = mMd.mSize;
    constexpr hsize_t block  = 1;

    H5Sselect_hyperslab(memSpace, H5S_SELECT_SET, &start, &stride, &count, &block);

    H5Dwrite(dataset, H5T_NATIVE_FLOAT, memSpace, dataspace, H5P_DEFAULT, mMd.mDataPtr[i]);

    H5Sclose(memSpace);
    H5Sclose(dataspace);
    H5Dclose(dataset);
  }
} // end of writeParticleData
//----------------------------------------------------------------------------------------------------------------------

/**
 * Write final particle data.
 */
void H5Helper::writeParticleDataFinal() const
{
  for (std::size_t i = 0; i < MemDesc::kAttrNum; i++)
  {
    const std::string suffix  = "_final";
    const hid_t       dataset = H5Dopen2(mOutputFileId, (mDatasetNames[i] + suffix).c_str(), H5P_DEFAULT);

    const hid_t dataspace = H5Dget_space(dataset);

    const hsize_t dim      = mMd.mStride[i] * mMd.mSize;
    const hid_t   memSpace = H5Screate_simple(1, &dim, nullptr);

    const     hsize_t start  = mMd.mOffset[i];
    const     hsize_t stride = mMd.mStride[i];
    const     hsize_t count  = mMd.mSize;
    constexpr hsize_t block  = 1;

    H5Sselect_hyperslab(memSpace, H5S_SELECT_SET, &start, &stride, &count, &block);

    H5Dwrite(dataset, H5T_NATIVE_FLOAT, memSpace, H5S_ALL, H5P_DEFAULT, mMd.mDataPtr[i]);

    H5Sclose(memSpace);
    H5Sclose(dataspace);
    H5Dclose(dataset);
  }
} // end of writeParticleDataFinal
//----------------------------------------------------------------------------------------------------------------------

/**
 * Write centre of mass.
 */
void H5Helper::writeCom(const float4& com, const size_t record) const
{
  hid_t             dataset   = H5Dopen2(mOutputFileId, "com_x", H5P_DEFAULT);
  hid_t             dataSpace = H5Dget_space(dataset);
  const hsize_t     coords    = record;
  constexpr hsize_t dim       = 1;
  const hid_t       memSpace  = H5Screate_simple(1, &dim, nullptr);

  H5Sselect_elements(dataSpace, H5S_SELECT_SET, 1, &coords);

  H5Dwrite(dataset, H5T_NATIVE_FLOAT, memSpace, dataSpace, H5P_DEFAULT, &com.x);

  H5Sclose(dataSpace);
  H5Dclose(dataset);

  dataset   = H5Dopen2(mOutputFileId, "com_y", H5P_DEFAULT);
  dataSpace = H5Dget_space(dataset);

  H5Sselect_elements(dataSpace, H5S_SELECT_SET, 1, &coords);

  H5Dwrite(dataset, H5T_NATIVE_FLOAT, memSpace, dataSpace, H5P_DEFAULT, &com.y);

  H5Sclose(dataSpace);
  H5Dclose(dataset);

  dataset   = H5Dopen2(mOutputFileId, "com_z", H5P_DEFAULT);
  dataSpace = H5Dget_space(dataset);

  H5Sselect_elements(dataSpace, H5S_SELECT_SET, 1, &coords);

  H5Dwrite(dataset, H5T_NATIVE_FLOAT, memSpace, dataSpace, H5P_DEFAULT, &com.z);

  H5Sclose(dataSpace);
  H5Dclose(dataset);

  dataset   = H5Dopen2(mOutputFileId, "com_w", H5P_DEFAULT);
  dataSpace = H5Dget_space(dataset);

  H5Sselect_elements(dataSpace, H5S_SELECT_SET, 1, &coords);

  H5Dwrite(dataset, H5T_NATIVE_FLOAT, memSpace, dataSpace, H5P_DEFAULT, &com.w);

  H5Sclose(dataSpace);
  H5Dclose(dataset);
} //end of writeCom
//----------------------------------------------------------------------------------------------------------------------

/**
 * Write final Centre of Mass.
 */
void H5Helper::writeComFinal(const float4& com) const
{
  hid_t dataset = H5Dopen2(mOutputFileId, "com_x_final", H5P_DEFAULT);
  H5Dwrite(dataset, H5T_NATIVE_FLOAT, H5S_ALL, H5S_ALL, H5P_DEFAULT, &com.x);
  H5Dclose(dataset);

  dataset = H5Dopen2(mOutputFileId, "com_y_final", H5P_DEFAULT);
  H5Dwrite(dataset, H5T_NATIVE_FLOAT, H5S_ALL, H5S_ALL, H5P_DEFAULT, &com.y);
  H5Dclose(dataset);

  dataset = H5Dopen2(mOutputFileId, "com_z_final", H5P_DEFAULT);
  H5Dwrite(dataset, H5T_NATIVE_FLOAT, H5S_ALL, H5S_ALL, H5P_DEFAULT, &com.z);
  H5Dclose(dataset);

  dataset = H5Dopen2(mOutputFileId, "com_w_final", H5P_DEFAULT);
  H5Dwrite(dataset, H5T_NATIVE_FLOAT, H5S_ALL, H5S_ALL, H5P_DEFAULT, &com.w);
  H5Dclose(dataset);
} // end of writeComFinal
//----------------------------------------------------------------------------------------------------------------------
