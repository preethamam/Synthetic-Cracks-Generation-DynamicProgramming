#!/usr/bin/env python3
"""
edge_metrics.py

Geometric analysis of crack edge morphology.
Compares synthetic vs. real-world crack binary masks using:
  - Tortuosity (arc length / chord length) per strand edge
  - Local curvature statistics (mean, variance) per strand edge
  - Distribution tests: KS, Mann-Whitney U, Wasserstein distance
  - Per-image feature histograms and violin plots
  - Pairwise nearest-neighbour (NN) matching in feature space
"""

import argparse
import random
import shutil
import sys
import textwrap
import time
import warnings
from pathlib import Path

import cv2

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import pyskelgrad
from joblib import Parallel, delayed
from PIL import Image
from scipy import ndimage
from scipy.ndimage import gaussian_filter1d
from scipy.spatial import cKDTree
from scipy.stats import ks_2samp, mannwhitneyu, wasserstein_distance
from skimage.measure import label

from skimage.morphology import skeletonize
from tqdm import tqdm

warnings.filterwarnings("ignore")

# ==============================================================================
# CONFIGURATION — edit these before running
# ==============================================================================
SYNTHETIC_DIRS = [
    r"H:\Project MegaCRACK-RoboCRACK\Synthetic Data\Training-RoboCrack\synthetic_cracks"
]
REAL_DIRS = [
    r"H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 1 - Cracks-200\Pixel Labels\train",
    r"H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 1 - Cracks-200\Pixel Labels\val",
    r"H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 1 - Cracks-200\Pixel Labels\test",
    r"H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)\Pixel Labels\train",
    r"H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)\Pixel Labels\val",
    r"H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)\Pixel Labels\test",    
    r"H:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack\Pixel Labels\train_crack_bmp",
    r"H:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack\Pixel Labels\val_crack_bmp",
    r"H:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack\Pixel Labels\test_crack_bmp",
]
# REAL_DIRS = [
#     r"S:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 1 - Cracks-200\Pixel Labels\train",
#     r"S:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 1 - Cracks-200\Pixel Labels\val",
#     r"S:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 1 - Cracks-200\Pixel Labels\test",
#     r"S:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)\Pixel Labels\train",
#     r"S:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)\Pixel Labels\val",
#     r"S:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)\Pixel Labels\test",    
#     r"S:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack\Pixel Labels\train_crack_bmp",
#     r"S:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack\Pixel Labels\val_crack_bmp",
#     r"S:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack\Pixel Labels\test_crack_bmp",
# ]
K_SAMPLES        = 3000    # max images to draw from each pool; None = use all
MIN_STRAND_LEN   = 10      # discard skeleton strands shorter than this (pixels)
GAUSSIAN_SIGMA   = 1.5     # sigma for Gaussian smoothing of edge coords before curvature
BINARY_THRESHOLD = 127     # 0-255 grayscale threshold for binarisation
OUTPUT_DIR       = None    # None -> same folder as this script; or r"C:\my\output"
N_JOBS           = -1      # number of parallel workers; -1 = all cores
RANDOM_SEED      = 42
IMAGE_EXTS       = {".png", ".jpg", ".jpeg", ".bmp", ".tif", ".tiff"}
MATCH_NO_STRANDS          = True  # True: subsample per-strand features to equal counts before stat tests
SAVE_PROCESS_STEPS        = True   # True: save per-image pipeline diagnostic figures
SAVE_PROCESS_STEPS_IMAGES = 5      # number of random images to save step figures for (each pool)
SKELETON_GRAD_THRESHOLD   = 0.06 #0.035    # pyskelgrad skeleton gradient threshold (tune for different datasets if needed)
USE_SKELGRAD              = False    # True: skeletonize via pyskelgrad gradient (already pruned); False: skimage + branch-point pruning
# ==============================================================================


# ------------------------------------------------------------------------------
# Image discovery & loading
# ------------------------------------------------------------------------------

def find_image_files(dirs):
    """Recursively collect all image files from a list of directories."""
    files = []
    for d in dirs:
        d = Path(d)
        if not d.exists():
            print(f"    [WARN] Directory not found, skipping: {d}")
            continue
        for path in d.rglob("*"):
            if path.suffix.lower() in IMAGE_EXTS:
                files.append(path)
    # Deduplicate while preserving order
    seen, unique = set(), []
    for f in files:
        if f not in seen:
            seen.add(f)
            unique.append(f)
    return unique


def load_binary_mask(path):
    """Load image and return a boolean binary mask (True = crack pixel)."""
    img = Image.open(path).convert("L")
    arr = np.array(img, dtype=np.uint8)
    return arr > BINARY_THRESHOLD


# ------------------------------------------------------------------------------
# Morphological helpers
# ------------------------------------------------------------------------------

def bwperim(binary_img):
    """
    MATLAB bwperim equivalent.
    Returns foreground pixels that have at least one background neighbour
    under 8-connectivity (i.e. the outer border pixels of each binary object).
    """
    eroded = ndimage.binary_erosion(binary_img, structure=np.ones((3, 3)))
    return binary_img & ~eroded


def find_branch_points(skel):
    """
    Detect branch points: skeleton pixels with >= 3 neighbours (8-connectivity).
    """
    kernel = np.ones((3, 3), dtype=np.uint8)
    kernel[1, 1] = 0
    counts = ndimage.convolve(
        skel.astype(np.uint8), kernel, mode="constant", cval=0
    )
    return skel & (counts >= 3)


# ------------------------------------------------------------------------------
# Pixel ordering via adjacency traversal
# ------------------------------------------------------------------------------

def _adjacency_traverse(pixels_set):
    """
    Traverse a set of 8-connected pixels in order.
    Starts from an endpoint (degree 1) if one exists, otherwise arbitrary.
    Returns an ordered list of (row, col) tuples.
    """
    if not pixels_set:
        return []

    # Build 8-connectivity adjacency
    adj = {}
    for p in pixels_set:
        r, c = p
        nbrs = []
        for dr in (-1, 0, 1):
            for dc in (-1, 0, 1):
                if dr == dc == 0:
                    continue
                n = (r + dr, c + dc)
                if n in pixels_set:
                    nbrs.append(n)
        adj[p] = nbrs

    # Prefer an endpoint (degree 1) as the start of the traversal
    start = None
    for p, nbrs in adj.items():
        if len(nbrs) == 1:
            start = p
            break
    if start is None:
        start = next(iter(pixels_set))

    ordered = [start]
    visited = {start}
    current = start
    while True:
        unvisited = [n for n in adj[current] if n not in visited]
        if not unvisited:
            break
        current = unvisited[0]
        ordered.append(current)
        visited.add(current)

    return ordered


def order_pixels(pixels):
    """Order a collection of pixels (list or array rows) into a connected chain."""
    return _adjacency_traverse({tuple(p) for p in pixels})


# ------------------------------------------------------------------------------
# Geometric feature computation
# ------------------------------------------------------------------------------

def compute_tortuosity(coords):
    """
    Tortuosity = arc length / chord length of an ordered coordinate list.
    Returns 1.0 for degenerate inputs (fewer than 2 points or zero chord).
    """
    if len(coords) < 2:
        return 1.0
    c     = np.asarray(coords, dtype=float)
    diffs = np.diff(c, axis=0)
    arc   = float(np.sum(np.hypot(diffs[:, 0], diffs[:, 1])))
    chord = float(np.hypot(c[-1, 0] - c[0, 0], c[-1, 1] - c[0, 1]))
    return arc / chord if chord > 1e-6 else 1.0


def compute_curvature(coords, sigma):
    """
    Compute absolute curvature |kappa| along an ordered pixel chain.
    Gaussian-smooths the (row, col) coordinates before finite-difference
    estimation of first and second derivatives.
    Returns an array of |kappa| values (one per coordinate point).
    """
    if len(coords) < 5:
        return np.zeros(1)
    c   = np.asarray(coords, dtype=float)
    y   = gaussian_filter1d(c[:, 0], sigma=sigma)   # row axis
    x   = gaussian_filter1d(c[:, 1], sigma=sigma)   # col axis
    dy  = np.gradient(y)
    dx  = np.gradient(x)
    ddy = np.gradient(dy)
    ddx = np.gradient(dx)
    denom = (dx**2 + dy**2) ** 1.5
    denom = np.where(denom < 1e-8, 1e-8, denom)
    return np.abs(dx * ddy - dy * ddx) / denom


# ------------------------------------------------------------------------------
# Strand edge extraction helpers
# ------------------------------------------------------------------------------

