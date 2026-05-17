# difficulty_analyzer.py
# mesure la difficulte d'un puzzle 3D ASP en fonction de 4 criteres :
#   - volume de la grille (length * height * depth)
#   - nombre de types de pieces differents utilises
#   - nombre total de blocs a placer
#   - temps de resolution clingo

from __future__ import annotations
import subprocess, time, re, os, json, tempfile
from dataclasses import dataclass, asdict
from typing import Optional, List, Tuple, Dict


# on normalise chaque critere entre 0 et 1 avant de les combiner.
# ces max sont a ajuster selon vos instances reelles.
# ex: 144 / 180 = 0.80 donc un 6x6x4 sera a ~80% pour le volume
NORM_MAX = {
    "grid_volume":   180,
    "active_types":   20,
    "total_blocks":   50,
    "solve_time_ms": 60000,
}

# poids de chaque critere, doit sommer a 1.0
WEIGHTS = {
    "grid_volume":   0.30,
    "active_types":  0.25,
    "total_blocks":  0.20,
    "solve_time_ms": 0.25,
}

LEVELS = [
    (0.00, 0.20, 1, "Very Easy"),
    (0.20, 0.40, 2, "Easy"),
    (0.40, 0.60, 3, "Medium"),
    (0.60, 0.80, 4, "Hard"),
    (0.80, 1.01, 5, "Harder"),
]


@dataclass
class Piece:
    pid: int
    cells: List[Tuple[int, int, int]]
    size: int
    score: int
    pick_times: int


@dataclass
class Instance:
    length: int
    height: int
    depth: int
    pieces: List[Piece]
    total_blocks: int
    db_path: str


@dataclass
class PuzzleMetrics:
    name: str
    grid: str

    grid_volume: int = 0
    active_types: int = 0
    total_blocks: int = 0   # nb de anchor() dans la solution
    solve_time_ms: float = 0.0

    satisfiable: bool = True
    models_found: int = 0
    timed_out: bool = False

    score: float = 0.0
    level: int = 0
    label: str = ""


def parse_db(path: str) -> Instance:
    with open(path) as f:
        content = f.read()

    def get_int(pat, default=0):
        m = re.search(pat, content)
        return int(m.group(1)) if m else default

    length = get_int(r'\blength\((\d+)\)')
    height = get_int(r'\bheight\((\d+)\)')
    depth  = get_int(r'\bdepth\((\d+)\)')
    total_blocks = get_int(r'\btotal_blocks\((\d+)\)')

    cells_by_pid: Dict[int, list] = {}
    for m in re.finditer(r'\bpiece\((\d+),\s*(-?\d+),\s*(-?\d+),\s*(-?\d+)\)', content):
        pid = int(m.group(1))
        cells_by_pid.setdefault(pid, []).append(
            (int(m.group(2)), int(m.group(3)), int(m.group(4)))
        )

    sizes  = {int(m.group(1)): int(m.group(2))
              for m in re.finditer(r'\bpiece_size\((\d+),\s*(\d+)\)', content)}
    scores = {int(m.group(1)): int(m.group(2))
              for m in re.finditer(r'\bpiece_score\((\d+),\s*(\d+)\)', content)}
    picks  = {int(m.group(1)): int(m.group(2))
              for m in re.finditer(r'\bpick_times\((\d+),\s*(\d+)\)', content)}

    pieces = [
        Piece(pid=pid, cells=cells,
              size=sizes.get(pid, len(cells)),
              score=scores.get(pid, 0),
              pick_times=picks.get(pid, 0))
        for pid, cells in sorted(cells_by_pid.items())
    ]

    return Instance(length=length, height=height, depth=depth,
                    pieces=pieces, total_blocks=total_blocks, db_path=path)


def find_clingo() -> Optional[str]:
    for c in ("clingo", "clingo5", "/usr/bin/clingo", "/usr/local/bin/clingo"):
        try:
            subprocess.run([c, "--version"], capture_output=True, check=True)
            return c
        except (FileNotFoundError, subprocess.CalledProcessError):
            pass
    return None


