#!/bin/bash
#SBATCH -J HPCworkshop_multiple_srun
#SBATCH -p debug                # Only debug in lab server, check official other servers' docs for available partition names 
#SBATCH -t 00:03:00             # time
#SBATCH -N 1                    # number of nodes
#SBATCH -D /scratch/connectome/jubin/projects/250402_HPC_Workshop   # change directory
#SBATCH --nodelist=node2        # maybe only useful in labserver
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=1G
#SBATCH --output=logs/multiple_srun/%x-%j.o   # https://slurm.schedmd.com/sbatch.html#SECTION_FILENAME-PATTERN
#SBATCH --error=logs/multiple_srun/%x-%j.e    # %x means "Job name", %j means "jobid of the running job."

# add below options if needed
# #SBATCH --gpus=1 # for node1, node3, or GPU nodes. Remove for node2/4
# #SBATCH --mail-user=<your_mail@mail.com> # useful when you have to know when the job begins/ends
# #SBATCH --mail-type=ALL # https://slurm.schedmd.com/sbatch.html#OPT_mail-type

# Function to repeat a string
repeat_string() {
    local string=$1
    local n=$2
    printf "%s" "$string"
    for (( i=1; i<n; i++ ));
    do
        printf ",%s" "$string"
    done
}

# Parse script's arguments
parse_arguments() {
    while [[ $# -gt 0 ]]
    do
        key="$1"
        case $key in
            -s|--wrap-script) wrap_script="$2"; shift; shift ;;
            -n|--nodes-per-job) nodes_per_job="$2"; shift; shift ;;
            -r|--learning-rates) learning_rates="$2"; shift; shift ;;
            -w|--weight-decays) weight_decays="$2"; shift; shift ;;
            -m|--mask-ratios) mask_ratios="$2"; shift; shift ;;
            -h|--help) usage; exit 0 ;;
            *) echo "Error: Unsupported argument $1"; exit 1 ;;
        esac
    done
}

usage(){
  echo -e "\n=========================================================================================================================="
  echo "Usage: $0"
  echo -e "\t[-s|--wrap-script <wrap_script>]: Path to the wrap script"
  echo -e "\t[-n|--nodes-per-job <nodes_per_job>]: Numbers of nodes used for each training"
  echo -e "\t[-r|--learning-rates <learning_rates>]: Comma separated learning rates."
  echo -e "\t[-w|--weight-decays <weight_decays>]: Comma separated weight decays."
  echo -e "\t[-m|--mask-ratios <mask_ratios>]: Comma separated mask ratios."
  echo -e "==========================================================================================================================\n"
}

# Validate required parameters
validate_parameters() {
    if [ ! -e "${wrap_script}" ]; then echo "Error: wrap_script ${wrap_script} does not exist!"; exit 1; fi
    if [ -z "${learning_rates}" ]; then echo "Error: learning rates is required"; exit 1; fi
    if [ -z "${weight_decays}" ]; then echo "Error: weight decays is required"; exit 1; fi
    if [ -z "${mask_ratios}" ]; then echo "Error: mask ratios is required"; exit 1; fi
    echo "** Parameters **"
    echo "  wrap_script: $wrap_script"
    echo "  nodes_per_job: $nodes_per_job"
    echo "  learning_rates: $learning_rates"
    echo "  weight_decays: $weight_decays"
    echo "  mask_ratios: $mask_ratios"
}

get_absolute_wrap_script() {
  wrap_script=$(readlink -f "${wrap_script}")
    echo "$wrap_script"
}

# Split hyper-parameter string into array
split_hyperparameters(){
  IFS=',' read -r -a lr_arr <<< $learning_rates
  IFS=',' read -r -a wd_arr <<< $weight_decays
  IFS=',' read -r -a mask_arr <<< $mask_ratios
  echo "${lr_arr[@]}"
  echo "${wd_arr[@]}"
  echo "${mask_arr[@]}"
}

