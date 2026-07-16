from graphviz import Digraph

# ----- Graph setup ---------------------------------------------------------
dot = Digraph(comment="Methodology Flowchart", format='pdf')   # <- PDF output
dot.attr(rankdir='TB', fontsize='12')

# eliminate Graphviz’s default page padding (0.055in) and extra canvas
# (optional) transparent background if you embed the PDF on coloured paper
# dot.graph_attr.update(bgcolor="transparent")
# force exact page size (A4 here) and keep our zero-margin settings
dot.graph_attr.update(
    size="8.27,11.69!",   # width,height in inches – “!” forces exact fit
    margin="0",
    pad="0",
    ratio="compress"      # uniformly scale the graph to use all available space
)

# ----- Synthetic crack generation -----------------------------------------
dot.node('A', 'Random noise image\n(uniform / Gaussian)')
dot.node('B', 'Dynamic Programming\ncrack strand\n(min/max energy)')
dot.node('C', 'Synthetic crack strand\n(1-pixel skeleton)')
dot.node('D', 'Morphological dilation\n(variable width)')
dot.node('E', 'Geometric transformations\nAffine / Projective /\nPiecewise Linear /\nPolynomial d=2-4 /\nLocal Weighted Mean')
dot.node('F', 'Elastic deformation\n(Random displacement\n+ Gaussian smoothing)')
dot.node('G', 'Synthetic crack images')

# ----- Training dataset & classification -----------------------------------
dot.node('H', 'Non-crack patches\n(from real images)')
dot.node('I', 'Labelled training set\n(crack & non-crack)')
dot.node('J', 'Feature extraction\n5 geometric features')
dot.node('K', 'Train classifiers\nANN  |  k-NN  |  SVM')

# ----- Crack detection on real images --------------------------------------
dot.node('L', 'Real concrete images')
dot.node('M', 'Crack detection filters\nMFAT | Vesselness | Morphological')
dot.node('N', 'Binarization\n(Otsu threshold)')
dot.node('O', 'Connected components')
dot.node('P', 'Classifier prediction\n(crack / non-crack)')
dot.node('Q', 'Final crack map')

# ----- Edges ---------------------------------------------------------------
dot.edges(['AB', 'BC', 'CD', 'DE', 'EF', 'FG'])
dot.edge('G', 'I')
dot.edge('H', 'I')
dot.edge('I', 'J')
dot.edge('J', 'K')
dot.edge('L', 'M')
dot.edge('M', 'N')
dot.edge('N', 'O')
dot.edge('O', 'P')
dot.edge('P', 'Q')
dot.edge('K', 'P', label='model')

# ----- Render --------------------------------------------------------------
outfile = 'methodology_flowchart'  # no extension here
dot.render(outfile, cleanup=True)  # produces methodology_flowchart.pdf
