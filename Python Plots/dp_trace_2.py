import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, Rectangle

def compute_vertical_seam_dp(energy):
    """
    Compute cumulative energy and back‑pointers for a vertical seam.
    Returns cumulative_cost, backtrack (same shape as energy).
    backtrack[i, j] stores the column index in row i‑1 that leads to (i, j).
    """
    h, w = energy.shape
    cumulative = energy.copy().astype(float)
    backtrack = np.zeros_like(energy, dtype=int)

    # First row already initialised
    for i in range(1, h):
        for j in range(w):
            # handle edge boundaries
            prev_cols = [j]
            if j > 0:
                prev_cols.append(j - 1)
            if j < w - 1:
                prev_cols.append(j + 1)

            # find col with minimal cumulative energy above
            costs = [(cumulative[i - 1, pc], pc) for pc in prev_cols]
            min_cost, min_col = min(costs, key=lambda t: t[0])

            cumulative[i, j] += min_cost
            backtrack[i, j] = min_col

    return cumulative, backtrack

def trace_seam(backtrack, cumulative):
    """
    Reconstruct optimal seam (row, col) list from backtrack.
    """
    h, w = backtrack.shape
    # start from minimal in last row
    j = np.argmin(cumulative[-1])
    seam = [(h - 1, j)]
    for i in range(h - 1, 0, -1):
        j = backtrack[i, j]
        seam.append((i - 1, j))
    seam.reverse()
    return seam

def plot_dp_process(energy):
    cumulative, backtrack = compute_vertical_seam_dp(energy)
    seam = trace_seam(backtrack, cumulative)

    h, w = energy.shape
    fig, ax = plt.subplots(figsize=(w * 1.2, h * 1.2))
    
    ax.set_xlim(0, w)
    ax.set_ylim(0, h)
    ax.set_aspect('equal')
    ax.invert_yaxis()  # origin at top‑left
    ax.axis('off')

    # Draw grid with values
    for i in range(h):
        for j in range(w):
            # rectangle
            ax.add_patch(Rectangle((j, i), 1, 1, fill=False, linewidth=2, edgecolor='black'))
            # energy (top‑left, red‑ish)
            ax.text(j + 0.05, i + 0.25, str(energy[i, j]), fontsize=28, ha='left', va='center', color='tab:red')
            # cumulative (center)
            ax.text(j + 0.5, i + 0.75, str(int(cumulative[i, j])), fontsize=28, ha='center', va='center')

    # Draw DP arrows
    for i in range(1, h):
        for j in range(w):
            prev_j = backtrack[i, j]
            start = (prev_j + 0.5, i - 1 + 0.5)
            end = (j + 0.5, i + 0.5)
            arrow = FancyArrowPatch(start, end,
                                    arrowstyle='->',
                                    color='blue',
                                    mutation_scale=40,
                                    linewidth=5)
            ax.add_patch(arrow)

    # Highlight seam
    seam_x = [j + 0.5 for (_, j) in seam]
    seam_y = [i + 0.5 for (i, _) in seam]
    ax.plot(seam_x, seam_y, linewidth=6, color='green', label='Optimal Strand')
    ax.legend(bbox_to_anchor=(0., 1.05), loc='upper left', borderaxespad=0., fontsize=14)

    border_lw = 8                      # make it the visual thickness you like
    ax.add_patch(Rectangle((0, 0),     # bottom-left corner
                       w, h,       # width, height
                       fill=False,
                       linewidth=border_lw,
                       edgecolor='black',
                       zorder=10)) # on top of other lines

    # ── NEW → maximise the window (best-effort) before saving ─────────────
    mng = plt.get_current_fig_manager()
    try:                       # Qt5/6 back-ends
        mng.window.showMaximized()
    except AttributeError:
        try:                   # TkAgg back-end
            mng.window.state('zoomed')
        except AttributeError: # headless / others
            # double canvas size as fallback
            w0, h0 = fig.get_size_inches()
            fig.set_size_inches(w0 * 2, h0 * 2, forward=True)

    fig.canvas.draw_idle()     # let the renderer update
    plt.pause(0.1)            # tiny delay (100 ms) is enough

    # ── NEW → zero inner margins, hair-line outer padding, then save ─────
    fig.savefig("strand_dp.pdf", bbox_inches='tight', pad_inches=0.03)

    plt.show()
    
# ------------------ Example usage ------------------
np.random.seed(13)  # 13, 15
grid_size = (6, 6)   # (rows, cols)
energy = np.random.randint(1, 10, size=grid_size)
plot_dp_process(energy)