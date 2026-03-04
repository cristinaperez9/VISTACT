# Segmentation after histology-guided µCT virtual staining

The scripts are supposed to be run the in the following order:

1.: **segment_after_style_transfer.py** : use colour deconvolution on EvG virtually stained uCT volumes to segment collagen.

2.A : **evaluate_segmentation.py** : calculate Recall, Precision, DSC, and Accuracy using manually annotated masks as reference.

2.B : **applications.py** : find vascular remodelled regions of pulmonary hypertension by projecting the collagen masks.
