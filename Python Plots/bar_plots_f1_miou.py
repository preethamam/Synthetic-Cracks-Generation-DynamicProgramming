import re
import numpy as np
import matplotlib.pyplot as plt

# 1) point to your three files
file_map = {
    'Cracks-200': '../Results/Text Files/jahan_LaTeX_table_entries.txt',
    'CDLN':  '../Results/Text Files/cdln_LaTeX_table_entries.txt',
    'DeepCrack':   '../Results/Text Files/liu_LaTeX_table_entries.txt',
}

# 2) parser (unchanged)
def parse_metric_scores(txt_path, metric_key):
    records = []
    with open(txt_path, 'r') as f:
        lines = [ln.strip() for ln in f if ln.strip()]
    current_class = None
    for idx, line in enumerate(lines):
        m = re.match(r'^Data class:\s*(.+)$', line)
        if m:
            current_class = m.group(1)
            continue
        m2 = re.match(r'^Algorithm type:\s*(.+)$', line)
        if m2 and current_class is not None:
            flt = m2.group(1)
            for j in range(idx+1, min(idx+8, len(lines))):
                if lines[j].startswith(metric_key):
                    parts = lines[j].split()
                    vals = list(map(float, parts[-3:]))
                    records.append((current_class, flt, vals))
                    break
    return records

# 3) build data_f1 and data_miou (unchanged)
data_f1   = {}
data_miou = {}
for ds_name, path in file_map.items():
    recs_f1   = parse_metric_scores(path, 'F1score')
    recs_miou = parse_metric_scores(path, 'MeanIoU')

    classes = []
    for dc, _, _ in recs_f1:
        if dc not in classes:
            classes.append(dc)
    filters = ['Hessian','MFAT','Morpho']

    arr_f1   = {f: [] for f in filters}
    arr_miou = {f: [] for f in filters}
    for dc in classes:
        for flt in filters:
            f1_vals   = next(vals for (c2,f2,vals) in recs_f1   if c2==dc and f2==flt)
            miou_vals = next(vals for (c2,f2,vals) in recs_miou if c2==dc and f2==flt)
            arr_f1[flt].append(f1_vals)
            arr_miou[flt].append(miou_vals)

    data_f1[ds_name]   = {flt: np.array(arr_f1[flt])   for flt in filters}
    data_miou[ds_name] = {flt: np.array(arr_miou[flt]) for flt in filters}

# 4) fixed labels & plotting params
classes     = ['TC 1','TC2 ','TC 3','TC 4','TC 5','TC 6']
datasets    = list(file_map.keys())
filters     = ['Hessian','MFAT','Morpho']
classifiers = ['ANN','K-NN','SVM']
hatches     = ['///', '...', 'xxx']
bar_w       = 0.25
x           = np.arange(len(classes))

# ─── Global font defaults (optional) ────────────────────────────────────
# You can still use these as fallbacks if you like
plt.rcParams.update({
    'font.size':        12,
    'axes.titlesize':   14,
    'axes.labelsize':   12,
    'xtick.labelsize':  10,
    'ytick.labelsize':  10,
    'legend.fontsize':  10,
    'figure.titlesize': 16,
})
# ────────────────────────────────────────────────────────────────────────

def plot_and_save(data_dict, metric_name, out_pdf):
    fig, axes = plt.subplots(3, 3, figsize=(12, 9), sharey=True)

    # 1) set uniform tick-label size on all subplots
    for ax in axes.flat:
        ax.tick_params(axis='both', which='major', labelsize=12)

    for i, ds in enumerate(datasets):
        for j, flt in enumerate(filters):
            ax = axes[i, j]
            arr = data_dict[ds][flt]

            legend_handles = None

            # 2) draw your bars exactly as before
            for k in range(3):
                bars = ax.bar(
                    x + k*bar_w,
                    arr[:, k],
                    width=bar_w,
                    hatch=hatches[k],
                    edgecolor='black',
                    linewidth=0.6,
                    label=classifiers[k] if (i, j) == (0, 0) else ""
                )
                if (i, j) == (0, 0):
                    legend_handles = legend_handles or []
                    legend_handles.append(bars[0])

            ax.set_xticks(x + bar_w)
            # no fontsize here—it uses tick_params above
            ax.set_xticklabels(classes, rotation=0, ha='center')

            # 3) explicitly size titles & labels on each Axes
            if flt == 'Hessian':
                flt = 'Vesselness'
            if i == 0:
                ax.set_title(flt, fontsize=14)              # larger title
            if j == 0:
                ax.set_ylabel(f"{ds}\n\n{metric_name}", fontsize=12)

            # legend only once
            if (i, j) == (0, 0):
                ax.legend(legend_handles, classifiers, ncol=3, loc='upper center', fontsize=10)

    # 4) size the figure-level axis labels
    fig.text(0.5, 0.04, "Test Cases", ha='center', fontsize=14)
    # fig.text(0.04, 0.5, metric_name, va='center', rotation='vertical', fontsize=14)

    # tight layout + save
    plt.tight_layout(rect=(0.05, 0.05, 1, 1))
    fig.savefig(out_pdf, format='pdf', bbox_inches='tight', pad_inches=0)
    plt.close(fig)
    print(f"Saved {out_pdf}")


# call it
plot_and_save(data_f1,   "F₁-score", "fig_f1_scores_v2.pdf")
plot_and_save(data_miou, "MeanIoU",    "fig_MeanIoU_v2.pdf")