def run_clingo(lp_path: str, db_path: str, timeout: float = 60.0) -> dict:
    res = dict(solve_time_ms=0.0, distinct_bids=0, satisfiable=True, models_found=0, timed_out=False)

    clingo = find_clingo()
    if clingo is None:
        print("  [!] clingo introuvable, on simule les temps")
        return _fake_run(lp_path, db_path, res)

    cmd = [clingo, lp_path, db_path, "--models=1", f"--time-limit={int(timeout)}"]
    t0 = time.perf_counter()
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout + 5)
        res["solve_time_ms"] = (time.perf_counter() - t0) * 1000
        out = proc.stdout + proc.stderr

        # on cherche uniquement dans la ligne du modele (apres "Answer:")
        answer_match = re.search(r'Answer\s*:\s*\d+[^\n]*\n(.*)', out)
        answer_line = answer_match.group(1) if answer_match else out
        bids = set(re.findall(r'\bplaced\(\d+,\s*\d+,\s*\d+,\s*(\d+)\s*\)', answer_line))
        res["distinct_bids"] = len(bids)

        m = re.search(r'Models\s*:\s*(\d+)', out, re.IGNORECASE)
        if m:
            res["models_found"] = int(m.group(1))

        if "UNSATISFIABLE" in out:
            res["satisfiable"] = False
        if "TIME LIMIT" in out or "INTERRUPTED" in out:
            res["timed_out"] = True
            res["solve_time_ms"] = timeout * 1000

    except subprocess.TimeoutExpired:
        res["solve_time_ms"] = timeout * 1000
        res["timed_out"] = True

    return res


def _fake_run(lp_path: str, db_path: str, res: dict) -> dict:
    # approximation grossiere basee sur la taille des fichiers
    import random
    size = sum(os.path.getsize(p) for p in (lp_path, db_path) if os.path.exists(p))
    scale = max(1.0, size / 1500)
    res["solve_time_ms"]  = round(scale ** 1.5 * 200 * (0.8 + random.random() * 0.4), 1)
    res["distinct_bids"]  = int(scale * 4 * (0.8 + random.random() * 0.4))
    res["models_found"]   = 1
    return res


def compute_score(m: PuzzleMetrics) -> float:
    vals = {
        "grid_volume":   m.grid_volume,
        "active_types":  m.active_types,
        "total_blocks":  m.total_blocks,
        "solve_time_ms": m.solve_time_ms,
    }
    total = 0.0
    for k, w in WEIGHTS.items():
        total += w * min(vals[k] / NORM_MAX[k], 1.0)
    return round(min(total, 1.0), 4)


def classify(score: float) -> Tuple[int, str]:
    for lo, hi, lvl, lbl in LEVELS:
        if lo <= score < hi:
            return lvl, lbl
    return 5, "Harder"


def analyze(lp_path: str, db_path: str, timeout: float = 60.0, name: str = "") -> PuzzleMetrics:
    inst = parse_db(db_path)
    clingo = run_clingo(lp_path, db_path, timeout)
    active = sum(1 for p in inst.pieces if p.pick_times > 0)

    m = PuzzleMetrics(
        name  = name or os.path.basename(db_path),
        grid  = f"{inst.length}x{inst.height}x{inst.depth}",

        grid_volume   = inst.length * inst.height * inst.depth,
        active_types  = active,
        total_blocks  = inst.total_blocks,
        solve_time_ms = clingo["solve_time_ms"],

        satisfiable  = clingo["satisfiable"],
        models_found = clingo["models_found"],
        timed_out    = clingo["timed_out"],
    )
    m.score = compute_score(m)
    m.level, m.label = classify(m.score)
    return m


STARS = {1: "★☆☆☆☆", 2: "★★☆☆☆", 3: "★★★☆☆", 4: "★★★★☆", 5: "★★★★★"}

def _bar(v: float, w: int = 30) -> str:
    n = int(round(v * w))
    return "█" * n + "░" * (w - n)