# Count number of hyper-parameters combinations
count_hyperparam_combinations(){
    num_works=$(( ${#lr_arr[@]} * ${#wd_arr[@]} * ${#mask_arr[@]}))
    echo "$num_works"
}

# Compute total nodes
compute_total_nodes(){
    total_nodes=$(( num_works * nodes_per_job ))
    echo "$total_nodes"
}

# Validate total nodes requested
validate_total_nodes() {
    total_nodes="$1"
    if [ -v SLURM_JOB_NUM_NODES ]; then
        if [ ${total_nodes} -ne "${SLURM_JOB_NUM_NODES}" ]; then
            echo -e "Total number of nodes needed (${total_nodes}) is different from SLURM_JOB_NUM_NODES (${SLURM_JOB_NUM_NODES})."
            exit 1
        fi
    else
        echo -e "\n==$0 Dry-Run Summary ====================================================================="
        echo -e "\n"
        echo -e "\tRun jobs with wrap script ${wrap_script}."
        echo -e "\n"
        echo -e "\tFind ${num_works} hyperparameter combinations."
        echo -e "\tNumber of nodes per work = ${nodes_per_job}"
        echo -e "\tTotal nodes needed is = ${total_nodes}"
        echo -e "\n"
        echo -e "\t\e[1;33mRemember to use -N ${total_nodes} when submitting the sbatch job.\e[0m"
        echo -e "==========================================================================================\n"
        exit 0
    fi
}

# Setup environment
setup_environment() {
    echo "* Setting up environments"
    # conda activate <your_env>
    # module load something
}

# Collect node info
collect_node_info() {
  TMP_SRUN_DIR=/tmp/${SLURM_JOB_ID} # 241112 added
  mkdir -p $TMP_SRUN_DIR # 241112 added
  srun --ntasks="${SLURM_JOB_NUM_NODES}" --ntasks-per-node=1 bash -c "hostname --ip-address | cut -d' ' -f 2| awk -v pid="\$SLURM_PROCID" '{print pid, \$1}'" | sort -n > ${TMP_SRUN_DIR}/ip.txt
  srun --ntasks="${SLURM_JOB_NUM_NODES}" --ntasks-per-node=1 bash -c "hostname | awk -v pid="\$SLURM_PROCID" '{print pid, \$1}' " | sort -n > ${TMP_SRUN_DIR}/host.txt
  echo "$TMP_SRUN_DIR"
}

# Define global variables
define_global_variables() {
  # export some variables here
  echo "* Setting global variables"
  # "export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7"
  # set ranks and other variables
  ranks_per_node=$SLURM_NTASKS_PER_NODE # Originally, it is the same with the number of GPUs in each node or SLURM_NGPUS
  ranks_total=$((ranks_per_node * nodes_per_job)) 
  if [ -z $SLURM_CPUS_PER_TASK ]; then
      cpus_per_task=$(($SLURM_CPUS_ON_NODE / $SLURM_NTASKS_PER_NODE))
  else
      cpus_per_task=$SLURM_CPUS_PER_TASK
  fi
}

# Launch training jobs
launch_training_jobs() {
    echo "** LAUNCH TRAINING JOBS - ranks_total - $ranks_total, nodes_per_job - $nodes_per_job, TMP_SRUN_DIR - $TMP_SRUN_DIR **"
    ranks_total="$1"
    job_index=0
    for lr in ${lr_arr[@]}
    do
        for wd in ${wd_arr[@]}
        do
            for mask_ratio in ${mask_arr[@]}
            do
                echo ========================================================================================================================
                k=$((job_index * nodes_per_job))
                # Extract k-th line and split into PROCID and IP
                ip_line=$(sed -n "$((k+1))p" "${TMP_SRUN_DIR}/ip.txt") # $(head -n 1 "${TMP_SRUN_DIR}/ip.txt")
                IFS=' ' read -r ip_procid master <<< "$ip_line"
                # Extract k-th line and split into PROCID and hostname
                host_line=$(sed -n "$((k+1))p" "${TMP_SRUN_DIR}/host.txt") # $(head -n 1 "${TMP_SRUN_DIR}/host.txt")
                IFS=' ' read -r host_procid host_name <<< "$host_line"
                echo -e "* Start job [${job_index}] on IP [${master}] with hostname [${host_name}], lr=[${lr}], wd=[${wd}], mask_ratio=[${mask_ratio}] *"

                nodelist=$(repeat_string "${host_name}" $nodes_per_job)
                for (( j=1; j<nodes_per_job; j++ ))
                do
                    k=$((job_index * nodes_per_job + j))
                    # Extract k-th line and split into PROCID and hostname
                    host_line=$(sed -n "$((k+1))p" "${TMP_SRUN_DIR}/host.txt")
                    IFS=' ' read -r host_procid host_name <<< "$host_line"
                    nodelist=${nodelist},$(repeat_string "${host_name}" $nodes_per_job)
                done
                echo "* NODELIST - $nodelist *"

                echo "* srun -c"${cpus_per_task}" -u -n "${ranks_total}" -N "${nodes_per_job}" --nodelist="${nodelist}" 
                     --output="$root_dir/logs/multiple_srun/${err_out_fname}_%j-${job_index}_lr${lr}_wd${wd}_${mask_ratio}.out" 
                     --error="$root_dir/logs/multiple_srun/${err_out_fname}_%j-${job_index}_lr${lr}_wd${wd}_${mask_ratio}.err" 
                     "${wrap_script}" "${master}"  "${lr}" "${wd}" "${mask_ratio}" *"

                srun -c"${cpus_per_task}" \
                     -u \
                     -n "${ranks_total}" \
                     -N "${nodes_per_job}" \
                     --nodelist="${nodelist}" \
                     --output="$root_dir/logs/multiple_srun/${err_out_fname}_%j-${job_index}_lr${lr}_wd${wd}_${mask_ratio}.out" \
                     --error="$root_dir/logs/multiple_srun/${err_out_fname}_%j-${job_index}_lr${lr}_wd${wd}_${mask_ratio}.err" \
                     "${wrap_script}" "${master}"  "${lr}" "${wd}" "${mask_ratio}" &

                sleep 1
                ((job_index++))
                nodelist=""
                echo ========================================================================================================================
            done
        done
    done
    wait
    echo "Main script complete"
}


root_dir=$(pwd)
wrap_script="$root_dir/5-srun_multiple.sh" # "$root_dir/sample_scripts/run_multi/srun_debug/wrap_debug.sh"
nodes_per_job=1 # Set default value
parse_arguments "$@" # Parse arguments. when using salloc, use like parse_arguments -r 2.5e-3 -w 0.1 -m 0.2,0.8
validate_parameters # Validate parameters
split_hyperparameters # Split learning rate and weight decay string
num_works=$(count_hyperparam_combinations) # Count number of sub jobs
total_nodes=$(compute_total_nodes) # compute total number of nodes required
validate_total_nodes "$total_nodes" # Validate total number of nodes
setup_environment # Setup environment
TMP_SRUN_DIR=$(collect_node_info) # Collect node info
echo ========================================================================================================================
ls $TMP_SRUN_DIR/ip*
echo ========================================================================================================================
define_global_variables
curr_date=$(date +'%y%m%d-%H%M')
err_out_fname="${curr_date}_multiple_srun" # "250120_1.2B_lr2.5e-5_wd0.05_4masks_64node_extended"
launch_training_jobs "$ranks_total" # Launch training jobs