#!/bin/bash
#SBATCH -J HPCworkshop_systematic
#SBATCH -p debug                # Only debug in lab server, check official other servers' docs for available partition names 
#SBATCH -t 00:03:00             # time
#SBATCH -N 1                    # number of nodes
#SBATCH -D /scratch/connectome/jubin/projects/250402_HPC_Workshop   # change directory
#SBATCH --nodelist=node2        # maybe only useful in labserver
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=1G
#SBATCH --output=logs/systematic/%x-%j.o   # https://slurm.schedmd.com/sbatch.html#SECTION_FILENAME-PATTERN
#SBATCH --error=logs/systematic/%x-%j.e    # %x means "Job name", %j means "jobid of the running job."

# add below options if needed
# #SBATCH --gpus=1 # for node1, node3, or GPU nodes. Remove for node2/4
# #SBATCH --mail-user=<your_mail@mail.com> # useful when you have to know when the job begins/ends
# #SBATCH --mail-type=ALL # https://slurm.schedmd.com/sbatch.html#OPT_mail-type

# == Helper functions ====================================================START
repeat_string() {
    local string=$1
    local n=$2
    printf "%s" "$string"
    for (( i=1; i<n; i++ ));
    do
        printf ",%s" "$string"
    done
}
# == Helper functions ====================================================END


# == Prepare for experiments =============================================START
export TZ='Asia/Seoul' # Set your timezone, not using UTC for experiment logging convenience
start=$(date +%s)
SECONDS=0 # This variable is reserved for checking elapsed time from initialization.
pwd; hostname; date
# == Prepare for experiments =============================================END


# == Setup module & env ==================================================START
# which conda
# source activate base
# == Setup module & env ==================================================END


# == Setup for experiment ================================================START
# Get the first node in the nodelist to assign to master
first=$(scontrol show hostnames $SLURM_NODELIST | head -n 1)
echo "first = ${first}, which is from scontrol show hostname $SLURM_NODELIST"

# Get the first node's IP
export MASTER_ADDR=$(srun --nodes=1 --ntasks=1 -w $first  hostname --ip-address | cut -d' ' -f 1)

# set ranks and other variables
ranks_per_node=$SLURM_NTASKS_PER_NODE # Originally, it is the same with the number of GPUs in each node or SLURM_NGPUS
ranks_total=$SLURM_NTASKS # Originally, it is $(ranks_per_node*$SLURM_JOB_NUM_NODES). 
nodes_per_work=$SLURM_NNODES
if [ -z $SLURM_CPUS_PER_TASK ]; then
    cpus_per_task=$(($SLURM_CPUS_ON_NODE / $SLURM_NTASKS_PER_NODE))
else
    cpus_per_task=$SLURM_CPUS_PER_TASK
fi

# repeat the hostname of the master N_nodes times
nodelist=$(repeat_string "${first}" $nodes_per_work) 

echo "NUM_NODES      = $SLURM_NNODES"
echo "nodelist       = ${nodelist}"
echo "MASTER_ADDR    = ${MASTER_ADDR}"
echo "Ranks per node = ${ranks_per_node}"
echo "GPUs per rank  = ${ranks_per_node}"
echo "Total ranks    = ${ranks_total}"

# get hyperparameters from arguments
learning_rate=$1
weight_decay=$2
mask_ratio=$3
# == Setup for experiment ================================================END


# == Run experiment in parellel with srun ================================START
set -x
srun -c"${cpus_per_task}" \
     -u \
     -n "${ranks_total}" \
     -N "${nodes_per_work}" \
     --nodelist="${nodelist}" \
     "./3-srun_hyperparams.sh" $MASTER_ADDR $learning_rate $weight_decay $mask_ratio
# == Run experiment in parellel with srun ================================END

# Print time spent & end date
echo Experiment ended, $SECONDS seconds elapsed