def print_report(m: PuzzleMetrics) -> None:
    sep = "-" * 64
    print(sep)
    print(f"  {m.name}   ({m.grid})")
    print(f"  satisfiable: {'oui' if m.satisfiable else 'non'}   "
          f"timeout: {'oui' if m.timed_out else 'non'}   "
          f"modeles: {m.models_found}")
    print(sep)
    print(f"  {'critere':<32} {'valeur':>10}   {'%':>6}  barre")
    print(f"  {'-'*32} {'-'*10}   {'-'*6}  {'-'*30}")

    rows = [
        ("volume grille (L x H x D)",
         f"{m.grid_volume}  ({m.grid})",
         min(m.grid_volume / NORM_MAX['grid_volume'], 1.0)),
        ("types de pieces actifs",
         str(m.active_types),
         min(m.active_types / NORM_MAX['active_types'], 1.0)),
        ("total blocs a placer",
         str(m.total_blocks),
         min(m.total_blocks / NORM_MAX['total_blocks'], 1.0)),
        ("temps resolution (ms)",
         f"{m.solve_time_ms:.1f}",
         min(m.solve_time_ms / NORM_MAX['solve_time_ms'], 1.0)),
    ]
    for lbl, val, norm in rows:
        print(f"  {lbl:<32} {val:>10}   {norm:>5.1%}  {_bar(norm)}")

    print(sep)
    print(f"  score : {m.score:.4f}   {_bar(m.score)}")
    print(f"  niveau: {m.level}  {STARS[m.level]}  {m.label}")
    print(sep)
    print()


def make_variant(base_db: str, out_path: str,
                 pick_scale: float = 1.0,
                 grid: Optional[Tuple[int, int, int]] = None) -> str:
    inst = parse_db(base_db)
    L, H, D = grid if grid else (inst.length, inst.height, inst.depth)

    lines = [f"length({L}).", f"height({H}).", f"depth({D})."]
    new_total = 0
    for p in inst.pieces:
        pt = max(0, round(p.pick_times * pick_scale))
        new_total += pt
        for x, y, z in p.cells:
            lines.append(f"piece({p.pid}, {x}, {y}, {z}).")
        lines.append(f"piece_size({p.pid}, {p.size}).")
        lines.append(f"piece_score({p.pid}, {p.score}).")
        lines.append(f"pick_times({p.pid}, {pt}).")
        lines.append("")
    lines.append(f"total_blocks({new_total}).")

    with open(out_path, "w") as f:
        f.write("\n".join(lines))
    return out_path


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="analyse la difficulte d'un puzzle 3D ASP")
    parser.add_argument("lp", help="fichier .lp")
    parser.add_argument("db", help="fichier .db (instance)")
    parser.add_argument("--variants", action="store_true",
                        help="genere 5 variantes de difficulte croissante")
    parser.add_argument("--json", default="", help="export JSON")
    parser.add_argument("--timeout", type=float, default=60.0)
    args = parser.parse_args()

    print("\n--- block puzzle difficulty analyzer ---\n")

    results: List[PuzzleMetrics] = []

    if args.variants:
        configs = [
            (0.25, (4, 4, 2), "very_easy"),
            (0.50, (5, 5, 3), "easy"),
            (1.00, None,      "medium"),
            (1.40, None,      "hard"),
            (1.80, None,      "harder"),
        ]
        tmpdir = tempfile.mkdtemp()
        for scale, grid, label in configs:
            out_db = os.path.join(tmpdir, f"{label}.db")
            make_variant(args.db, out_db, pick_scale=scale, grid=grid)
            g = f"{grid[0]}x{grid[1]}x{grid[2]}" if grid else "grille originale"
            print(f"variante '{label}'  (scale={scale}, {g})")
            m = analyze(args.lp, out_db, timeout=args.timeout, name=label)
            results.append(m)
            print_report(m)
    else:
        m = analyze(args.lp, args.db, timeout=args.timeout)
        results.append(m)
        print_report(m)

    if len(results) > 1:
        print("-" * 64)
        print(f"  {'nom':<18} {'grille':>8} {'vol':>5} {'types':>6} {'blocs':>6} {'ms':>8} {'score':>7}  niveau")
        print("  " + "-" * 60)
        for m in results:
            print(f"  {m.name:<18} {m.grid:>8} {m.grid_volume:>5} "
                  f"{m.active_types:>6} {m.total_blocks:>6} "
                  f"{m.solve_time_ms:>8.0f} {m.score:>7.4f}  [{m.level}] {m.label}")
        print("-" * 64 + "\n")

    if args.json:
        with open(args.json, "w") as f:
            json.dump([asdict(m) for m in results], f, indent=2)
        print(f"rapport sauvegarde -> {args.json}\n")


if __name__ == "__main__":
    main()
