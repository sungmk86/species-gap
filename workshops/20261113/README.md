# 2026-11-13 로제타 실습 1: 점수 하나 보기

시간은 2시간이다. 끝날 때 각자 화면에 숫자 두 개가 나오면 성공이다.
하나는 아미노산 개수, 하나는 로제타 점수다.

설치는 실습 중에 하지 않는다. `imac1`이라는 공용 컴퓨터에 미리 해 둔다.
당일에는 그 설치에 어떤 명령을 쳤는지만 함께 본다.

이 폴더에는 실습 계획만 둔다. 신청서, 예산, 비밀번호, 개인 정보는 적지 않는다.

## 오늘 하는 일

로제타는 네 가지 일을 한다. 오늘은 첫 번째만 한다.

| 하는 일 | 쉬운 뜻 | 오늘 |
| --- | --- | --- |
| 점수 보기 | 이 단백질 모양이 계산 안에서 얼마나 안정한지 숫자로 본다 | 한다 |
| 다듬기 (FastRelax) | 원자 위치를 살짝 옮겨 점수를 낮춘다 | 대표 한 명만, 시간이 남을 때 |
| 글자 하나 바꾸기 | 아미노산 하나를 바꿨을 때 점수가 얼마나 달라지는지 본다 | 안 한다 |
| 붙는 위치 찾기 | 두 분자가 어디에 붙는지 후보를 만든다 | 안 한다 |

점수는 실험실에서 잰 값이 아니다. 같은 단백질을, 같은 방법으로 계산한 숫자끼리만 비교한다.

실습 파일은 유비퀴틴이다. PDB 파일 이름은 `1UBQ`다. 아미노산이 76개라서 오래 걸리지 않는다.

## 시간

| 시간 | 하는 일 | 여기까지 되면 통과 |
| --- | --- | --- |
| 0:00–0:15 | 점수란 무엇인지 듣는다 | 다른 단백질의 총점끼리는 순위를 매기지 않는다고 말할 수 있다 |
| 0:15–0:30 | 설치 기록을 함께 본다. 다시 설치하지는 않는다 | 설치가 `imac1`에 이미 끝났다는 것을 안다 |
| 0:30–1:00 | 각자 노트북에서 `imac1`에 접속한다 | `ssh` 접속 뒤 이름 프롬프트가 보인다 |
| 1:00–1:40 | `1UBQ`를 받아 점수를 출력한다 | 화면에 `residues 76`과 점수 숫자가 나온다 |
| 1:40–2:00 | 숫자를 적고, 다음 시간을 듣는다 | 세 줄을 노트에 남긴다. 잔기 수, 점수, 날짜 |

설치 확인이 1시를 넘기면 다듬기는 하지 않는다. 오늘 꼭 필요한 결과는 `1UBQ` 점수다.

## 각자 노트북에서 imac1에 들어오려면

계산은 `imac1` 안에서 돌아간다. 노트북은 그 컴퓨터에 글을 보내고 화면을 받아 오는 창이다.

각자 준비할 것은 네 가지다.

1. 노트북. 윈도우여도 되고 맥이어도 된다.
2. `imac1`과 같은 연구실 와이파이, 또는 같은 랜선 네트워크. 집에서는 이 컴퓨터가 보이지 않는다.
3. 글자 창. 맥은 `터미널` 앱이다. 윈도우는 `PowerShell`이다. 둘 다 `ssh`가 이미 들어 있다. 새로 깔지 않는다.
4. 담당자가 알려 주는 세 가지. 주소, 아이디, 비밀번호. 비밀번호는 이 문서에 적지 않는다.

주소는 컴퓨터 이름일 수도 있고, `192.168`로 시작하는 번호일 수도 있다. 당일 칠판에 적힌 것을 그대로 친다.

맥 터미널 또는 윈도우 PowerShell에 이 한 줄을 친다. `내아이디`와 `주소`만 바꾼다.

```text
ssh 내아이디@주소
```

처음 한 번은 `Are you sure you want to continue connecting?`이라고 묻는다. `yes`를 치고 Enter를 누른다. 그다음 비밀번호를 친다. 칠 때 화면에 글자가 안 보여도 정상이다. Enter를 누른다.

들어왔으면 프롬프트가 `imac1` 쪽으로 바뀐다. 여기서부터 치는 명령은 노트북이 아니라 `imac1`에서 실행된다.

`imac1` 쪽에는 실습 전에 이것들이 켜져 있어야 한다. 참가자가 하는 일이 아니다.

- 전원이 켜져 있고, 우분투 화면이 떠 있다.
- SSH 서버가 켜져 있다. 밖에서 `ssh`로 들어올 수 있다.
- 사람마다 계정이 하나씩 있다. 계정은 담당자에게 받는다.
- 아래 설치 기록의 파이썬으로 `import pyrosetta`가 된다.

