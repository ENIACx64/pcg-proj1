#!/bin/bash

#
# @file      compare.sh
#
# @author    David Bayer \n
#            Faculty of Information Technology \n
#            Brno University of Technology \n
#            ibayer@fit.vutbr.cz
#
# @author    Oliver Kunik \n
#            Faculty of Information Technology \n
#            Brno University of Technology \n
#            ikunik@fit.vutbr.cz
#
# @brief     PCG - Assignment 1 / Compare script
#
# @version   2025
#
# @date      04 October   2023, 09:00 (created) \n
# @date      03 October   2025, 11:13 (revised)
#

if [[ $# -lt 2 ]]; then
	echo "Usage: <cpu_output.h5> <gpu_output.h5> [STEP_NUMBER]" >&2
	exit 1
fi

if [[ -z "$3" ]]; then
  STEP=4
elif [[ "$3" =~ ^[0-4]$ ]]; then
  STEP="$3"
else
  echo "Error: STEP_NUMBER must be a number between 0 and 4." >&2
  exit 1
fi

dataset_info() {
    local file="$1"
    local dataset="$2"

    h5dump -pH -d "$dataset" "$file" 2>/dev/null | awk '
    /DATATYPE/ {type=$2}
    /DATASPACE/ {
        match($0, /\{.*\}/, arr)
        shape=arr[0]
    }
    /STORAGE_LAYOUT/ {
        getline
        getline
        if ($1=="SIZE") size=$2
    }
    END {print shape, type, size}'
}

datasets_comparable() {
    local f1="$1"
    local f2="$2"
    local dataset="$3"

    # Get full info: shape, type, size
    local info1 info2
    info1=$(dataset_info "$f1" "$dataset") || return 1
    info2=$(dataset_info "$f2" "$dataset") || return 1

    # Extract allocated size (last field)
    local size1 size2
    size1=$(echo "$info1" | awk '{print $NF}')
    size2=$(echo "$info2" | awk '{print $NF}')

    # Extract shape and type (all fields except last)
    local shape_type1 shape_type2
    shape_type1=$(echo "$info1" | awk '{$NF=""; print $0}' | xargs)
    shape_type2=$(echo "$info2" | awk '{$NF=""; print $0}' | xargs)

    # Compare shape/type as strings, and allocated size numerically
    if [[ "$shape_type1" == "$shape_type2" && "$size1" -gt 0 && "$size2" -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

compare_h5() {
    local f1="$1"
    local f2="$2"
    local dataset="$3"
    local precision="${4:-0.0001}"  # optional, default 0.0001

    echo -n "$dataset: "  # always print dataset name

    # Check if comparable using existing function
    if ! datasets_comparable "$f1" "$f2" "$dataset"; then
        echo "Dataset not comparable"
        return
    fi

    # Datasets are comparable, check if identical
    if h5diff -q -p "$precision" "$f1" "$f2" "$dataset" >/dev/null 2>&1; then
        echo "OK"
    else
        # Differences found, show verbose diff
        h5diff -v1 -p "$precision" "$f1" "$f2" "$dataset"
    fi
}



for ds in /pos_x_final /pos_y_final /vel_x_final /vel_y_final /vel_z_final /weight_final; do
  compare_h5 "$1" "$2" "$ds"
done

if [[ "$STEP" -ge 3 ]]; then
  for ds in /com_x_final /com_y_final /com_z_final /com_w_final; do
    compare_h5 "$1" "$2" "$ds"
  done
fi

if [[ "$STEP" -ge 4 ]]; then
  for ds in /pos_x /pos_y /pos_z /vel_x /vel_y /vel_z /weight /com_x /com_y /com_z /com_w; do
    compare_h5 "$1" "$2" "$ds"
  done
fi
