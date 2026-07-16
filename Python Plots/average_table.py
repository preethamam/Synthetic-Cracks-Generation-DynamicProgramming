import re
import numpy as np

# 1) point to your three files
file_map = {
    'Jahan': '../Results/Text Files/jahan_LaTeX_table_entries.txt',
    'CDLN':  '../Results/Text Files/cdln_LaTeX_table_entries.txt',
    'Liu':   '../Results/Text Files/liu_LaTeX_table_entries.txt',
}

metrics_keys = ['Precision', 'Recall', 'F1score', 'MeanIoU']
filters      = ['Hessian','MFAT','Morpho']
classifiers  = ['ANN','K-NN','SVM']

def parse_all_metrics(txt_path):
    """
    Returns a dict:
      data[class_name][filter_name][metric_key] = [val_ann, val_knn, val_svm]
    """
    data = {}
    with open(txt_path, 'r') as f:
        lines = [ln.strip() for ln in f if ln.strip()]
    current_class = None
    for idx, line in enumerate(lines):
        m = re.match(r'^Data class:\s*(.+)$', line)
        if m:
            current_class = m.group(1)
            data.setdefault(current_class, {})
            continue

        m2 = re.match(r'^Algorithm type:\s*(.+)$', line)
        if m2 and current_class:
            flt = m2.group(1)
            data[current_class].setdefault(flt, {})
            # for each metric, look ahead a few lines
            for metric in metrics_keys:
                for j in range(idx+1, min(idx+8, len(lines))):
                    if lines[j].startswith(metric):
                        parts = lines[j].split()
                        vals  = list(map(float, parts[-3:]))
                        data[current_class][flt][metric] = vals
                        break
    return data

# 2) parse all three datasets
all_data = {ds: parse_all_metrics(path) for ds,path in file_map.items()}

# 3) collect the six data-classes in order of appearance in Jahan
data_classes = list(all_data['Jahan'].keys())

# 4) compute averages across datasets
avg_data = {}
for dc in data_classes:
    avg_data[dc] = {}
    for flt in filters:
        avg_data[dc][flt] = {}
        for metric in metrics_keys:
            # gather a (3×3) array: datasets × classifiers
            vals = np.array([ all_data[ds][dc][flt][metric]
                              for ds in file_map.keys() ])
            # average over axis=0 → one 3-element row
            avg = vals.mean(axis=0)
            avg_data[dc][flt][metric] = avg

# 5) write the plain‐text report
with open('average_metrics.txt','w') as f:
    for dc in data_classes:
        f.write(f"Data class: {dc}\n")
        for flt in filters:
            f.write(f"Algorithm type: {flt}\n")
            f.write("-"*75 + "\n")
            f.write(f"{'Classifier name':<20}" +
                    "".join(f"{clf:<15}" for clf in classifiers) + "\n")
            f.write("-"*75 + "\n")
            for metric in metrics_keys:
                row = avg_data[dc][flt][metric]
                # format to 4 decimal places
                f.write(f"{metric:<20}" +
                        "".join(f"{v:>15.4f}" for v in row) + "\n")
            f.write("\n")
    print("Wrote average_metrics.txt")

# 6) emit a LaTeX table
with open('average_results_table.tex','w', encoding='utf-8') as f:
    f.write(r"\begin{table}[ht]"+"\n")
    f.write(r"\centering"+"\n")
    f.write(r"\caption{Average Precision, Recall, F$_1$‐score and mIoU across all three datasets.}"+"\n")
    f.write(r"\label{tab:avg_results}"+"\n")
    cols = "ll l" + " c"*len(metrics_keys)
    f.write(r"\begin{tabular}{" + cols + "}\n")
    f.write(r"\toprule"+"\n")
    header = ["Data class","Method","Classifier"] + [m.replace("F1score","F$_1$").replace("MeanIoU","mIoU") for m in metrics_keys]
    f.write(" & ".join(header) + r" \\" + "\n")
    f.write(r"\midrule"+"\n")
    for dc in data_classes:
        # 3 filters × 3 classifiers = 9 rows per data class
        f.write(r"\multirow{9}{*}{" + dc + r"}" + "\n")
        for i,flt in enumerate(filters):
            for j,clf in enumerate(classifiers):
                prefix = ("&" if (i,j)!=(0,0) else "")
                if j==0:
                    # write filter only on first of its 3 rows
                    prefix += r"& \multirow{3}{*}{" + flt + r"}"
                else:
                    prefix += "&"
                vals = avg_data[dc][flt]
                nums = [vals[m][j] for m in metrics_keys]
                num_str = " & ".join(f"{v:.4f}" for v in nums)
                f.write(prefix + " & " + clf + " & " + num_str + r"\\" + "\n")
        f.write(r"\midrule"+"\n")
    f.write(r"\bottomrule"+"\n")
    f.write(r"\end{tabular}"+"\n")
    f.write(r"\end{table}"+"\n")
    print("Wrote average_results_table.tex")
    print("Done.")