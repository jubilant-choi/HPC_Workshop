# Connectome Lab HPC Workshop

안녕하세요! 😊 이론으로 배운 내용을 우리 랩 서버에서 직접 경험해보는 시간이에요!
이번 실습에서는 Slurm 스크립트를 작성하고 제출하는 다양한 방법들을 단계별로 알아볼 거예요. 기본적인 스크립트부터 시작해서, 멀티 노드 작업, 체계적인 실험 제출 방법까지 함께 살펴봅시다!

**🎯 실습 목표**

*   다양한 유형의 Slurm 스크립트를 이해하고 작성/수정할 수 있다.
*   각 스크립트의 사용 목적과 장단점을 파악한다.
*   `sbatch`, `srun`, Slurm 환경 변수 등의 기본 개념을 실제 스크립트를 통해 익힌다.

**✅ 준비물**

*   랩 서버에 SSH로 접속된 터미널 창 💻
*   간단한 텍스트 편집기 사용 능력 (nano 또는 vim 추천!)
*   터미널 기본 명령어 (`cd`, `ls`, `mkdir`, `cat`, `cp`, `chmod`) 사용 능력
*   **(중요!)** 제공된 실습용 스크립트 파일들 (`0-setup.sh`, `1-*.sh`, `2-*.sh`, `3-*.sh`, `4-*.sh`) 이 실습 디렉토리에 준비되어 있어야 합니다!

---

### 0. 사전 세팅 ⚙️

실습을 원활하게 진행하기 위해, 필요한 디렉토리를 만들고 스크립트 파일에 실행 권한을 부여합시다!

- **실습 디렉토리 생성 및 이동:**

```bash
# 랩서버 SCRATCH 디렉토리에서 시작한다고 가정합니다.
cd $SCRATCH
git clone https://github.com/jubilant-choi/HPC_Workshop.git
cd HPC_Workshop
chmod +x 0-setup.sh
bash 0-setup.sh
```
*   튜토리얼을 진행할 위치로 이동한 후, 이 깃헙 레포를 클론해주세요.
*   이후 HPC_Workshop 폴더로 이동한 후 0-setup.sh의 권한을 변경해주세요.
*   그 다음  0-setup.sh 파일을 실행해주세요.
*   `logs`, `logs/systematic`, `logs/multiple_srun` 디렉토리가 생성됩니다. 각 실습 단계의 로그 파일이 이곳에 저장될 거예요.
*   또한 이제 모든 `.sh` 파일들이 실행 가능한 상태가 되었습니다! ✨
*   `ls *.sh` 명령어로 파일들이 잘 있는지 확인해보세요!

---

### 1. 슬럼 스크립트 기본 📝 (`1-basic_sbatch.sh`)

가장 기본 형태의 Slurm 스크립트입니다. **하나의 노드**에서 **하나의 작업**을 실행하는 방법을 보여줍니다.

*   **스크립트 살펴보기:** `cat 1-basic_sbatch.sh` 명령어로 내용을 확인해보세요.
    *   `#SBATCH` 지시어들: 작업 이름(`-J`), 사용할 파티션(`-p`), 예상 시간(`-t`), 사용할 노드 수(`-N`), 로그 파일 경로(`-o`, `-e`) 등을 설정합니다.
        *   **꿀팁🍯:** `-D` 옵션으로 작업 디렉토리를 지정하면 편리해요!
        *   **꿀팁🍯:** 로그 파일 이름에 `%x` (Job 이름), `%j` (Job ID)를 사용하면 구분이 쉬워요!
    *   **환경 설정 주석:** 실제로는 이 부분에 `module load`나 `conda activate` 같은 명령어를 넣어 실험 환경을 맞춰줍니다.
    *   **실행 명령어:** `echo`, `hostname`, `date`, `sleep` 등 간단한 명령어들을 실행합니다.
    *   `env | grep SLURM`: Slurm이 제공하는 환경 변수들을 확인해볼 수 있어요!

