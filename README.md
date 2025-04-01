## HPC Workshop

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
    1) 랩 서버 접속 후 git pull https://github.com/jubilant-choi/HPC_Workshop.git
    2) cd HPC_Workshop, chmod +x 0-setup.sh
    3) bash 0-setup.sh 실행
