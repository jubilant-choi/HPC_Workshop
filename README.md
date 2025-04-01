## HPC Workshop

```markdown
# 💻 Slurm 기초 실습: Job Array로 여러 작업 한 번에 돌려보기!

안녕하세요! 😊 이론으로 배운 내용을 우리 랩 서버에서 직접 경험해보는 시간이에요!
오늘은 Slurm의 강력한 기능 중 하나인 **Job Array**를 사용해서, 여러 개의 간단한 작업을 한 번의 스크립트 제출로 실행시키는 연습을 해볼 거예요.

**🎯 실습 목표**

*   간단한 Slurm 스크립트를 작성하고 이해한다.
*   Job Array (`--array`) 옵션과 `$SLURM_ARRAY_TASK_ID` 변수를 활용해본다.
*   여러 개의 작업(Task)이 동시에 제출되고, 각각 다른 '가상' 파라미터로 실행되어 다른 결과를 출력하는 것을 확인한다.

**✅ 준비물**

*   랩 서버에 SSH로 접속된 터미널 창 💻
*   간단한 텍스트 편집기 사용 능력 (nano 또는 vim 추천!)
*   터미널 기본 명령어 (`cd`, `ls`, `mkdir`, `cat`, `cp`) 사용 능력

---

## 0. 사전 세팅 ⚙️

실습을 진행하기 전에, 필요한 디렉토리를 만들고 파일을 준비합시다!

1.  **실습 디렉토리 생성 및 이동:**
    ```bash
    # 홈 디렉토리에서 시작한다고 가정합니다.
    mkdir -p ~/slurm_practice/logs  # 실습 디렉토리와 로그 저장할 하위 디렉토리 생성
    cd ~/slurm_practice           # 생성한 디렉토리로 이동
    pwd                           # 현재 위치 확인 (~/slurm_practice 여야 해요!)
    ```

2.  **(Optional) 제공된 스크립트 파일 다운로드 또는 복사:**
    *   만약 제가 `1-basic_sbatch.txt` 같은 파일을 미리 제공했다면, 이 디렉토리로 복사해주세요.
    *   없다면, 아래 단계에서 직접 만들 예정이니 걱정 마세요! 😊

---

## 1. 슬럼 스크립트 기본 📝 (`1-basic_sbatch.sh`)

가장 기본적인 Slurm 스크립트 파일을 만들어 봅시다. `nano 1-basic_sbatch.sh` 명령어로 편집기를 열고 아래 내용을 **복사 & 붙여넣기** 하거나 직접 입력해주세요.

**(주의! `<랩서버_파티션이름>` 부분은 실제 우리 랩 서버의 파티션 이름으로 바꿔주세요! 예: `debug`, `cpu`, `gpu` 등. 잘 모르겠다면 `sinfo` 명령어로 확인하거나 문의!)**

```bash
#!/bin/bash
#SBATCH --job-name=basic_slurm_job  # 작업 이름 (나중에 squeue로 볼 때 식별하기 쉽게!)
#SBATCH --output=logs/basic_job_%j.out # 표준 출력 로그 파일 (%j는 Job ID)
#SBATCH --error=logs/basic_job_%j.err  # 표준 에러 로그 파일
#SBATCH --partition=<랩서버_파티션이름>    # 작업을 실행할 파티션 지정 (★ 중요! ★)
#SBATCH --time=00:01:00             # 최대 실행 시간 (1분이면 충분해요!)
#SBATCH --nodes=1                   # 노드(컴퓨터) 1개 사용
#SBATCH --ntasks-per-node=1         # 노드당 실행할 작업(프로세스) 수
#SBATCH --cpus-per-task=1           # 작업당 사용할 CPU 코어 수

# --- 여기가 실제 작업 내용 ---
echo "=========================================="
echo "🎉 작업 시작! Job ID: $SLURM_JOB_ID"
echo "🚀 실행 노드: $SLURMD_NODENAME"
echo "⏰ 현재 시간: $(date)"
echo "=========================================="

echo ">>> 간단한 명령어를 실행해볼게요..."
sleep 15 # 15초 동안 잠시 대기 😴
echo ">>> 15초 끝! 이제 마무리합니다."