*   **스크립트 제출 및 확인:**
    ```bash
    # <랩서버_파티션이름> 부분을 실제 파티션 이름으로 수정했는지 다시 확인!
    nano 1-basic_sbatch.sh # 필요시 수정
    sbatch 1-basic_sbatch.sh
    squeue -u $USER # 작업 상태 확인
    # 잠시 기다린 후...
    ls -l logs/ # 로그 파일 생성 확인
    cat logs/<로그파일명>.o # 실제 로그 파일 이름으로 바꿔서 내용 확인
    ```
*   **핵심:** Slurm 스크립트의 기본 구조와 `#SBATCH` 옵션 설정법, 그리고 작업 제출 및 결과 확인의 기본 흐름을 이해하는 것이 목표입니다! 😊

---

### 2. `srun`으로 멀티태스크/멀티노드 실행하기 🚀 (`2-using_srun_sbatch.sh`, `2-srun_example.sh`)

이번에는 **여러 노드**에 걸쳐 **여러 개의 Task(프로세스)**를 실행하는, 소위 '분산(Distributed)' 작업의 기초를 알아봅니다. `sbatch` 스크립트가 환경을 설정하고, `srun` 명령어가 실제 작업을 병렬로 실행시키는 구조입니다. (MPI나 PyTorch DDP 같은 분산 학습의 기본 원리!)

*   **스크립트 살펴보기:**
    *   `cat 2-using_srun_sbatch.sh`:
        *   `#SBATCH -N 2`: **2개의 노드**를 요청합니다!
        *   `#SBATCH --ntasks-per-node=2`: **노드당 2개의 Task**를 실행하도록 요청합니다 (총 4개 Task).
        *   **Master Node 주소 찾기:** `scontrol show hostnames`, `srun hostname --ip-address` 등을 조합하여 분산 작업의 기준점(Master)이 될 노드의 IP 주소를 찾습니다. (분산 환경 설정의 핵심!)
        *   **`srun` 명령어:** `-n` (총 Task 수), `-N` (총 노드 수) 등의 옵션과 함께, 실제 작업을 수행할 **워커 스크립트 (`2-srun_example.sh`)**를 호출합니다. Master IP 주소를 인자로 넘겨줍니다.
    *   `cat 2-srun_example.sh`:
        *   `srun`에 의해 **각 Task에서 개별적으로 실행**되는 스크립트입니다.
        *   `$1`: `sbatch` 스크립트에서 넘겨준 Master IP 주소를 받습니다.
        *   **Slurm 환경 변수 활용:** `$SLURM_PROCID` (전체 Rank), `$SLURM_LOCALID` (노드 내 Local Rank), `$SLURM_NTASKS` (전체 Task 수 = World Size) 등을 활용하여 각 Task가 자신의 역할(Rank)을 인지하고 분산 작업을 수행하게 됩니다.
        *   `echo`를 통해 각 Rank가 어떤 정보를 가지고 있는지 출력합니다. (실제로는 여기에 `python 분산학습코드.py ...`가 들어갑니다.)

*   **스크립트 제출 및 확인:**
    ```bash
    # 파티션 이름, 노드 목록(--nodelist) 등을 랩 서버 환경에 맞게 수정했는지 확인!
    nano 2-using_srun_sbatch.sh # 필요시 수정
    sbatch 2-using_srun_sbatch.sh
    squeue -u $USER
    # 잠시 기다린 후...
    ls -l logs/
    cat logs/<로그파일명>.o # 총 4개의 Task에서 출력한 메시지 확인! (Rank 0, 1, 2, 3)
    ```
*   **핵심:** `sbatch` 스크립트가 전체 판을 깔고(`-N`, `--ntasks-per-node`), `srun`이 각 Task에게 역할을 부여하며(`SLURM_*` 변수들) 실제 작업을 병렬로 실행시키는 과정을 이해하는 것이 중요합니다! ✨

---