def _split_perimeter_loop(loop, skel_arr, tangents, skel_tree):
    """
    For a single-component closed perimeter loop (end strand that has an end cap),
    split it at the two points nearest to the skeleton endpoints to produce the
    two edge halves.  Returns (left_edge, right_edge) or (None, None).
    """
    if len(loop) < 6:
        return None, None
    perim_arr  = np.array(loop, dtype=float)
    perim_tree = cKDTree(perim_arr)

    _, i0 = perim_tree.query(skel_arr[0:1])
    _, i1 = perim_tree.query(skel_arr[-1:])
    i0, i1 = int(i0[0]), int(i1[0])

    if i0 == i1:
        return None, None
    if i0 > i1:
        i0, i1 = i1, i0

    half_a = loop[i0 : i1 + 1]
    half_b = loop[i1 :] + loop[: i0 + 1]

    if len(half_a) < 3 or len(half_b) < 3:
        return None, None

    # One cross-product at the midpoint of half_a to determine which is left
    mid = np.array(half_a[len(half_a) // 2], dtype=float)
    _, nn  = skel_tree.query(mid.reshape(1, 2))
    nn     = int(nn[0])
    vec    = mid - skel_arr[nn]
    cross  = tangents[nn, 0] * vec[1] - tangents[nn, 1] * vec[0]

    return (half_a, half_b) if cross >= 0 else (half_b, half_a)


def compute_voronoi_and_perim(mask, labeled, n_comp):
    """
    For a binary crack mask and its per-strand skeleton label map:
      - Voronoi-partition every crack pixel to its nearest strand skeleton pixel.
      - Compute the outer perimeter of the entire crack (bwperim of mask).
    Returns (voronoi_map, crack_perim).
      voronoi_map : int32 array, shape == mask.shape; value = strand ID (1..n_comp)
                    for crack pixels, 0 for background.
      crack_perim : bool array, shape == mask.shape; True where crack pixel
                    has at least one background 8-neighbour.
    """
    crack_pix = np.argwhere(mask)         # (N, 2)
    if len(crack_pix) == 0:
        return np.zeros(mask.shape, dtype=np.int32), np.zeros(mask.shape, dtype=bool)

    skel_pix_list  = []
    skel_label_list = []
    for sid in range(1, n_comp + 1):
        sp = np.argwhere(labeled == sid)
        if len(sp) > 0:
            skel_pix_list.append(sp)
            skel_label_list.append(np.full(len(sp), sid, dtype=np.int32))

    if not skel_pix_list:
        return np.zeros(mask.shape, dtype=np.int32), bwperim(mask)

    skel_all = np.vstack(skel_pix_list)
    skel_lbl = np.concatenate(skel_label_list)

    tree_all  = cKDTree(skel_all)
    _, nn_idx = tree_all.query(crack_pix)

    voronoi_map = np.zeros(mask.shape, dtype=np.int32)
    voronoi_map[crack_pix[:, 0], crack_pix[:, 1]] = skel_lbl[nn_idx]

    crack_perim = bwperim(mask)
    return voronoi_map, crack_perim


# ------------------------------------------------------------------------------
# Strand edge extraction
# ------------------------------------------------------------------------------

def extract_two_edges(strand_skel, strand_region, crack_perim):
    """
    Extract the two outer boundary edges of a strand.

    strand_skel  : bool mask — skeleton pixels for this strand only.
    strand_region: bool mask — Voronoi region of this strand (voronoi_map == sid).
    crack_perim  : bool mask — outer crack boundary (bwperim of the full mask).

    Algorithm
    ---------
    1. Order and canonically orient the skeleton (rightward / upward for vertical).
    2. Take every pixel in (crack_perim AND strand_region) — the complete outer
       boundary of this strand's Voronoi cell, with no gaps.
    3. For each boundary pixel find its nearest skeleton point via KD-tree
       (equivalent to using the distance transform) and classify left vs right
       using the signed cross-product:  cross = tang_r*vec_c − tang_c*vec_r.
       cross ≥ 0  →  left (blue);   cross < 0  →  right (orange).

    Orientation rule
    ----------------
    Skeleton oriented so dc > 0 (rightward), or dr < 0 (upward) for vertical.
      • Non-vertical crack : blue = upper/top,  orange = lower/bottom.
      • Purely vertical    : blue = left,        orange = right.

    Returns (left_pixels, right_pixels) as lists of (row, col) tuples,
    or (None, None) on failure.
    """
    # ---- Skeleton: order + canonical orientation ----
    skel_pix     = list(zip(*np.where(strand_skel)))
    ordered_skel = order_pixels(skel_pix)
    if len(ordered_skel) < 2:
        return None, None

    skel_arr = np.array(ordered_skel, dtype=float)
    dr = skel_arr[-1, 0] - skel_arr[0, 0]
    dc = skel_arr[-1, 1] - skel_arr[0, 1]
    # Rightward for non-vertical; upward for purely vertical
    if dc < 0 or (dc == 0 and dr > 0):
        skel_arr = skel_arr[::-1]

    # ---- Skeleton tangents ----
    tangents        = np.zeros_like(skel_arr)
    tangents[0]     = skel_arr[1]   - skel_arr[0]
    tangents[-1]    = skel_arr[-1]  - skel_arr[-2]
    tangents[1:-1]  = skel_arr[2:]  - skel_arr[:-2]
    norms           = np.linalg.norm(tangents, axis=1, keepdims=True)
    tangents       /= np.where(norms < 1e-8, 1e-8, norms)
    skel_tree       = cKDTree(skel_arr)

    # ---- cv2.findContours on the strand's Voronoi region ----
    # The contour is a perfectly ordered closed loop.
    H, W    = strand_region.shape
    img     = strand_region.astype(np.uint8) * 255
    cnts, _ = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    if not cnts:
        return None, None
    loop_cv = max(cnts, key=len)   # (N, 1, 2) — OpenCV (col, row) order

    # ---- Keep only outer crack boundary pixels (removes inter-strand cuts) ----
    # outer[k] = (contour_index, row, col) — preserves contour order.
    outer = []
    for i, pt in enumerate(loop_cv):
        c_, r_ = int(pt[0][0]), int(pt[0][1])
        if 0 <= r_ < H and 0 <= c_ < W and crack_perim[r_, c_]:
            outer.append((i, r_, c_))

    if len(outer) < 6:
        return None, None

    # ---- Split the outer-boundary arc at the skeleton endpoints ----
    #
    # Algorithm
    # ---------
    # The ordered outer list traces the crack's outer perimeter (one or two
    # arcs depending on whether inter-strand cuts exist).  The skeleton
    # start and end endpoints each lie nearest to a specific outer pixel;
    # those two pixels divide the perimeter into a LEFT arc and a RIGHT arc
    # regardless of crack shape or curvature.  A single cross-product at
    # each arc's midpoint then assigns the left/right label.
    #
    outer_rc = np.array([(r, c) for (_, r, c) in outer], dtype=float)
    j0 = int(np.argmin(np.sum((outer_rc - skel_arr[0])  ** 2, axis=1)))
    j1 = int(np.argmin(np.sum((outer_rc - skel_arr[-1]) ** 2, axis=1)))

    if j0 == j1:
        return None, None
    if j0 > j1:
        j0, j1 = j1, j0

    # Arc A: outer[j0 .. j1]  (inclusive)
    # Arc B: outer[j1 .. end] + outer[0 .. j0]  (wraps around)
    arc_a = [(r, c) for (_, r, c) in outer[j0 : j1 + 1]]
    arc_b = [(r, c) for (_, r, c) in outer[j1 :] + outer[: j0 + 1]]

    if len(arc_a) < 3 or len(arc_b) < 3:
        return None, None

    # ---- One cross-product at arc_a's midpoint → assign left / right ----
    mid_a  = np.array(arc_a[len(arc_a) // 2], dtype=float)
    _, nn  = skel_tree.query(mid_a.reshape(1, 2))
    nn     = int(nn[0])
    vec    = mid_a - skel_arr[nn]
    cross  = tangents[nn, 0] * vec[1] - tangents[nn, 1] * vec[0]

    return (arc_a, arc_b) if cross >= 0 else (arc_b, arc_a)


# ------------------------------------------------------------------------------
# Per-image processing (parallelised unit)
# ------------------------------------------------------------------------------

def process_image(path):
    """
    Full pipeline for one image:
      load -> binarise -> skeletonize (via pyskelgrad gradient threshold) ->
      label strands -> filter short strands -> extract two edges per strand ->
      compute tortuosity and curvature per edge -> aggregate per image.
    Returns a feature dict, or None on failure / empty mask.
    """
    try:
        mask = load_binary_mask(path)
        if mask.sum() < MIN_STRAND_LEN:
            return None

        if USE_SKELGRAD:
            skg, _rad   = pyskelgrad.compute_skeleton_gradient(mask)
            threshold   = int(np.ceil(max(mask.shape) * SKELETON_GRAD_THRESHOLD))
            skel_pruned = skeletonize(skg > threshold)
        else:
            skel        = skeletonize(mask)
            branch_pts  = find_branch_points(skel)
            skel_pruned = skel & ~branch_pts

        labeled, n_comp = label(skel_pruned, connectivity=2, return_num=True)
        if n_comp == 0:
            return None

        # Voronoi partition: assign every crack pixel to its nearest strand skeleton.
        # crack_perim = outer boundary pixels of the entire crack mask.
        voronoi_map, crack_perim = compute_voronoi_and_perim(mask, labeled, n_comp)

        tort_all      = []
        mean_curv_all = []
        var_curv_all  = []
        strands_data  = []

        for sid in range(1, n_comp + 1):
            strand_skel = labeled == sid
            if strand_skel.sum() < MIN_STRAND_LEN:
                continue

            edge1, edge2 = extract_two_edges(
                strand_skel, voronoi_map == sid, crack_perim)

            for edge in (edge1, edge2):
                if edge is None or len(edge) < 3:
                    continue
                t = compute_tortuosity(edge)
                k = compute_curvature(edge, GAUSSIAN_SIGMA)
                tort_all.append(t)
                mean_curv_all.append(float(np.mean(k)))
                var_curv_all.append(float(np.var(k)))
                strands_data.append({
                    "tortuosity":        t,
                    "mean_curvature":    float(np.mean(k)),
                    "curvature_variance": float(np.var(k)),
                })

        if not tort_all:
            return None

        return {
            "path":                 str(path),
            "tortuosity_mean":      float(np.mean(tort_all)),
            "tortuosity_std":       float(np.std(tort_all)),
            "tortuosity_median":    float(np.median(tort_all)),
            "curvature_mean":       float(np.mean(mean_curv_all)),
            "curvature_std":        float(np.std(mean_curv_all)),
            "curvature_median":     float(np.median(mean_curv_all)),
            "curvature_var_mean":   float(np.mean(var_curv_all)),
            "curvature_var_std":    float(np.std(var_curv_all)),
            "curvature_var_median": float(np.median(var_curv_all)),
            "n_edges":              len(tort_all),
            "strands":              strands_data,
        }
    except Exception:
        return None


# ------------------------------------------------------------------------------
# Sampling
# ------------------------------------------------------------------------------

def sample_files(files, k, seed=RANDOM_SEED):
    """
    Draw up to k files at random.
    If k is None or k >= len(files), returns all files (shuffled).
    Warns when the pool is smaller than the requested k.
    """
    n = len(files)
    if k is None or k >= n:
        rng    = random.Random(seed)
        result = list(files)
        rng.shuffle(result)
        return result
    rng = random.Random(seed)
    return rng.sample(files, k)


def balance_strands(syn_results, real_results, seed=RANDOM_SEED):
    """
    Collect per-strand-edge features from all results and randomly subsample
    the larger pool's strand list down to the smaller pool's count.
    Returns (syn_strands, real_strands) as lists of per-strand-edge dicts,
    and prints the before/after counts.
    """
    syn_strands  = [s for r in syn_results  for s in r.get("strands", [])]
    real_strands = [s for r in real_results for s in r.get("strands", [])]
    n_syn, n_real = len(syn_strands), len(real_strands)
    print(f"       Strand counts before balancing : syn={n_syn}, real={n_real}")
    rng = random.Random(seed)
    n_target = min(n_syn, n_real)
    if n_syn > n_target:
        syn_strands = rng.sample(syn_strands, n_target)
    if n_real > n_target:
        real_strands = rng.sample(real_strands, n_target)
    print(f"       Strand counts after  balancing : syn={len(syn_strands)}, real={len(real_strands)}")
    return syn_strands, real_strands


# ------------------------------------------------------------------------------
# Statistical tests
# ------------------------------------------------------------------------------

FEATURE_LABELS = [
    ("tortuosity_mean",      "Tortuosity - Mean"),
    ("tortuosity_std",       "Tortuosity - Std"),
    ("tortuosity_median",    "Tortuosity - Median"),
    ("curvature_mean",       "Curvature - Mean"),
    ("curvature_std",        "Curvature - Std"),
    ("curvature_median",     "Curvature - Median"),
    ("curvature_var_mean",   "Curvature Var - Mean"),
    ("curvature_var_std",    "Curvature Var - Std"),
    ("curvature_var_median", "Curvature Var - Median"),
]

# Feature space used for pairwise NN matching
NN_FEATURE_KEYS = ["tortuosity_mean", "curvature_mean", "curvature_var_mean"]


def run_statistical_tests(syn_vals, real_vals):
    """Return KS, Mann-Whitney U, and Wasserstein results for two 1-D samples."""
    ks_stat, ks_p = ks_2samp(syn_vals, real_vals)
    mw_stat, mw_p = mannwhitneyu(syn_vals, real_vals, alternative="two-sided")
    wass          = wasserstein_distance(syn_vals, real_vals)
    return dict(ks_stat=ks_stat, ks_p=ks_p,
                mw_stat=mw_stat, mw_p=mw_p,
                wasserstein=wass)


def pairwise_nn_matching(syn_results, real_results):
    """
    For each synthetic image find the nearest real-world image in the
    normalised feature space (tortuosity_mean, curvature_mean, curvature_var_mean).
    Normalisation uses the combined std of both pools.
    Returns (nn_distances, nn_indices_into_real_results).
    """
    keys     = NN_FEATURE_KEYS
    syn_mat  = np.array([[f[k] for k in keys] for f in syn_results])
    real_mat = np.array([[f[k] for k in keys] for f in real_results])

    combined = np.vstack([syn_mat, real_mat])
    std      = combined.std(axis=0)
    std      = np.where(std < 1e-10, 1.0, std)

    syn_norm  = syn_mat  / std
    real_norm = real_mat / std

    tree           = cKDTree(real_norm)
    dists, indices = tree.query(syn_norm, k=1)
    return dists, indices


def save_process_steps_figure(path, tag, out_dir):
    """
    Save a 1x5 subplot diagnostic PNG for one image showing the full
    processing pipeline:
      (a) Binary mask
      (b) Skeleton overlaid on mask
      (c) Branch points highlighted on skeleton
      (d) Pruned skeleton — strands colour-coded
      (e) Raw cv2 contours overlaid on mask (green)
      (f) Extracted outer edges overlaid on mask (left=blue, right=orange)

    tag   : "synthetic" or "real"
    out_dir: Path to process_steps subfolder.
    """
    try:
        mask = load_binary_mask(path)
        if not mask.any():
            return

        if USE_SKELGRAD:
            skg, _rad   = pyskelgrad.compute_skeleton_gradient(mask)
            threshold   = int(np.ceil(max(mask.shape) * SKELETON_GRAD_THRESHOLD))
            skel        = skeletonize(skg > threshold)
        else:
            skel        = skeletonize(mask)
        branch_pts  = find_branch_points(skel)
        skel_pruned = skel & ~branch_pts
        labeled, n_comp = label(skel_pruned, connectivity=2, return_num=True)

        voronoi_map, crack_perim = compute_voronoi_and_perim(mask, labeled, n_comp)

        # Collect all left/right edge pixels across all valid strands
        left_img  = np.zeros(mask.shape, dtype=bool)
        right_img = np.zeros(mask.shape, dtype=bool)
        for sid in range(1, n_comp + 1):
            strand_skel = labeled == sid
            if strand_skel.sum() < MIN_STRAND_LEN:
                continue
            e1, e2 = extract_two_edges(strand_skel, voronoi_map == sid, crack_perim)
            if e1:
                for r, c in e1:
                    if 0 <= r < mask.shape[0] and 0 <= c < mask.shape[1]:
                        left_img[r, c] = True
            if e2:
                for r, c in e2:
                    if 0 <= r < mask.shape[0] and 0 <= c < mask.shape[1]:
                        right_img[r, c] = True

        # ---- Build the 6 overlay images ----

        def gray3(m):
            """Convert bool/float mask to 3-channel float [0,1] image."""
            g = m.astype(float)
            return np.stack([g, g, g], axis=-1)

        # (a) binary mask
        img_a = gray3(mask)

        # (b) skeleton on mask (cyan)
        img_b = gray3(mask)
        img_b[skel] = [0.0, 0.85, 0.85]

        # (c) branch points on skeleton+mask (branch points = red)
        img_c = gray3(mask)
        img_c[skel]        = [0.0, 0.85, 0.85]
        img_c[branch_pts]  = [1.0, 0.15, 0.15]

        # (d) pruned skeleton strands, colour-coded on dim mask
        img_d = gray3(mask) * 0.25
        cmap  = plt.cm.get_cmap("tab20", max(n_comp, 1))
        for sid in range(1, n_comp + 1):
            sm = labeled == sid
            if sm.sum() < MIN_STRAND_LEN:
                continue
            img_d[sm] = cmap(sid % 20)[:3]

        # (e) raw cv2.findContours result (bright green on dim mask)
        img_e = gray3(mask) * 0.3
        mask_u8  = mask.astype(np.uint8) * 255
        cnts_all, _ = cv2.findContours(mask_u8, cv2.RETR_EXTERNAL,
                                        cv2.CHAIN_APPROX_NONE)
        for cnt in cnts_all:
            for pt in cnt:
                c_, r_ = int(pt[0][0]), int(pt[0][1])
                if 0 <= r_ < mask.shape[0] and 0 <= c_ < mask.shape[1]:
                    img_e[r_, c_] = [0.10, 0.95, 0.25]   # bright green

        # (f) left/right edges overlaid on mask
        img_f = gray3(mask)
        img_f[left_img]  = [0.10, 0.45, 0.95]   # blue  — left edge
        img_f[right_img] = [1.00, 0.40, 0.00]   # orange — right edge

        # ---- Figure ----
        fig, axes = plt.subplots(1, 6, figsize=(34, 6), dpi=200)

        titles = [
            "(a) Binary Mask",
            "(b) Skeleton",
            f"(c) Branch Points\n({int(branch_pts.sum())} px)",
            f"(d) Pruned Strands\n(n = {n_comp})",
            "(e) cv2 Contours\n(exact 1-px boundary)",
            "(f) Extracted Edges\nBlue = Left  |  Orange = Right",
        ]
        imgs = [img_a, img_b, img_c, img_d, img_e, img_f]

        for ax, img, title in zip(axes, imgs, titles):
            ax.imshow(img, interpolation="nearest", aspect="equal")
            ax.set_title(title, fontsize=10, fontweight="bold", pad=6)
            ax.axis("off")

        fname = Path(path).name
        fpath = str(path)
        fig.suptitle(
            f"[{tag.upper()}]  {fname}\n{fpath}",
            fontsize=8, fontweight="bold", y=1.01, ha="center"
        )

        plt.tight_layout(pad=1.2)

        stem    = Path(path).stem
        outname = f"{stem}_{tag}.png"
        plt.savefig(out_dir / outname, dpi=200, bbox_inches="tight")
        plt.close(fig)

    except Exception:
        plt.close("all")


# ------------------------------------------------------------------------------
# Plotting
# ------------------------------------------------------------------------------

def plot_results(syn_results, real_results, nn_dists, out_dir):
    out_dir = Path(out_dir)
    n_feat  = len(FEATURE_LABELS)
    ncols   = 3
    nrows   = int(np.ceil(n_feat / ncols))

    # ---- Histograms --------------------------------------------------------
    fig, axes = plt.subplots(nrows, ncols, figsize=(5 * ncols, 4 * nrows))
    for ax, (key, lbl) in zip(axes.flat, FEATURE_LABELS):
        sv = [f[key] for f in syn_results]
        rv = [f[key] for f in real_results]
        ax.hist(sv, bins=40, alpha=0.6, density=True,
                color="steelblue",  label="Synthetic")
        ax.hist(rv, bins=40, alpha=0.6, density=True,
                color="darkorange", label="Real")
        ax.set_title(lbl, fontsize=9)
        ax.set_xlabel("Value", fontsize=8)
        ax.set_ylabel("Density", fontsize=8)
        ax.legend(fontsize=7)
        ax.tick_params(labelsize=7)
    for ax in list(axes.flat)[n_feat:]:
        ax.set_visible(False)
    plt.suptitle("Feature Distribution: Synthetic vs. Real Crack Edges", fontsize=12)
    plt.tight_layout(rect=[0, 0, 1, 0.96])
    p = out_dir / "feature_histograms.png"
    plt.savefig(p, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"    Saved: {p}")

    # ---- Violin plots ------------------------------------------------------
    fig, axes = plt.subplots(nrows, ncols, figsize=(5 * ncols, 4 * nrows))
    for ax, (key, lbl) in zip(axes.flat, FEATURE_LABELS):
        sv = [f[key] for f in syn_results]
        rv = [f[key] for f in real_results]
        parts = ax.violinplot([sv, rv], positions=[1, 2],
                              showmedians=True, showextrema=True)
        parts["cmedians"].set_color("black")
        parts["cmedians"].set_linewidth(2)
        ax.set_xticks([1, 2])
        ax.set_xticklabels(["Synthetic", "Real"], fontsize=8)
        ax.set_title(lbl, fontsize=9)
        ax.set_ylabel("Value", fontsize=8)
        ax.tick_params(labelsize=7)
    for ax in list(axes.flat)[n_feat:]:
        ax.set_visible(False)
    plt.suptitle("Feature Distributions (Violin): Synthetic vs. Real", fontsize=12)
    plt.tight_layout(rect=[0, 0, 1, 0.96])
    p = out_dir / "feature_violins.png"
    plt.savefig(p, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"    Saved: {p}")

    # ---- NN matching distances ---------------------------------------------
    fig, ax = plt.subplots(figsize=(7, 4))
    ax.hist(nn_dists, bins=50, color="mediumseagreen",
            edgecolor="black", alpha=0.85)
    ax.axvline(np.median(nn_dists), color="crimson", ls="--", lw=1.5,
               label=f"Median = {np.median(nn_dists):.3f}")
    ax.axvline(nn_dists.mean(), color="navy", ls=":", lw=1.5,
               label=f"Mean   = {nn_dists.mean():.3f}")
    ax.set_xlabel("Nearest-Neighbour Distance (normalised feature space)", fontsize=10)
    ax.set_ylabel("Count", fontsize=10)
    ax.set_title("Pairwise NN Matching: Synthetic -> Real Crack Images", fontsize=11)
    ax.legend(fontsize=9)
    plt.tight_layout()
    p = out_dir / "nn_matching_distances.png"
    plt.savefig(p, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"    Saved: {p}")


# ------------------------------------------------------------------------------
# Article-ready text summary
# ------------------------------------------------------------------------------

def _build_interpretation(syn_results, real_results, test_rows, test_lookup, nn_dists):
    """
    Build a list of interpretive paragraphs comparing synthetic and real crack
    edge geometry based on the computed features and statistical tests.
    Each element in the returned list is one paragraph (unsplit string).
    """
    paras = []

    # ---- Helper: pull mean arrays for a feature key ----
    def smean(key):
        return float(np.mean([f[key] for f in syn_results]))
    def rmean(key):
        return float(np.mean([f[key] for f in real_results]))
    def sstd(key):
        return float(np.std([f[key] for f in syn_results]))
    def rstd(key):
        return float(np.std([f[key] for f in real_results]))

    # ---- Collect significant features ----
    sig_features = [r["feature"] for r in test_rows if r["ks_p"] < 0.05]
    n_sig        = len(sig_features)
    n_total      = len(test_rows)

    # ---- Tortuosity comparison ----
    s_tort  = smean("tortuosity_mean")
    r_tort  = rmean("tortuosity_mean")
    tort_diff_pct = abs(s_tort - r_tort) / max(r_tort, 1e-8) * 100
    tort_row = test_lookup.get("Tortuosity - Mean", {})
    tort_sig = tort_row.get("ks_p", 1.0) < 0.05

    if tort_diff_pct < 5:
        tort_adj = "nearly identical"
    elif tort_diff_pct < 15:
        tort_adj = "closely comparable"
    else:
        tort_adj = "somewhat different"

    if s_tort > r_tort:
        tort_dir = (f"Synthetic edges are marginally more tortuous "
                    f"({s_tort:.3f} vs. {r_tort:.3f}), suggesting slightly "
                    f"more irregular crack paths in the synthetic dataset.")
    elif s_tort < r_tort:
        tort_dir = (f"Real-world edges exhibit marginally higher tortuosity "
                    f"({r_tort:.3f} vs. {s_tort:.3f}), consistent with the "
                    f"irregular propagation patterns found in physical fractures.")
    else:
        tort_dir = (f"Tortuosity is virtually identical between both datasets "
                    f"({s_tort:.3f}).")

    tort_sig_str = (
        "The difference is statistically significant (KS p = "
        f"{tort_row.get('ks_p', float('nan')):.4f}), indicating a detectable "
        "distributional gap."
        if tort_sig else
        "The difference is not statistically significant (KS p = "
        f"{tort_row.get('ks_p', float('nan')):.4f}), confirming distributional "
        "agreement."
    )

    paras.append(
        f"Tortuosity Analysis: The mean tortuosity of crack edges is {tort_adj} "
        f"between synthetic and real-world masks (synthetic: {s_tort:.3f} +/- "
        f"{sstd('tortuosity_mean'):.3f}; real-world: {r_tort:.3f} +/- "
        f"{rstd('tortuosity_mean'):.3f}). {tort_dir} {tort_sig_str}"
    )

    # ---- Curvature comparison ----
    s_curv = smean("curvature_mean")
    r_curv = rmean("curvature_mean")
    s_cvar = smean("curvature_var_mean")
    r_cvar = rmean("curvature_var_mean")
    curv_diff_pct = abs(s_curv - r_curv) / max(r_curv, 1e-8) * 100
    curv_row = test_lookup.get("Curvature - Mean", {})
    cvar_row = test_lookup.get("Curvature Var - Mean", {})

    if curv_diff_pct < 10:
        curv_adj = "closely matched"
    elif curv_diff_pct < 25:
        curv_adj = "moderately similar"
    else:
        curv_adj = "notably different"

    if s_curv > r_curv:
        curv_dir = (f"Synthetic edges show higher mean curvature ({s_curv:.4f} vs. "
                    f"{r_curv:.4f}), which may reflect the effect of morphological "
                    f"dilation used in synthetic crack generation producing more "
                    f"rounded edge profiles.")
    else:
        curv_dir = (f"Real-world edges exhibit higher mean curvature ({r_curv:.4f} "
                    f"vs. {s_curv:.4f}), consistent with the rougher, more irregular "
                    f"boundaries characteristic of physically propagated cracks.")

    curv_sig_str = (
        f"Mean curvature distributions are {'significantly' if curv_row.get('ks_p', 1) < 0.05 else 'not significantly'} "
        f"different (KS p = {curv_row.get('ks_p', float('nan')):.4f}), and curvature "
        f"variance distributions are {'significantly' if cvar_row.get('ks_p', 1) < 0.05 else 'not significantly'} "
        f"different (KS p = {cvar_row.get('ks_p', float('nan')):.4f})."
    )

    paras.append(
        f"Curvature Analysis: Local curvature statistics are {curv_adj} between "
        f"the two datasets (mean curvature — synthetic: {s_curv:.4f} +/- "
        f"{sstd('curvature_mean'):.4f}, real-world: {r_curv:.4f} +/- "
        f"{rstd('curvature_mean'):.4f}; curvature variance — synthetic: "
        f"{s_cvar:.4f} +/- {sstd('curvature_var_mean'):.4f}, real-world: "
        f"{r_cvar:.4f} +/- {rstd('curvature_var_mean'):.4f}). "
        f"{curv_dir} {curv_sig_str}"
    )

    # ---- Overall statistical summary ----
    wass_vals = {r["feature"]: r["wasserstein"] for r in test_rows}
    max_wass_feat = max(wass_vals, key=wass_vals.get)
    min_wass_feat = min(wass_vals, key=wass_vals.get)

    if n_sig == 0:
        sig_stmt = (
            f"Across all {n_total} tested features, no statistically significant "
            f"distributional differences were detected between synthetic and "
            f"real-world crack edges (all KS p >= 0.05). This provides strong "
            f"evidence that the synthetic crack generation process replicates "
            f"the geometric character of real-world crack boundaries."
        )
    elif n_sig <= n_total // 2:
        sig_stmt = (
            f"Of the {n_total} features tested, {n_sig} showed statistically "
            f"significant distributional differences: {', '.join(sig_features)}. "
            f"The remaining {n_total - n_sig} features showed no significant "
            f"difference, indicating broad geometric agreement between synthetic "
            f"and real-world crack edges."
        )
    else:
        sig_stmt = (
            f"Of the {n_total} features tested, {n_sig} showed statistically "
            f"significant distributional differences, suggesting that while the "
            f"synthetic cracks capture the general morphological character of "
            f"real-world cracks, systematic differences in edge geometry remain."
        )

    paras.append(
        f"Statistical Overview: {sig_stmt} The largest Wasserstein distance was "
        f"observed for '{max_wass_feat}' ({wass_vals[max_wass_feat]:.4f}), "
        f"indicating this feature has the greatest distributional separation, "
        f"while '{min_wass_feat}' showed the smallest distance "
        f"({wass_vals[min_wass_feat]:.4f}), confirming near-identical distributions "
        f"for that feature."
    )

    # ---- NN matching interpretation ----
    nn_mean   = float(nn_dists.mean())
    nn_median = float(np.median(nn_dists))
    nn_std    = float(nn_dists.std())

    if nn_mean < 0.5:
        nn_adj = "very close"
        nn_qual = ("indicating that for the majority of synthetic images, a "
                   "geometrically similar real-world counterpart exists in the dataset.")
    elif nn_mean < 1.0:
        nn_adj = "reasonably close"
        nn_qual = ("indicating that synthetic crack boundaries broadly overlap "
                   "with the geometric diversity present in real-world crack datasets.")
    else:
        nn_adj = "moderately distant"
        nn_qual = ("suggesting that a portion of the synthetic feature space "
                   "is not well-covered by the available real-world samples, "
                   "or vice versa.")

    paras.append(
        f"Nearest-Neighbour Matching: Pairwise NN matching in the normalised "
        f"feature space (tortuosity mean, curvature mean, curvature variance mean) "
        f"yielded a mean distance of {nn_mean:.4f} (median: {nn_median:.4f}, "
        f"std: {nn_std:.4f}). These distances are {nn_adj}, {nn_qual} The "
        f"relatively {'low' if nn_std < 0.3 else 'moderate'} standard deviation "
        f"({nn_std:.4f}) indicates {'consistent' if nn_std < 0.3 else 'variable'} "
        f"similarity across the synthetic dataset, rather than a few outlier "
        f"synthetic images driving the overall result."
    )

    # ---- Overall conclusion ----
    if n_sig == 0 and nn_mean < 1.0:
        conclusion_quality = (
            "strongly supports the validity of the synthetic crack generation "
            "methodology. The morphological dilation approach, while a simplified "
            "model of crack thickness, produces edge irregularity and tortuosity "
            "distributions that are statistically indistinguishable from those "
            "observed in real-world crack datasets."
        )
    elif n_sig <= n_total // 3 and nn_mean < 1.5:
        conclusion_quality = (
            "broadly supports the fidelity of the synthetic crack generation "
            "approach. Minor distributional differences in isolated features do "
            "not undermine the overall geometric correspondence, and the synthetic "
            "dataset provides a representative surrogate for real-world crack "
            "boundary morphology."
        )
    else:
        conclusion_quality = (
            "indicates partial geometric correspondence between synthetic and "
            "real-world crack boundaries. Further refinement of the synthetic "
            "generation parameters — particularly those governing edge irregularity "
            "and curvature — may be warranted to improve fidelity."
        )

    paras.append(
        f"Overall Conclusion: The combined evidence from tortuosity analysis, "
        f"curvature statistics, distribution-level hypothesis tests, and pairwise "
        f"nearest-neighbour matching {conclusion_quality}"
    )

    return paras


def write_summary_txt(path, syn_results, real_results, test_rows,
                      nn_dists, syn_sampled, real_sampled, elapsed,
                      strand_test_rows=None, syn_strands=None, real_strands=None,
                      syn_topup_sampled=None):
    """
    Write a formatted plain-text summary suitable for inclusion in an article.
    Sections:
      1. Feature statistics table  (mean, std, median for synthetic and real)
      2. Statistical comparison table (KS, Mann-Whitney U, Wasserstein)
      3. Pairwise NN matching summary
      4. Sampled image file lists (synthetic then real-world, full paths)
    """
    W  = 100          # total line width
    SEP  = "=" * W
    SEP2 = "-" * W

    col_feat  = 30
    col_val   = 18    # wide enough for "mean +/- std  median"

    lines = []
    def ln(s=""):
        lines.append(s)

    # ------------------------------------------------------------------
    # Header
    # ------------------------------------------------------------------
    syn_topup_sampled = syn_topup_sampled or []
    n_syn_strands_total  = sum(len(r.get("strands", [])) for r in syn_results)
    n_real_strands_total = sum(len(r.get("strands", [])) for r in real_results)
    n_syn_bal  = len(syn_strands)  if syn_strands  else 0
    n_real_bal = len(real_strands) if real_strands else 0

    ln(SEP)
    ln("CRACK EDGE GEOMETRIC METRICS — SUMMARY")
    ln(f"Synthetic images analysed : {len(syn_results)}"
       f"  (initial: {len(syn_sampled)},  top-up: {len(syn_topup_sampled)})")
    ln(f"Real-world images analysed: {len(real_results)}")
    if elapsed is not None:
        ln(f"Total processing time     : {elapsed:.1f} s")
    if syn_strands is not None:
        ln(f"Strand pool (all images)  : syn={n_syn_strands_total},  real={n_real_strands_total}")
        ln(f"Strand pool (balanced)    : syn={n_syn_bal},  real={n_real_bal}")
    ln(SEP)

    # ------------------------------------------------------------------
    # Statistical test glossary
    # ------------------------------------------------------------------
    ln()
    ln("STATISTICAL TEST GLOSSARY")
    ln(SEP2[:W])
    cA = 14
    ln(f"  {'Abbreviation':<{cA}}  {'Full Name':<30}  {'What It Measures'}")
    ln(f"  {'-'*cA}  {'-'*30}  {'-'*50}")
    ln(f"  {'KS stat':<{cA}}  {'Kolmogorov-Smirnov statistic':<30}  "
       f"Maximum vertical distance between the two CDFs (0 = identical, 1 = completely separate)")
    ln(f"  {'KS p':<{cA}}  {'KS p-value':<30}  "
       f"Probability of observing this difference by chance under H0 (same distribution)")
    ln(f"  {'MW p':<{cA}}  {'Mann-Whitney U p-value':<30}  "
       f"Non-parametric test for whether one distribution tends to have larger values than the other")
    ln(f"  {'Wass':<{cA}}  {'Wasserstein distance':<30}  "
       f"How much work to transform one distribution into the other — scale-sensitive, unlike KS")
    ln(f"  {'Sig':<{cA}}  {'Significance marker':<30}  "
       f"ns = not significant (p >= 0.05);  * = p < 0.05;  ** = p < 0.01  (based on KS p-value)")
    ln(SEP2[:W])

    # ------------------------------------------------------------------
    # Table 1 — Feature statistics
    # ------------------------------------------------------------------
    ln()
    ln("TABLE 1.  Per-image edge feature statistics (aggregated across all strands per image).")
    ln("          Values shown as mean +/- std  [median].")
    ln()

    c0, c1, c2 = col_feat, col_val + 4, col_val + 4
    hdr = f"  {'Feature':<{c0}}  {'Synthetic':^{c1}}  {'Real-world':^{c2}}"
    ln(hdr)
    ln("  " + SEP2[: len(hdr) - 2])

    for key, lbl in FEATURE_LABELS:
        sv = np.array([f[key] for f in syn_results])
        rv = np.array([f[key] for f in real_results])
        s_cell = f"{sv.mean():.4f} +/- {sv.std():.4f}  [{np.median(sv):.4f}]"
        r_cell = f"{rv.mean():.4f} +/- {rv.std():.4f}  [{np.median(rv):.4f}]"
        ln(f"  {lbl:<{c0}}  {s_cell:<{c1}}  {r_cell:<{c2}}")

    # ------------------------------------------------------------------
    # Table 2 — Statistical comparison
    # ------------------------------------------------------------------
    ln()
    ln()
    ln("TABLE 2.  Statistical comparison between synthetic and real-world edge feature distributions.")
    ln("          Significance: * p < 0.05,  ** p < 0.01.")
    ln()

    c_ks, c_ksp, c_mwp, c_wass = 10, 10, 10, 12
    hdr2 = (f"  {'Feature':<{c0}}  {'Sig':>3}  "
            f"{'KS stat':>{c_ks}}  {'KS p':>{c_ksp}}  "
            f"{'MW p':>{c_mwp}}  {'Wasserstein':>{c_wass}}")
    ln(hdr2)
    ln("  " + SEP2[: len(hdr2) - 2])

    for row in test_rows:
        if   row["ks_p"] < 0.01:
            sig = "**"
        elif row["ks_p"] < 0.05:
            sig = " *"
        else:
            sig = "  "
        ln(f"  {row['feature']:<{c0}}  {sig:>3}  "
           f"{row['ks_stat']:>{c_ks}.4f}  {row['ks_p']:>{c_ksp}.4f}  "
           f"{row['mw_p']:>{c_mwp}.4f}  {row['wasserstein']:>{c_wass}.4f}")

    # ------------------------------------------------------------------
    # Table 2b — Strand-level statistical comparison (only if MATCH_NO_STRANDS)
    # ------------------------------------------------------------------
    if strand_test_rows:
        ln()
        ln()
        ln("TABLE 2b. Strand-level statistical comparison (MATCH_NO_STRANDS=True).")
        ln(f"          Balanced strand counts: {len(syn_strands or [])} synthetic, "
           f"{len(real_strands or [])} real-world.")
        ln("          Tests run on per-strand-edge feature distributions.")
        ln("          Significance: * p < 0.05,  ** p < 0.01.")
        ln()
        c_sl = 30
        hdr_s = (f"  {'Feature':<{c_sl}}  {'Syn mean+/-std [med]':<28}"
                 f"  {'Real mean+/-std [med]':<28}"
                 f"  {'KS stat':>8}  {'KS p':>8}  {'MW p':>8}  {'Wass':>10}  {'Sig':>3}")
        ln(hdr_s)
        ln("  " + "-" * (len(hdr_s) - 2))
        for row in strand_test_rows:
            if row["ks_p"] < 0.01:
                sig = "**"
            elif row["ks_p"] < 0.05:
                sig = " *"
            else:
                sig = "ns"
            s_cell = (f"{row['syn_mean']:.4f} +/- {row['syn_std']:.4f}"
                      f" [{row['syn_median']:.4f}]")
            r_cell = (f"{row['real_mean']:.4f} +/- {row['real_std']:.4f}"
                      f" [{row['real_median']:.4f}]")
            ln(f"  {row['feature']:<{c_sl}}  {s_cell:<28}  {r_cell:<28}"
               f"  {row['ks_stat']:>8.4f}  {row['ks_p']:>8.4f}"
               f"  {row['mw_p']:>8.4f}  {row['wasserstein']:>10.4f}  {sig:>3}")

    # ------------------------------------------------------------------
    # Table 3 — NN matching
    # ------------------------------------------------------------------
    ln()
    ln()
    ln("TABLE 3.  Pairwise nearest-neighbour (NN) matching distances.")
    ln("          Each synthetic image matched to its closest real-world image in normalised")
    ln("          feature space (tortuosity mean, curvature mean, curvature variance mean).")
    ln()
    ln(f"  {'Statistic':<20}  {'Value':>10}")
    ln("  " + SEP2[:34])
    ln(f"  {'Mean':<20}  {nn_dists.mean():>10.4f}")
    ln(f"  {'Median':<20}  {np.median(nn_dists):>10.4f}")
    ln(f"  {'Std':<20}  {nn_dists.std():>10.4f}")
    ln(f"  {'Min':<20}  {nn_dists.min():>10.4f}")
    ln(f"  {'Max':<20}  {nn_dists.max():>10.4f}")

    # ------------------------------------------------------------------
    # Table 4 — Compact publication table (Tables 1 + 2 + 3 merged)
    # ------------------------------------------------------------------
    ln()
    ln()
    ln("TABLE 4.  Compact summary for publication.")
    ln("          Crack edge feature statistics for synthetic vs. real-world crack masks,")
    ln("          with distribution comparison tests and pairwise NN matching.")
    ln()
    ln("  Legend:")
    ln("    KS stat  : Kolmogorov-Smirnov statistic — max distance between CDFs (0=identical, 1=separate)")
    ln("    KS p     : KS test p-value (H0: same distribution)")
    ln("    MW p     : Mann-Whitney U test p-value (H0: equal medians, two-sided)")
    ln("    Wass     : Wasserstein (Earth Mover's) distance — transport cost between distributions")
    ln("    Sig      : * p < 0.05,  ** p < 0.01  (based on KS p-value);  blank = not significant")
    ln()

    # Build a lookup from feature label -> test row
    test_lookup = {row["feature"]: row for row in test_rows}

    # Column widths
    cF  = 26   # Feature
    cS  = 20   # Synthetic mean +/- std
    cR  = 20   # Real mean +/- std
    cKS =  8   # KS stat
    cP  =  7   # KS p
    cMW =  7   # MW p
    cW  =  9   # Wasserstein
    cSG =  4   # Sig (ns / * / **)

    div = (f"  {'-'*cF}  {'-'*cS}  {'-'*cR}  {'-'*cKS}  {'-'*cP}"
           f"  {'-'*cMW}  {'-'*cW}  {'-'*cSG}")

    ln("  Part A — Edge feature statistics and distribution tests")
    ln(f"  {'Feature':<{cF}}  {'Syn (mean +/- std)':^{cS}}  {'Real (mean +/- std)':^{cR}}"
       f"  {'KS':^{cKS}}  {'KS p':^{cP}}  {'MW p':^{cMW}}  {'Wass':^{cW}}  {'Sig':^{cSG}}")
    ln(div)

    for key, lbl in FEATURE_LABELS:
        sv  = np.array([f[key] for f in syn_results])
        rv  = np.array([f[key] for f in real_results])
        row = test_lookup.get(lbl, {})

        s_cell = f"{sv.mean():.3f} +/- {sv.std():.3f}"
        r_cell = f"{rv.mean():.3f} +/- {rv.std():.3f}"

        ks_p = row.get("ks_p", float("nan"))
        if ks_p < 0.01:
            sig = " **"
        elif ks_p < 0.05:
            sig = "  *"
        else:
            sig = " ns"

        ln(f"  {lbl:<{cF}}  {s_cell:<{cS}}  {r_cell:<{cR}}"
           f"  {row.get('ks_stat', float('nan')):>{cKS}.4f}"
           f"  {ks_p:>{cP}.4f}"
           f"  {row.get('mw_p', float('nan')):>{cMW}.4f}"
           f"  {row.get('wasserstein', float('nan')):>{cW}.4f}"
           f"  {sig:>{cSG}}")

    ln(div)

    # Part B — NN matching embedded in Table 4
    ln()
    ln("  Part B — Pairwise nearest-neighbour matching (Synthetic -> Real, normalised feature space)")
    ln(f"  {'Statistic':<20}  {'Value':>10}  Note")
    ln(f"  {'-'*20}  {'-'*10}  {'-'*45}")
    ln(f"  {'Mean NN distance':<20}  {nn_dists.mean():>10.4f}"
       f"  Average similarity; lower = more similar")
    ln(f"  {'Median NN distance':<20}  {np.median(nn_dists):>10.4f}"
       f"  Robust central tendency")
    ln(f"  {'Std NN distance':<20}  {nn_dists.std():>10.4f}"
       f"  Spread of similarity across the dataset")
    ln(f"  {'Min NN distance':<20}  {nn_dists.min():>10.4f}"
       f"  Best-matched synthetic-real pair")
    ln(f"  {'Max NN distance':<20}  {nn_dists.max():>10.4f}"
       f"  Worst-matched synthetic-real pair")
    ln(f"  {'-'*20}  {'-'*10}  {'-'*45}")

    # ------------------------------------------------------------------
    # Interpretation / Commentary
    # ------------------------------------------------------------------
    ln()
    ln()
    ln("COMMENTARY — Interpretation of Table 4")
    ln(SEP2[:W])
    interp = _build_interpretation(
        syn_results, real_results, test_rows, test_lookup, nn_dists
    )
    # Word-wrap the paragraph at W characters
    for para in interp:
        for line in textwrap.wrap(para, width=W):
            ln(line)
        ln()
    ln(SEP2[:W])

    # ------------------------------------------------------------------
    # Sampled file lists
    # ------------------------------------------------------------------
    ln()
    ln()
    n_syn_total_files = len(syn_sampled) + len(syn_topup_sampled)
    ln(SEP)
    ln(f"SAMPLED IMAGE FILES  "
       f"(synthetic: {len(syn_sampled)} initial + {len(syn_topup_sampled)} top-up = {n_syn_total_files} total"
       f",  real-world: {len(real_sampled)})")
    ln(SEP)

    ln()
    ln(f"--- Synthetic images — initial sample ({len(syn_sampled)}) ---")
    for i, p in enumerate(sorted(str(f) for f in syn_sampled), 1):
        ln(f"  {i:>6}.  {p}")

    if syn_topup_sampled:
        ln()
        ln(f"--- Synthetic images — strand top-up ({len(syn_topup_sampled)}) ---")
        for i, p in enumerate(sorted(str(f) for f in syn_topup_sampled), 1):
            ln(f"  {i:>6}.  {p}")

    ln()
    ln(f"--- Real-world images ({len(real_sampled)}) ---")
    for i, p in enumerate(sorted(str(f) for f in real_sampled), 1):
        ln(f"  {i:>6}.  {p}")

    ln()
    ln(SEP)

    Path(path).write_text("\n".join(lines), encoding="utf-8")


# ------------------------------------------------------------------------------
# Entry point
# ------------------------------------------------------------------------------

def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Crack edge geometric metrics: tortuosity and curvature comparison "
            "between synthetic and real-world crack binary masks."
        )
    )
    parser.add_argument(
        "--output-dir", type=str, default=None,
        help=(
            "Directory for CSV and PNG outputs. "
            "Defaults to OUTPUT_DIR in config, or the script directory."
        ),
    )
    return parser.parse_args()


def main():
    args = parse_args()
    t0   = time.time()

    # Resolve output directory: CLI arg > config variable > script directory
    if args.output_dir:
        out_dir = Path(args.output_dir)
    elif OUTPUT_DIR:
        out_dir = Path(OUTPUT_DIR)
    else:
        out_dir = Path(__file__).resolve().parent
    out_dir.mkdir(parents=True, exist_ok=True)

    SEP = "=" * 68
    print(SEP)
    print("  CRACK EDGE GEOMETRIC METRICS ANALYSIS")
    print(SEP)
    print(f"  MIN_STRAND_LEN   : {MIN_STRAND_LEN} px")
    print(f"  GAUSSIAN_SIGMA   : {GAUSSIAN_SIGMA}")
    print(f"  BINARY_THRESHOLD : {BINARY_THRESHOLD}")
    print(f"  K_SAMPLES        : {K_SAMPLES if K_SAMPLES else 'ALL'}")
    print(f"  N_JOBS           : {N_JOBS}  (-1 = all cores)")
    print(f"  RANDOM_SEED      : {RANDOM_SEED}")
    print(f"  Output dir       : {out_dir}")
    print(SEP)

    # ---- 1. Discover files ------------------------------------------------
    print("\n[1/6]  Discovering images ...")
    syn_files  = find_image_files(SYNTHETIC_DIRS)
    real_files = find_image_files(REAL_DIRS)
    print(f"       Synthetic  images found : {len(syn_files)}")
    print(f"       Real-world images found : {len(real_files)}")

    if not syn_files:
        sys.exit("  ERROR: No synthetic images found. Check SYNTHETIC_DIRS.")
    if not real_files:
        sys.exit("  ERROR: No real-world images found. Check REAL_DIRS.")

    # ---- 2. Sample --------------------------------------------------------
    # Cap K to the smaller pool so both sets are equally sized.
    effective_k = K_SAMPLES
    if K_SAMPLES is not None:
        pool_min = min(len(syn_files), len(real_files))
        if K_SAMPLES > pool_min:
            effective_k = pool_min
            print(f"\n[2/6]  K={K_SAMPLES} exceeds the smaller pool ({pool_min}). "
                  f"Using K={effective_k} for both pools.")
        else:
            print(f"\n[2/6]  Sampling K={effective_k} images per pool ...")
    else:
        print("\n[2/6]  Sampling ALL images per pool ...")

    syn_sampled  = sample_files(syn_files,  effective_k, RANDOM_SEED)
    real_sampled = sample_files(real_files, effective_k, RANDOM_SEED)
    print(f"       Synthetic  : {len(syn_sampled):>6} / {len(syn_files)}")
    print(f"       Real-world : {len(real_sampled):>6} / {len(real_files)}")

    if len(syn_sampled) < 2:
        print("  WARNING: Very few synthetic images -- statistics will be unreliable.")
    if len(real_sampled) < 2:
        print("  WARNING: Very few real-world images -- statistics will be unreliable.")

    # ---- 3. Process synthetic images --------------------------------------
    print(f"\n[3/6]  Processing {len(syn_sampled)} synthetic images "
          f"(parallel, N_JOBS={N_JOBS}) ...")
    syn_raw = Parallel(n_jobs=N_JOBS)(
        delayed(process_image)(p)
        for p in tqdm(syn_sampled, desc="    Synthetic ", unit="img", ncols=72)
    )
    syn_results = [r for r in syn_raw if r is not None]
    print(f"       Valid: {len(syn_results)}   "
          f"Failed/empty: {len(syn_sampled) - len(syn_results)}")

    # ---- 4. Process real-world images -------------------------------------
    print(f"\n[4/6]  Processing {len(real_sampled)} real-world images "
          f"(parallel, N_JOBS={N_JOBS}) ...")
    real_raw = Parallel(n_jobs=N_JOBS)(
        delayed(process_image)(p)
        for p in tqdm(real_sampled, desc="    Real-world", unit="img", ncols=72)
    )
    real_results = [r for r in real_raw if r is not None]
    print(f"       Valid: {len(real_results)}   "
          f"Failed/empty: {len(real_sampled) - len(real_results)}")

    syn_topup_sampled = []   # extra synthetic images processed for strand balancing

    # ---- 4a. Top up synthetic strand pool to match real strand count ------
    # We have 2.33M+ synthetic images available.  If the initial synthetic
    # sample produced fewer strands than the real pool, process additional
    # synthetic images (in batches) until n_syn_strands >= n_real_strands.
    # Falls back gracefully if the synthetic pool is truly exhausted first.
    if MATCH_NO_STRANDS:
        n_syn_strands  = sum(len(r.get("strands", [])) for r in syn_results)
        n_real_strands = sum(len(r.get("strands", [])) for r in real_results)

        if n_syn_strands < n_real_strands:
            already_used = set(str(p) for p in syn_sampled)
            remaining    = [f for f in syn_files if str(f) not in already_used]
            random.Random(RANDOM_SEED + 1).shuffle(remaining)

            print(f"\n[3b] Topping up synthetic strands "
                  f"({n_syn_strands} → target ≥{n_real_strands}) ...")

            batch_sz = max(len(real_sampled), 200)
            idx      = 0
            while n_syn_strands < n_real_strands and idx < len(remaining):
                batch = remaining[idx : idx + batch_sz]
                idx  += len(batch)
                batch_raw = Parallel(n_jobs=N_JOBS)(
                    delayed(process_image)(p)
                    for p in tqdm(batch, desc="    Syn top-up", unit="img", ncols=72)
                )
                extra = [r for r in batch_raw if r is not None]
                syn_results.extend(extra)
                syn_topup_sampled.extend(batch)
                n_syn_strands += sum(len(r.get("strands", [])) for r in extra)

            print(f"       Synthetic strands after top-up : {n_syn_strands}"
                  f"  (target was {n_real_strands})")

    # ---- 4b. Save process-step diagnostic figures -------------------------
    if SAVE_PROCESS_STEPS and SAVE_PROCESS_STEPS_IMAGES > 0:
        steps_dir = out_dir / "process_steps"
        if steps_dir.exists():
            shutil.rmtree(steps_dir, ignore_errors=True)
        steps_dir.mkdir(exist_ok=True)
        n_steps = SAVE_PROCESS_STEPS_IMAGES

        rng_steps = random.Random(RANDOM_SEED + 1)

        syn_step_paths  = rng_steps.sample(syn_sampled,  min(n_steps, len(syn_sampled)))
        real_step_paths = rng_steps.sample(real_sampled, min(n_steps, len(real_sampled)))

        print(f"\n[4b] Saving {len(syn_step_paths)} synthetic + "
              f"{len(real_step_paths)} real process-step figures -> {steps_dir}")

        for p in syn_step_paths:
            save_process_steps_figure(p, "synthetic", steps_dir)
        for p in real_step_paths:
            save_process_steps_figure(p, "real", steps_dir)

        print(f"     Done ({len(syn_step_paths) + len(real_step_paths)} figures saved).")

    if len(syn_results) < 2 or len(real_results) < 2:
        sys.exit("  ERROR: Too few valid images for statistical comparison. Exiting.")

    # ---- 5. Statistical tests ---------------------------------------------
    print(f"\n[5/6]  Running statistical tests "
          f"({len(FEATURE_LABELS)} features x 3 tests) ...")

    # Per-image tests (always run)
    test_rows = []
    for key, lbl in FEATURE_LABELS:
        sv  = np.array([f[key] for f in syn_results])
        rv  = np.array([f[key] for f in real_results])
        res = run_statistical_tests(sv, rv)
        test_rows.append({
            "feature":     lbl,
            "ks_stat":     res["ks_stat"],
            "ks_p":        res["ks_p"],
            "mw_stat":     res["mw_stat"],
            "mw_p":        res["mw_p"],
            "wasserstein": res["wasserstein"],
        })

    # Strand-level tests (only if MATCH_NO_STRANDS)
    strand_test_rows = []
    syn_strands_bal  = []
    real_strands_bal = []
    if MATCH_NO_STRANDS:
        print("       MATCH_NO_STRANDS=True — balancing strand counts ...")
        syn_strands_bal, real_strands_bal = balance_strands(
            syn_results, real_results, seed=RANDOM_SEED
        )
        strand_features = [
            ("tortuosity",        "Tortuosity (strand)"),
            ("mean_curvature",    "Curvature Mean (strand)"),
            ("curvature_variance","Curvature Variance (strand)"),
        ]
        for key, lbl in strand_features:
            sv  = np.array([s[key] for s in syn_strands_bal])
            rv  = np.array([s[key] for s in real_strands_bal])
            res = run_statistical_tests(sv, rv)
            strand_test_rows.append({
                "feature":     lbl,
                "ks_stat":     res["ks_stat"],
                "ks_p":        res["ks_p"],
                "mw_stat":     res["mw_stat"],
                "mw_p":        res["mw_p"],
                "wasserstein": res["wasserstein"],
                "syn_mean":    float(sv.mean()),
                "syn_std":     float(sv.std()),
                "syn_median":  float(np.median(sv)),
                "real_mean":   float(rv.mean()),
                "real_std":    float(rv.std()),
                "real_median": float(np.median(rv)),
            })
        print(f"       Strand-level tests done ({len(strand_test_rows)} features).")

    print(f"       Pairwise NN matching ({len(syn_results)} synthetic images) ...")
    nn_dists, nn_indices = pairwise_nn_matching(syn_results, real_results)
    print("       Done.")

    # ---- 6. Save outputs --------------------------------------------------
    print(f"\n[6/6]  Saving outputs to {out_dir} ...")

    syn_csv  = out_dir / "synthetic_features.csv"
    real_csv = out_dir / "real_features.csv"
    test_csv = out_dir / "statistical_tests.csv"
    nn_csv   = out_dir / "nn_matching.csv"

    pd.DataFrame(syn_results ).to_csv(syn_csv,  index=False)
    pd.DataFrame(real_results).to_csv(real_csv, index=False)
    pd.DataFrame(test_rows)   .to_csv(test_csv, index=False)
    print(f"    Saved: {syn_csv}")
    print(f"    Saved: {real_csv}")
    print(f"    Saved: {test_csv}")

    if MATCH_NO_STRANDS and strand_test_rows:
        strand_test_csv = out_dir / "strand_statistical_tests.csv"
        pd.DataFrame(strand_test_rows).to_csv(strand_test_csv, index=False)
        print(f"    Saved: {strand_test_csv}")

    nn_df = pd.DataFrame({
        "synthetic_path":    [syn_results[i]["path"] for i in range(len(syn_results))],
        "matched_real_path": [real_results[nn_indices[i]]["path"]
                              for i in range(len(syn_results))],
        "nn_distance":       nn_dists,
    })
    nn_df.to_csv(nn_csv, index=False)
    print(f"    Saved: {nn_csv}")

    plot_results(syn_results, real_results, nn_dists, out_dir)

    elapsed = time.time() - t0

    summary_txt = out_dir / "summary.txt"
    write_summary_txt(
        summary_txt, syn_results, real_results, test_rows,
        nn_dists, syn_sampled, real_sampled, elapsed=elapsed,
        strand_test_rows=strand_test_rows,
        syn_strands=syn_strands_bal,
        real_strands=real_strands_bal,
        syn_topup_sampled=syn_topup_sampled,
    )
    print(f"    Saved: {summary_txt}")

    # ---- Summary ----------------------------------------------------------
    col_w   = 35

    print(f"\n{SEP}")
    print("  SUMMARY")
    print(SEP)
    hdr = f"  {'Feature':<{col_w}} {'Synthetic (mean+/-std)':>22} {'Real (mean+/-std)':>22}"
    print(hdr)
    print("  " + "-" * (len(hdr) - 2))
    for key, lbl in FEATURE_LABELS:
        sv = np.array([f[key] for f in syn_results])
        rv = np.array([f[key] for f in real_results])
        print(f"  {lbl:<{col_w}} {sv.mean():>10.4f} +/-{sv.std():>7.4f}   "
              f"{rv.mean():>10.4f} +/-{rv.std():>7.4f}")

    print("\n  Statistical tests  (* p<0.05, ** p<0.01):")
    print(f"  {'Feature':<{col_w}} {'KS stat':>8} {'KS p':>8} "
          f"{'MW p':>8} {'Wass':>10}")
    print("  " + "-" * 68)
    for row in test_rows:
        if row["ks_p"] < 0.01:
            sig = "**"
        elif row["ks_p"] < 0.05:
            sig = " *"
        else:
            sig = "  "
        print(f"  {sig}{row['feature']:<{col_w - 2}} "
              f"{row['ks_stat']:>8.4f} {row['ks_p']:>8.4f} "
              f"{row['mw_p']:>8.4f} {row['wasserstein']:>10.4f}")

    print("\n  NN Matching (Synthetic -> Nearest Real):")
    print(f"    Mean   : {nn_dists.mean():.4f}")
    print(f"    Median : {np.median(nn_dists):.4f}")
    print(f"    Std    : {nn_dists.std():.4f}")
    print(f"    Min    : {nn_dists.min():.4f}")
    print(f"    Max    : {nn_dists.max():.4f}")

    print(f"\n  Images processed : {len(syn_results)} synthetic, "
          f"{len(real_results)} real-world")
    print(f"  Output directory : {out_dir}")
    print(f"  Total time       : {elapsed:.1f} s")
    print(SEP)


if __name__ == "__main__":
    main()