각자 다른 아이디로 들어온다. 같은 아이디로 여러 명이 들어가면 파일을 서로 덮어쓴다.

## 설치 기록

이 명령은 `imac1`에 미리 한 번만 친 것이다. 실습 시간에 따라 치지 않는다. 화면으로 어떤 순서였는지만 본다.

우분투 종류와 CPU를 먼저 확인했다.

```text
lsb_release -a
uname -m
```

`uname -m` 결과가 `x86_64`여야 지금 받는 PyRosetta 파일이 맞다.

그다음 공용 폴더에 파이썬 환경을 만들고 PyRosetta를 넣었다.

```text
sudo apt update
sudo apt install -y python3-pip python3-venv openssh-server
sudo python3 -m venv /opt/pyrosetta
sudo /opt/pyrosetta/bin/pip install -U pip
sudo /opt/pyrosetta/bin/pip install pyrosetta --find-links https://west.rosettacommons.org/pyrosetta/quarterly/release
sudo chmod -R a+rX /opt/pyrosetta
```

대학에서 연구로 쓰는 것은 무료다. 회사 일은 유료 허락이 필요하다.

설치가 되었는지 확인하는 명령이다. 실습 시작 때 각자 한 번씩 쳐 본다. 설치를 다시 하지는 않는다.

```text
/opt/pyrosetta/bin/python -c "import pyrosetta; pyrosetta.init('-mute all'); print('ok')"
```

`ok`가 나오면 다음 실습으로 간다.

## 실습

`imac1`에 들어온 뒤, 내 폴더를 만들고 그 안으로 들어간다.

```text
mkdir -p ~/workshop-20261113
cd ~/workshop-20261113
```

유비퀴틴 파일을 받는다.

```text
wget https://files.rcsb.org/download/1UBQ.pdb -O 1ubq.pdb
```

점수를 계산한다.

```python
/opt/pyrosetta/bin/python - <<'PY'
import pyrosetta
pyrosetta.init("-mute all")
pose = pyrosetta.pose_from_pdb("1ubq.pdb")
scorefxn = pyrosetta.get_score_function()
print("residues", pose.total_residue())
print("score_REU", scorefxn(pose))
print("version", pyrosetta.version())
PY
```

나오는 세 줄을 노트에 적는다.

- `residues` 는 76이어야 한다.
- `score_REU` 는 점수다.
- `version` 은 설치된 PyRosetta 판 번호다.

친구와 점수가 조금 달라도, 판 번호가 같으면 같은 계산이다. 판 번호가 다르면 숫자를 한 표에 섞지 않는다.

다듬기는 대표 한 명만 한다. 오래된 컴퓨터라서 여러 명이 동시에 하면 멈춘 것처럼 보인다.

```python
/opt/pyrosetta/bin/python - <<'PY'
import pyrosetta
from pyrosetta.rosetta.protocols.relax import FastRelax
pyrosetta.init("-mute all")
pose = pyrosetta.pose_from_pdb("1ubq.pdb")
scorefxn = pyrosetta.get_score_function()
relax = FastRelax()
relax.set_scorefxn(scorefxn)
relax.apply(pose)
pose.dump_pdb("1ubq_relax.pdb")
print("score_REU_after_relax", scorefxn(pose))
PY
```

## 안 될 때

| 보이는 것 | 이렇게 한다 |
| --- | --- |
| `Could not resolve hostname` | 칠판의 주소를 다시 본다. 연구실 와이파이에 붙어 있는지 확인한다 |
| `Connection refused` 또는 오래 기다림 | `imac1` 전원과 SSH 서버를 담당자에게 확인한다 |
| `Permission denied` | 아이디와 비밀번호를 다시 받는다. 비밀번호는 쳐도 화면에 안 나온다 |
| `No module named pyrosetta` | `/opt/pyrosetta/bin/python` 으로 실행했는지 확인한다. `python` 만 치면 다른 파이썬이 열린다 |
| `1ubq.pdb` 를 못 찾음 | `cd ~/workshop-20261113` 을 먼저 쳤는지 확인한다 |
| 명령이 한참 멈춤 | 점수 계산은 짧다. 다듬기를 여러 명이 동시에 돌리고 있으면 그것 때문이다 |

나갈 때는 `exit` 를 친다.

## 다음 시간

다음에도 `imac1`에 접속한다. Furin을 두 개 만든다. 하나는 그대로 두고, 하나는 A408부터 S421까지 루프를 뺀다. 둘을 같은 방법으로 한 번씩 다듬고, 그 두 점수만 비교한다.

애드진 주문과 DNA 합성은 이 실습에 넣지 않는다.
