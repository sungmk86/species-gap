# 2026-11-13 — Rosetta practical 1: score one structure

First lab workshop. Two hours. Everyone leaves with one Rosetta score
on screen. No local install.

This folder is the session plan and the commands to run. Do not add
Brain Pool forms, budgets, or personal data here.

## Who and what

Lab members who have not run Rosetta. A laptop with Chrome is enough.
Windows, Mac, and Linux all use the same Colab notebook.

Rosetta does four jobs. This session does only the first.

| Job | What it answers | This session |
| --- | --- | --- |
| Score | How favorable is this structure under the Rosetta energy function? | Yes |
| FastRelax | Can a short refinement lower that score? | One optional model, if install finished |
| Point-mutation ΔΔG | Did one amino-acid change help or hurt? | No |
| Docking or loop modeling | Where do two molecules sit, or how does a missing loop look? | No |

The score is in Rosetta energy units (REU). A lower number is more
favorable inside that calculation. It is not a measured ΔG. Compare
scores only when the protein, the score function, and the protocol are
the same.

## Why this protein

Live exercise: ubiquitin, PDB `1UBQ`, 76 residues. It downloads in
seconds and scores in seconds, so the group can finish together.

Optional second file, same commands: mouse furin ectodomain, PDB
`1P8J`. That is the lab's enzyme project, not the human construct with
the MBP tag and the A408–S421 loop deletion. Do not compare the `1UBQ`
total score with the `1P8J` total score. They are different proteins.

## Schedule

| Time | Block | Done when |
| --- | --- | --- |
| 0:00–0:15 | The four jobs above, and what a score is not | Someone can say why two total scores from different proteins are not ranked against each other |
| 0:15–0:45 | Colab install | `import pyrosetta` runs |
| 0:45–1:20 | Download `1UBQ` and print residue count plus score | Every person has a number |
| 1:20–1:40 | Optional FastRelax, one model | A second PDB and a second score exist |
| 1:40–2:00 | Read the two scores. Preview the next session | The group can name the next furin question |

If the install is still running at 0:45, skip FastRelax. The required
result is the `1UBQ` score.

## Colab setup

1. Open Chrome.
2. Open a new notebook at https://colab.research.google.com/
3. Paste the install cell and run it. The official PyRosetta teaching
   notebook sometimes has parentheses after `pyrosettacolabsetup`.
   Do not type those parentheses. Use the cell below.

Official teaching notebook, for reference only:

https://colab.research.google.com/github/RosettaCommons/PyRosetta.notebooks/blob/master/notebooks/01.00-How-to-Get-Started.ipynb

Install cell:

```python
!pip install pyrosetta --find-links https://west.rosettacommons.org/pyrosetta/quarterly/release
```

PyRosetta is free for academic non-commercial use. A paid license is
required for company work, including fee-for-service work inside a
university. Restarting the Colab runtime deletes the install. Run the
install cell again.

Do not run `pip install pyrosetta` in Windows PowerShell. PyRosetta on
Windows is supported through Ubuntu on WSL, or through Colab. This
session uses Colab so nobody needs that setup.

## Exercise

Paste this as the second cell. It downloads `1UBQ`, scores it, and
prints the residue count beside the score.

```python
import urllib.request
import pyrosetta

urllib.request.urlretrieve(
    "https://files.rcsb.org/download/1UBQ.pdb", "1ubq.pdb"
)
pyrosetta.init("-mute all")
pose = pyrosetta.pose_from_pdb("1ubq.pdb")
scorefxn = pyrosetta.get_score_function()
print("residues", pose.total_residue())
print("score_REU", scorefxn(pose))
```

Expected result: `residues 76`, then one score. The score will not
match a classmate's score if the PyRosetta build differs. Record the
build too:

```python
import pyrosetta
print(pyrosetta.version())
```

Write down three lines: residue count, score, PyRosetta version.

Optional FastRelax cell. Run it only after the score cell works.
`1UBQ` is small enough for one model.

```python
from pyrosetta.rosetta.protocols.relax import FastRelax

relax = FastRelax()
relax.set_scorefxn(scorefxn)
relax.apply(pose)
pose.dump_pdb("1ubq_relax.pdb")
print("residues", pose.total_residue())
print("score_REU_after_relax", scorefxn(pose))
```

Download `1ubq_relax.pdb` from the Colab file browser before closing
the tab. Colab deletes the file with the runtime.

Optional same-day check, same cells, with `1P8J.pdb` and
`https://files.rcsb.org/download/1P8J.pdb`. Record it in a second row.
Do not subtract it from the ubiquitin score.

## If it fails

| What you see | What to do |
| --- | --- |
| `No matching distribution` on pip | Confirm the notebook runtime is Python 3, then rerun the install cell. Do not switch to PowerShell |
| Install cell has `pyrosettacolabsetup()` | Delete the parentheses |
| Runtime restarted and `import pyrosetta` fails | Rerun the install cell |
| Score cell cannot find the PDB | The download cell and the score cell must use the same filename |
| Two people want to rank different proteins by the total score | Stop. Compare per-residue only as a rough note, and only after writing down the residue counts |

## After the session

Each person keeps three lines for `1UBQ`: residues, score, version.
Anyone who finished `1P8J` keeps a second row and does not rank the two
totals.

Next session, separate folder: build the furin ectodomain twice in
PyRosetta, once intact and once without A408–S421, relax each once,
and compare those two scores. That pair is the same protein and the
same protocol, so the comparison is allowed. Gene synthesis and
Addgene orders are not part of that session.

## Local install, not used today

Use this only after the same PDB will be scored many times, or when
the structure cannot be uploaded. On Mac or Linux:

```text
pip install pyrosetta --find-links https://west.rosettacommons.org/pyrosetta/quarterly/release
```

The quarterly wheel is the reproducible build. `pyrosetta-installer`
tracks weekly builds that are not kept. On Windows, run that command
inside Ubuntu on WSL, not in PowerShell.
