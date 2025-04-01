#!/bin/bash
export RANK=$SLURM_PROCID
export LOCAL_RANK=$SLURM_LOCALID
export WORLD_SIZE=$SLURM_NTASKS
export MASTER_ADDR=$1
export MASTER_PORT=29500

ping_result=$(ping -c 1 $MASTER_ADDR | head -n 2)
echo "Rank ${RANK} local rank ${LOCAL_RANK} master ${MASTER_ADDR} master port ${MASTER_PORT} visible devices CUDA ${CUDA_VISIBLE_DEVICES} WORLD_SIZE ${WORLD_SIZE}, PING result=$ping_result"
# python ~.py ~~