echo "=========================================="
echo "✅ 작업 완료!"
echo "=========================================="
```

*   **저장:** 편집기에서 내용을 입력/붙여넣기 한 후 저장하고 닫아주세요. (nano: Ctrl+X -> Y -> Enter)

*   **스크립트 제출:**
    ```bash
    sbatch 1-basic_sbatch.sh
    ```
    `Submitted batch job <JOB_ID>` 메시지가 나오면 성공!

*   **상태 및 결과 확인:**
    ```bash
    squeue -u $USER      # 내 작업 상태 확인 (잠시 PD -> R -> 완료 후 사라짐)
    sleep 20             # 작업이 완료될 시간을 조금 기다려요 ⏳
    ls -l logs/          # logs 디렉토리에 .out, .err 파일 생성 확인!
    cat logs/basic_job_<JOB_ID>.out # <JOB_ID>는 실제 숫자로 바꿔서 내용 확인!
    ```
    `cat` 명령어로 출력 파일 내용을 보면, 스크립트 안의 `echo` 문들이 잘 실행된 것을 볼 수 있을 거예요. 😊

---

## 2. Job Array 마법 배우기 ✨ (`2-job_array.sh`)

이제 Job Array를 사용해서 여러 작업을 한 번에 제출해 봅시다!

1.  **기본 스크립트 복사:**
    ```bash
    cp 1-basic_sbatch.sh 2-job_array.sh
    ```

2.  **스크립트 수정:** `nano 2-job_array.sh` 로 파일을 열고 아래 **굵은 글씨** 부분을 **수정 및 추가** 해주세요.

    ```bash
    #!/bin/bash
    #SBATCH --job-name=**job_array_test**     # 작업 이름 변경
    #SBATCH --output=logs/**array_job_%A_task_%a.out** # 출력 파일 이름 규칙 변경! (%A: Array Job ID, %a: Task ID)
    #SBATCH --error=logs/**array_job_%A_task_%a.err**  # 에러 파일 이름 규칙 변경!
    #SBATCH --partition=<랩서버_파티션이름>    # ★ 파티션 이름 확인! ★
    #SBATCH --time=00:01:00             # 시간은 그대로 1분
    #SBATCH --nodes=1                   # 노드 1개
    #SBATCH --ntasks-per-node=1         # 노드당 작업 1개
    #SBATCH --cpus-per-task=1           # 작업당 CPU 1개
    **#SBATCH --array=1-4               # ★ Job Array 마법 주문! (1부터 4까지 총 4개의 Task 생성!) ★**

    # --- 여기가 실제 작업 내용 ---

    # 가상 하이퍼파라미터 목록 (예시) - Bash 배열 사용
    **learning_rates=(0.1 0.05 0.01 0.005)**
    **optimizers=("Adam" "SGD" "AdamW" "RMSprop")**

    echo "=========================================="
    echo "✨ Array Job ID: $SLURM_ARRAY_JOB_ID, Task ID: $SLURM_ARRAY_TASK_ID 시작!"
    echo "🚀 실행 노드: $SLURMD_NODENAME"
    echo "⏰ 현재 시간: $(date)"
    echo "=========================================="

    # Task ID를 이용해서 파라미터 선택하기 (Bash 배열 인덱스는 0부터 시작!)
    **task_id=$SLURM_ARRAY_TASK_ID # 현재 Task의 번호 (1, 2, 3, 4 중 하나)**
    **param_index=$((task_id - 1)) # 배열 인덱스로 사용하기 위해 1을 빼줌 (0, 1, 2, 3)**

    **current_lr=${learning_rates[param_index]}**
    **current_opt=${optimizers[param_index]}**

    echo ">>> 이번 Task ($task_id) 설정값:"
    echo ">>>   Learning Rate: $current_lr"
    echo ">>>   Optimizer: $current_opt"
    echo ">>> (실제로는 이 값으로 딥러닝 모델을 학습시키겠죠? 😉)"

    sleep 10 # 잠깐 대기 😴
    echo ">>> 작업 진행 중..."
    sleep 5

    echo "=========================================="
    echo "✅ Task $task_id 완료!"
    echo "=========================================="

    ```

*   **수정 포인트:**
    *   `--job-name` 변경
    *   `--output`, `--error` 파일명 규칙에 `%A` (Array Job ID), `%a` (Task ID) 추가 ✨
    *   `--array=1-4` 추가 (1번부터 4번까지 Task 생성) ✨
    *   Bash 배열 `learning_rates`, `optimizers` 정의
    *   `$SLURM_ARRAY_TASK_ID` 변수 사용해서 현재 Task 번호 얻기
    *   Task 번호를 배열 인덱스(`$task_id - 1`)로 변환해서 해당 파라미터 값 가져오기
    *   `echo` 문에서 선택된 파라미터 값 출력하기

*   **저장:** 수정이 완료되면 저장하고 닫아주세요.

*   **스크립트 제출:**
    ```bash
    sbatch 2-job_array.sh
    ```
    `Submitted batch job <ARRAY_JOB_ID>` 메시지가 나올 거예요.

*   **상태 및 결과 확인:**
    ```bash
    squeue -u $USER      # 내 작업 상태 확인 (JOBID에 _[1-4] 같은 표시가 보일 거예요!)
    sleep 20             # 작업 완료 기다리기 ⏳
    ls -l logs/          # logs 디렉토리에 array_job_..._task_1.out 부터 task_4.out 까지 생성 확인!
    cat logs/array_job_*.out # 모든 task 결과 파일을 한 번에 보기!
    ```
    각 `task_X.out` 파일 내용을 보면, Task ID 별로 서로 다른 Learning Rate와 Optimizer 값이 출력된 것을 확인할 수 있을 거예요! 이게 바로 Job Array의 힘! 💪

---

## 3. (참고) 멀티노드 실행 (`srun`) 맛보기 👀

실제 멀티노드 실험은 복잡하지만, `srun`이 어떻게 사용되는지 간단히 살펴봅시다. (이 부분은 직접 실행하지 않고 눈으로만 봐도 좋아요!)

아래는 **2개 노드, 각 노드당 2개 작업 (총 4개 작업)**을 실행하는 예시 스크립트 (`3-multi_node_sbatch.sh`) 입니다.

```bash
#!/bin/bash
#SBATCH --job-name=multi_node_test
#SBATCH --output=logs/multi_node_%j.out
#SBATCH --error=logs/multi_node_%j.err
#SBATCH --partition=<랩서버_멀티노드가능_파티션> # ★ 멀티노드 가능한 파티션 확인! ★
#SBATCH --time=00:02:00
#SBATCH --nodes=2                   # ★ 노드 2개 요청! ★
#SBATCH --ntasks-per-node=2         # ★ 노드당 작업 2개 요청! ★
#SBATCH --cpus-per-task=1

