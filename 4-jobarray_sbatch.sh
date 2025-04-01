#!/bin/bash
#SBATCH -J HPCworkshop_jobarray
#SBATCH -p debug                # Only debug in lab server, check official other servers' docs for available partition names 
#SBATCH -t 00:03:00             # time
#SBATCH -N 1                    # number of nodes
#SBATCH -D /scratch/connectome/jubin/projects/250402_HPC_Workshop   # change directory
#SBATCH --nodelist=node2        # maybe only useful in labserver
#SBATCH --ntasks-per-node=1      # 노드당 작업 1개
#SBATCH --array=1-4              # ★ Job Array 마법 주문! (1부터 4까지 총 4개의 Task 생성!) ★
#SBATCH --output=logs/systematic/%x-%j-%A.o   # https://slurm.schedmd.com/sbatch.html#SECTION_FILENAME-PATTERN
#SBATCH --error=logs/systematic/%x-%j-%A.e    # %x means "Job name", %j means "jobid of the running job."

# 가상 하이퍼파라미터 목록 (예시)
learning_rates=(0.1 0.05 0.01 0.005)
batch_sizes=(32 64 128 256)

# 실제 작업 내용
echo "🌟 Array Job ID: $SLURM_ARRAY_JOB_ID, Task ID: $SLURM_ARRAY_TASK_ID 시작!"

# Task ID를 이용해서 파라미터 선택하기 (Bash 배열 인덱스는 0부터 시작!)
task_id=$SLURM_ARRAY_TASK_ID # 현재 Task의 번호 (1, 2, 3, 4 중 하나)
param_index=$((task_id - 1)) # 배열 인덱스로 사용하기 위해 1을 빼줌 (0, 1, 2, 3)

current_lr=${learning_rates[param_index]}
current_bs=${batch_sizes[param_index]}

echo "이번 Task ($task_id)는 Learning Rate = $current_lr, Batch Size = $current_bs 로 실행되는 척! 😉"
echo "(실제로는 여기에 python train.py --lr $current_lr --batch_size $current_bs 같은 코드가 들어가겠죠?)"
sleep 10 # 잠깐 대기
echo "Task $task_id 종료! 👋"