from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import numpy as np

def compute_optimal_rotation(L, L_true, scale=True):
    """Find a rotation matrix R such that F_inf.dot(R) ~= F_true"""
    from scipy.linalg import orthogonal_procrustes
    R = orthogonal_procrustes(L, L_true)[0]

    if scale:
        Lp = L.dot(R)
        s = (L_true*Lp).sum() / (Lp*Lp).sum()
        return R*s
    else:
        return R
    