### 3. 체계적인 실험 제출 (방법 1: 외부 스크립트로 `sbatch` 반복 호출) 🔄 (`3-systematic_sbatch.sh`, `3-srun_hyperparams.sh`, `3-iter_sbatch_helper.sh`)

하이퍼파라미터 튜닝처럼 **동일한 구조의 작업을 파라미터만 바꿔가며 여러 번 독립적으로 실행**하고 싶을 때 사용하는 방법 중 하나입니다. 외부 헬퍼 스크립트(`bash`)가 `sbatch` 명령어를 반복 호출하여 **여러 개의 독립적인 Slurm Job**을 생성합니다.

*   **스크립트 살펴보기:**
    *   `cat 3-iter_sbatch_helper.sh`:
        *   **이 스크립트는 `sbatch`로 제출하는 것이 아니라, 터미널에서 `bash`로 직접 실행합니다!**
        *   Bash 배열(`lrs`, `wds`, `masks`)로 튜닝할 하이퍼파라미터 목록을 정의합니다.
        *   **중첩 `for` 루프:** 모든 파라미터 조합을 순회합니다.
        *   루프 내부에서 **`sbatch` 명령어 호출:** 각 조합에 대해 `3-systematic_sbatch.sh` 스크립트를 제출합니다. 이때, `--job-name`을 설정하고 **파라미터들을 커맨드 라인 인자**로 넘겨줍니다!
    *   `cat 3-systematic_sbatch.sh`:
        *   `iter_sbatch_helper.sh`에 의해 **개별 Job으로 제출되는** 스크립트입니다.
        *   스크립트 앞부분은 이전 예제들과 유사합니다 (자원 요청, 환경 설정 등).
        *   **`$1`, `$2`, `$3`**: 헬퍼 스크립트에서 넘겨준 커맨드 라인 인자(lr, wd, mask_ratio)를 받습니다!
        *   `srun`을 사용하여 워커 스크립트(`3-srun_hyperparams.sh`)를 호출하며, 받은 파라미터들을 다시 넘겨줍니다.
    *   `cat 3-srun_hyperparams.sh`:
        *   `srun`에 의해 각 Task에서 실행됩니다.
        *   Master 주소 외에 추가적인 하이퍼파라미터 인자들(`$2`, `$3`, `$4`)을 받습니다.
        *   받은 파라미터를 사용합니다 (예: `NEPTUNE_CUSTOM_RUN_ID` 설정, 로그 출력 등).

*   **실행 방법 및 확인:**
    ```bash
    # 3-systematic_sbatch.sh 안의 파티션 등을 환경에 맞게 수정했는지 확인!
    nano 3-systematic_sbatch.sh # 필요시 수정

    # 헬퍼 스크립트를 bash로 실행하여 여러 sbatch 작업을 제출!
    bash 3-iter_sbatch_helper.sh

    # squeue로 확인하면 여러 개의 Job이 생성된 것을 볼 수 있음!
    squeue -u $USER

    # 잠시 기다린 후 logs/systematic/ 디렉토리 확인
    ls -l logs/systematic/
    # 각 Job의 로그 파일 내용을 cat으로 확인
    ```
*   **핵심:** 외부 쉘 스크립트를 이용해 **여러 개의 독립적인 Slurm Job**을 자동으로 생성하고 제출하는 방법입니다. 각 Job은 제출 시 전달받은 파라미터로 실행됩니다. Job Array와 달리 각 실험이 완전히 분리되어 관리됩니다.

---

### 4. 체계적인 실험 제출 (방법 1: Job Array 활용) ✨ (`4-jobarray_sbatch.sh`)

하이퍼파라미터 튜닝과 같이 **동일한 작업을 파라미터만 바꿔서 여러 번 실행**할 때 가장 **표준적이고 권장되는** 방법입니다. **하나의 `sbatch` 제출**로 **여러 개의 Task**를 생성하고 관리합니다.