# --- 실제 작업 내용 ---
echo "=========================================="
echo "🚀 멀티노드 작업 시작! Job ID: $SLURM_JOB_ID"
echo "🌏 총 노드 수: $SLURM_NNODES, 총 작업 수: $SLURM_NTASKS"
echo "💻 할당된 노드 목록: $SLURM_NODELIST"
echo "=========================================="

# srun을 사용하여 모든 노드의 모든 task에서 명령어를 실행!
srun hostname # 각 task가 어느 노드에서 실행되는지 확인

srun echo "Hello from Rank \$SLURM_PROCID (Task ID) on Node \$SLURMD_NODENAME !"

# 실제 분산 학습 시에는 이런 식으로 사용됨 (예시)
# srun python distributed_train.py --args ...

echo "=========================================="
echo "✅ 멀티노드 작업 완료!"
echo "=========================================="
```

*   **핵심:**
    *   `--nodes=2`, `--ntasks-per-node=2` 로 총 4개의 Task를 2개의 노드에 분산 요청.
    *   스크립트 내부에서 `srun <명령어>` 를 사용하면, 할당된 모든 Task (여기서는 4개)에서 해당 `<명령어>`가 병렬로 실행됩니다!
    *   `$SLURM_PROCID` 는 전체 작업 내에서 각 Task의 고유 번호(Rank)를 의미합니다 (0부터 시작). 분산 학습에서 매우 중요하게 사용돼요!

*   **실행해 보려면?**
    *   위 내용을 `3-multi_node_sbatch.sh` 로 저장하고, 파티션 이름을 맞게 수정한 뒤 `sbatch 3-multi_node_sbatch.sh` 로 제출해보세요!
    *   출력 로그(`logs/multi_node_<JOB_ID>.out`)를 확인하면, 4개의 Task가 2개의 다른 노드에서 메시지를 출력하는 것을 볼 수 있을 거예요.

---

## 🎉 실습 완료! 🎉

축하합니다! Slurm의 기본 스크립트 작성법과 강력한 Job Array 기능을 직접 경험해보셨습니다! 💪 멀티노드 작업 실행의 기본 개념도 살짝 맛보았네요!

**오늘 배운 것 복습:**

*   Slurm 스크립트의 기본 구조 (`#SBATCH`)
*   Job Array (`--array`)로 여러 작업 효율적으로 제출하기
*   `$SLURM_ARRAY_TASK_ID` 로 각 작업(Task) 구분하고 파라미터 다르게 주기
*   `srun` 명령어로 할당된 자원에서 명령어 실행하기 (특히 멀티노드에서!)

이제 이 기본기를 바탕으로 실제 연구에 필요한 스크립트를 작성하고, 하이퍼파라미터 튜닝이나 다양한 조건의 실험들을 훨씬 효율적으로 진행하실 수 있을 거예요! 😊

궁금한 점이 있다면 언제든지 편하게 질문해주세요! 수고하셨습니다! 🥰
```
