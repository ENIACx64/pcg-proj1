#!/bin/sh

#
# @file      load_modules.sh
#
# @author    Oliver Kunik \n
#            Faculty of Information Technology \n
#            Brno University of Technology \n
#            ikunik@fit.vutbr.cz
#
# @brief     PCG - Assignement / Modules
#
# @version   2025
#
# @date      24 September 2025, 14:56 (created) \n
# @date      03 October   2025, 21:54 (revised) \n
#

if [ "$CLUSTERNAME" = "KAROLINA" ]; then
  ml purge 2>/dev/null
  ml CMake/4.0.3-GCCcore-14.3.0 Python/3.13.5-GCCcore-14.3.0 HDF5/1.14.6-iimpi-2025b GCC/14.3.0 CUDA/12.8.0
  export CC=gcc
  export CXX=g++
fi

if [ "$CLUSTERNAME" = "BARBORA" ]; then
  ml purge 2>/dev/null
  ml CMake/3.26.3-GCCcore-12.3.0 Python/3.11.3-GCCcore-12.3.0 HDF5/1.14.0-gompi-2023a GCC/12.3.0 CUDA/12.2.0
  export CC=gcc
  export CXX=g++
fi