*   **스크립트 살펴보기:** `cat 4-jobarray_sbatch.sh` 명령어로 내용을 확인해보세요.
    *   **`#SBATCH --array=1-4`**: 핵심! 1번부터 4번까지, 총 4개의 Task를 생성하라는 지시입니다. 이 Job은 하나의 Job ID를 공유하지만, 각 Task는 고유한 Task ID (1, 2, 3, 4)를 갖습니다.
    *   **`#SBATCH --output`, `--error`**: 로그 파일 이름에 `%A` (Array Job ID)와 **`%a` (Task ID)**를 넣어 각 Task의 로그가 별도로 저장되도록 설정할 수 있습니다. (`logs/systematic/%x-%A_%a.o`)
    *   **Bash 배열:** `learning_rates`, `batch_sizes` 배열에 튜닝할 파라미터 값들을 저장합니다.
    *   **`$SLURM_ARRAY_TASK_ID` 활용:** Slurm이 각 Task에게 자동으로 부여하는 이 환경 변수 값을 읽어옵니다.
    *   **파라미터 매핑:** Task ID (`$SLURM_ARRAY_TASK_ID`, 1부터 시작)를 배열 인덱스 (`$task_id - 1`, 0부터 시작)로 변환하여, 각 Task가 실행될 때 사용할 고유한 파라미터 값 (`current_lr`, `current_bs`)을 배열에서 가져옵니다.
    *   **실행:** 가져온 파라미터 값을 사용하여 실제 작업을 수행합니다 (여기서는 `echo`로 출력).

*   **스크립트 제출 및 확인:**
    ```bash
    # 파티션 이름, 노드 목록(--nodelist) 등을 랩 서버 환경에 맞게 수정했는지 확인!
    nano 4-jobarray_sbatch.sh # 필요시 수정
    sbatch 4-jobarray_sbatch.sh
    squeue -u $USER # 작업 상태 확인 (JOBID에 _[1-4] 또는 JOBID_1, JOBID_2 ... 형식 확인)
    # 잠시 기다린 후...
    ls -l logs/systematic/ # 로그 파일 생성 확인 
    cat logs/systematic/<로그파일명>.o # 로그 파일 내용 확인 (Task ID 별로 다른 파라미터 출력 확인)
    ```
*   **핵심:** **`--array` 옵션**으로 Task를 생성하고, 스크립트 내에서 **`$SLURM_ARRAY_TASK_ID`**를 이용해 각 Task의 동작(주로 파라미터)을 다르게 정의하는 것이 Job Array의 핵심 원리입니다! 하이퍼파라미터 튜닝에 매우 효율적입니다. 👍

---

### 5. 체계적인 실험 제출 (방법 2: 한 Job 내에서 여러 `srun` 병렬 실행) 👯 (`5-multiple_srun_sbatch.sh`, `5-srun_multiple.sh`)

**하나의 큰 Slurm Job 안에서 여러 개의 독립적인 (소규모) 실험들을 동시에 병렬로 실행**하는 고급 기법입니다. 제한된 시간 내에 많은 실험을 처리하거나, 큰 노드 할당을 효율적으로 사용하고 싶을 때 유용합니다. 스크립트가 다소 복잡해집니다! 😅 (이전 실습 자료의 4번 내용과 동일합니다.)

