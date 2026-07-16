import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, Rectangle

def plot_seam_dp(r, c, seed=None):
    """
    Visualise dynamic-programming for a *vertical* seam on an (r×c) grid.
      • r, c – rows and columns
      • seed – optional RNG seed to keep the same numbers every run
    """
    if seed is not None:
        np.random.seed(seed)
    energy   = np.random.randint(1, 10, size=(r, c))
    cumul, bt = _cumulative_dp(energy)
    seam      = _trace_seam(bt, cumul)

    fig, ax = plt.subplots(figsize=(c * 1.2, r * 1.2))
    ax.set_xlim(0, c); ax.set_ylim(0, r)
    ax.set_aspect("equal"); ax.invert_yaxis(); ax.axis("off")

    # 1) draw grid, red energies, black cumulatives
    for i in range(r):
        for j in range(c):
            ax.add_patch(Rectangle((j, i), 1, 1, fill=False))
            ax.text(j + .05, i + .25, f"{energy[i,j]}",  color="tab:red",
                    fontsize=12, ha="left",  va="center")
            ax.text(j + .5,  i + .75, f"{int(cumul[i,j])}",
                    fontsize=12, ha="center", va="center")

    # 2) add every DP arrow
    for i in range(1, r):
        for j in range(c):
            pj = bt[i, j]
            start, end = (pj+.5, i-1+.5), (j+.5, i+.5)
            ax.add_patch(FancyArrowPatch(start, end, arrowstyle="->",
                                         mutation_scale=10, linewidth=1))

    # 3) highlight optimal seam
    xs = [j+.5 for (i,j) in seam]
    ys = [i+.5 for (i,j) in seam]
    ax.plot(xs, ys, linewidth=4)

    plt.show()


# ───────────────────────────────── internal helpers ─────────────────────────
def _cumulative_dp(e):
    h, w = e.shape
    c = e.astype(float).copy()
    bt  = np.zeros_like(e, int)
    for i in range(1, h):
        for j in range(w):
            nbrs = [j] + ([j-1] if j else []) + ([j+1] if j < w-1 else [])
            idx  = min(nbrs, key=lambda k: c[i-1, k])
            c[i, j] += c[i-1, idx]
            bt[i, j] = idx
    return c, bt

def _trace_seam(bt, c):
    h, _ = bt.shape
    j = c[-1].argmin()
    seam = [(h-1, j)]
    for i in range(h-1, 0, -1):
        j = bt[i, j]
        seam.append((i-1, j))
    return seam[::-1]

if __name__ == "__main__":
    plot_seam_dp(r=4, c=6, seed=0)   # makes exactly the demo above
    # plot_seam_dp(8, 8)               # any size you like