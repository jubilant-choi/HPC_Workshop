#!/bin/bash
#SBATCH -J HPCworkshop_basic
#SBATCH -p debug                # Only debug in lab server, check official other servers' docs for available partition names 
#SBATCH -t 00:03:00             # time
#SBATCH -N 1                    # number of nodes
#SBATCH -D /scratch/connectome/jubin/projects/250402_HPC_Workshop   # change directory
#SBATCH --nodelist=node4        # maybe only useful in labserver
#SBATCH --ntasks-per-node=1 
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=2G
#SBATCH --output=logs/%x-%j.o   # https://slurm.schedmd.com/sbatch.html#SECTION_FILENAME-PATTERN
#SBATCH --error=logs/%x-%j.e    # %x means "Job name", %j means "jobid of the running job."

# add below options if needed
# #SBATCH --gpus=1 # for node1, node3, or GPU nodes. Remove for node2/4
# #SBATCH --mail-user=<your_mail@mail.com> # useful when you have to know when the job begins/ends
# #SBATCH --mail-type=ALL # https://slurm.schedmd.com/sbatch.html#OPT_mail-type

# Prepare for experiments
export TZ='Asia/Seoul' # Set your timezone, not using UTC for experiment logging convenience
start=$(date +%s)
SECONDS=0 # This variable is reserved for checking elapsed time from initialization.
pwd; hostname; date         

# setup your env here
# In lab server, do something like this
# source activate 3DCNN
which conda # /usr/anaconda3/bin/conda
conda env list

# In Perlmutter or other clusters, you have to use "module load ~~"
# module load pytorch/2.3.1
# module load gcc/11.2.0
echo "Hello, world!"
env | grep SLURM # show you slurm env variables
sleep 10

# Print time spent & end date
echo Experiment ended, $SECONDS seconds elapsed