*   **스크립트 살펴보기:** (`cat 5-multiple_srun_sbatch.sh`)
    *   **대규모 자원 요청:** `#SBATCH -N <큰 숫자>` 로 모든 하위 실험에 필요한 노드를 한 번에 요청합니다.
    *   **복잡한 인자 파싱:** `-r`, `-w`, `-m` 같은 옵션으로 여러 하이퍼파라미터 값들을 콤마(,)로 구분하여 입력받고, 이를 파싱하는 함수들(`parse_arguments`, `split_hyperparameters` 등)이 포함되어 있습니다.
    *   **노드 정보 수집:** `srun ... hostname --ip-address` 등을 이용해 할당받은 **모든 노드의 정보(IP, 호스트명)를 미리 수집**하여 임시 파일(`TMP_SRUN_DIR`)에 저장합니다. (핵심!)
    *   **루프 및 노드 할당:** 하이퍼파라미터 조합을 순회하며, 각 하위 실험에 필요한 노드 수만큼 미리 수집된 노드 정보에서 **순차적으로 노드를 할당**합니다. (`ip_line = $(sed ...)` 부분)
    *   **백그라운드 `srun` 실행:** 각 하위 실험에 대해 `srun` 명령어를 실행하되, **맨 뒤에 `&`를 붙여 백그라운드로 실행**시킵니다! 이렇게 하면 다음 하위 실험 `srun`이 즉시 실행될 수 있습니다.
    *   **`wait` 명령어:** 모든 백그라운드 `srun` 작업이 끝날 때까지 메인 스크립트가 종료되지 않도록 기다립니다.
    *   **개별 로그:** 각 `srun` 명령어의 `--output`, `--error` 옵션에 파라미터 값을 포함시켜 로그 파일을 분리합니다.
    *   `5-srun_multiple.sh` 스크립트는 각 하위 실험의 Task에서 실행되며, 전달받은 파라미터를 사용합니다.

*   **실행 방법 및 확인:** (이 스크립트는 설정이 복잡하여 실제 제출보다는 구조 이해에 집중하는 것이 좋습니다.)
    ```bash
    # 스크립트 내부의 파티션, 노드 수 등을 매우 신중하게 설정해야 합니다!
    # 실제 제출보다는 아래처럼 파라미터를 직접 전달하며 실행 흐름을 보는 것이 유용할 수 있습니다.
    # (단, sbatch로 제출하지 않으면 SLURM 환경 변수가 없어서 일부 기능은 동작하지 않음)
    # bash 5-multiple_srun_sbatch.sh -n 1 -r 0.1,0.01 -w 0.1 -m 0.4

    # 실제 제출 예시 (2개 실험, 각 실험당 1노드 사용, 총 2노드 요청 가정)
    # nano 5-multiple_srun_sbatch.sh # 파티션, 노드 수 등 수정
    # sbatch --nodes=2 5-multiple_srun_sbatch.sh -n 1 -r 0.1,0.01 -w 0.1 -m 0.4

    # squeue 확인
    # 잠시 기다린 후 logs/multiple_srun/ 디렉토리 확인
    # ls -l logs/multiple_srun/
    # 각 로그 파일 확인
    ```
*   **핵심:** 하나의 큰 Slurm 자원 할당 내에서, 노드 정보를 직접 관리하고 `srun`을 백그라운드로 실행하여 **여러 독립 실험을 동시에 수행**하는 방법입니다. 스크립트 복잡도가 높지만 자원 활용률을 극대화할 수 있습니다. Job Array와는 다른 접근 방식입니다.

---

## 🎉 실습 완료! 🎉

축하합니다! Slurm 스크립트를 작성하고 제출하는 다양한 방법들을 함께 살펴보았습니다. 💪

**오늘 배운 것 복습:**

*   **기본:** 단일 작업 제출 및 확인 (`1-*.sh`)
*   **멀티노드:** `srun`을 이용한 분산 작업 실행 (`2-*.sh`)
*   **체계적 실험 (방법 1: 외부 스크립트):** 여러 독립 Job 제출 (`3-*.sh`)
*   **체계적 실험 (방법 2: Job Array):** 가장 표준적인 방법! (`4-*.sh`) ✨
*   **체계적 실험 (방법 3: 병렬 srun):** 한 Job 내에서 여러 실험 동시 실행 (`5-*.sh`)

이제 각 방법의 특징과 장단점을 이해하셨으니, 여러분의 연구 상황과 목적에 가장 적합한 방법을 선택하여 효율적으로 HPC 자원을 활용하실 수 있을 거예요! 😊 특히 **Job Array**는 하이퍼파라미터 튜닝 등 많은 경우에 가장 유용하게 사용될 수 있으니 꼭 기억해주세요!

궁금한 점이 있다면 언제든지 편하게 질문해주세요! 수고하셨습니다! 🥰
