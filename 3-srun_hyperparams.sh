#!/bin/bash
export RANK=$SLURM_PROCID
export LOCAL_RANK=$SLURM_LOCALID
export WORLD_SIZE=$SLURM_NTASKS
export MASTER_ADDR=$1
export MASTER_PORT=29500

learning_rate=$2
weight_decay=$3
mask_ratio=$4

export NEPTUNE_CUSTOM_RUN_ID="1B_lr${learning_rate}_wd${weight_decay}_mask${mask_ratio}" # make it easy to create & resume neptune run with custom exp_id

echo "Rank ${RANK} local rank ${LOCAL_RANK} master ${MASTER_ADDR} master port ${MASTER_PORT} visible devices CUDA ${CUDA_VISIBLE_DEVICES} WORLD_SIZE ${WORLD_SIZE}"
echo "EXP_ID=${NEPTUNE_CUSTOM_RUN_ID}, learning_rate=${learning_rate}, weight_decay=${weight_decay}, mask_ratio=${mask_ratio}"
# python ~.py ~~