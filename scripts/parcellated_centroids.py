from __future__ import annotations

import enum
import argparse
import nibabel as nib
import numpy as np

from typing import TYPE_CHECKING, Optional, Tuple
from scipy.spatial.distance import cdist

if TYPE_CHECKING:
    from nibabel.gifti.gifti import GiftiImage
    from nibabel.cifti2.cifti2 import CiftiImage
    from numpy import ndarray


class Hemisphere(str, enum.Enum):
    LEFT = "left"
    RIGHT = "right"


class CiftiStruct(str, enum.Enum):
    STRUCTURE_CORTEX_LEFT = "CIFTI_STRUCTURE_CORTEX_LEFT"
    STRUCTURE_CORTEX_RIGHT = "CIFTI_STRUCTURE_CORTEX_RIGHT"


CIFTI_HEMI_MAP = {
    CiftiStruct.STRUCTURE_CORTEX_LEFT: Hemisphere.LEFT,
    CiftiStruct.STRUCTURE_CORTEX_RIGHT: Hemisphere.RIGHT,
}

HEMI_CIFTI_MAP = {
    Hemisphere.LEFT: CiftiStruct.STRUCTURE_CORTEX_LEFT,
    Hemisphere.RIGHT: CiftiStruct.STRUCTURE_CORTEX_RIGHT
}


def gifti_to_mesh(gifti: GiftiImage) -> tuple[ndarray, ndarray]:
    '''
    Extract vertices and triangles from GIFTI surf.gii
    file
    Arguments:
        gifti (GiftiImage): Input GiftiImage
    '''

    v, t = gifti.agg_data(('pointset', 'triangle'))
    return v.copy(), t.copy()


def surface_centroids(surf: GiftiImage,
                      hemi: Hemisphere,
                      dlabel: CiftiImage,
                      vertex_areas_file: Optional[str] = None,
                      map_index: Optional[int] = 0) -> Tuple[ndarray, ndarray]:
    """
    Extract centroids from a surface
    """
    # Get vertices
    v, _ = gifti_to_mesh(surf)

    if vertex_areas_file:
        areas = nib.load(vertex_areas_file).agg_data()
    else:
        areas = np.ones(v.shape[0], dtype=float)

    # Get brain model to determine which labels to pull in
    bm_axis = dlabel.header.get_axis(1)
    matches = [(slx, bm.vertex) for name, slx, bm in bm_axis.iter_structures()
               if CIFTI_HEMI_MAP[name] == hemi]

    if not matches:
        raise ValueError(f"Did not find {hemi} hemisphere in {dlabel}!")
    slx = matches[0][0]

    label_ax = dlabel.header.get_axis(0)
    selected_map = label_ax[map_index]
    _, label_map, _ = selected_map

    labels = dlabel.get_fdata().astype(int)[map_index][slx]

    sort_inds = np.argsort(labels)
    sorted_labels = labels[sort_inds]
    sorted_areas = areas[sort_inds]
    sorted_coords = v[sort_inds, :]

    coord_x_area = sorted_areas[:, None] * sorted_coords
    parcel_weights = np.bincount(sorted_labels, weights=sorted_areas)
    X = np.bincount(sorted_labels, weights=coord_x_area[:, 0])
    Y = np.bincount(sorted_labels, weights=coord_x_area[:, 1])
    Z = np.bincount(sorted_labels, weights=coord_x_area[:, 2])
    centroids = np.c_[X, Y, Z] / parcel_weights[:, None]
    nonzero_parcels = np.where(parcel_weights)[0]
    return np.unique(sorted_labels), centroids[nonzero_parcels, :]


def main():

    parser = argparse.ArgumentParser(
        description="Compute centroids from a parcellation and a surface")

    parser.add_argument("dlabel", type=str, help="Parcellation dlabel file")
    parser.add_argument("--left-surf", type=str, help="GIFTI surface file")
    parser.add_argument("--right-surf", type=str, help="GIFTI surface file")
    parser.add_argument(
        "--left-vertex-areas",
        type=str,
        help="Left Vertex areas for weighting centroid computation")
    parser.add_argument(
        "--right-vertex-areas",
        type=str,
        help="Right Vertex areas for weighting centroid computation")
    parser.add_argument("--map-index",
                        type=int,
                        help="Map index to calculate"
                        " centroids of in dlabel, default is to use the first",
                        default=0)
    parser.add_argument(
        "--out-centroids",
        type=str,
        help="File output"
        " containing centroid for each parcel in a dlabel file")
    parser.add_argument("--out-distances",
                        type=str,
                        help="File output containing distance matrix")

    args = parser.parse_args()

    dlabel = nib.load(args.dlabel)
    _, all_parcels, _ = dlabel.header.get_axis(0)[args.map_index]
    all_parcel_nums = all_parcels.keys()

    # Array to store results (N_PARCELS X 3)
    output_array = np.zeros((max(all_parcel_nums) + 1, 3), dtype=float)

    left_centroids = np.empty((0, 3))
    left_keys = []
    if args.left_surf:
        left_keys, left_centroids = surface_centroids(nib.load(args.left_surf),
                                                      Hemisphere.RIGHT, dlabel,
                                                      args.left_vertex_areas,
                                                      args.map_index)
    right_centroids = np.empty((0, 3))
    right_keys = []
    if args.right_surf:
        right_keys, right_centroids = surface_centroids(
            nib.load(args.right_surf), Hemisphere.LEFT, dlabel,
            args.right_vertex_areas, args.map_index)

    for key, row in zip(left_keys, left_centroids):
        output_array[key, :] = row

    for key, row in zip(right_keys, right_centroids):
        if output_array[key].any():
            output_array[key, :] = (output_array[key] + row) / 2
        else:
            output_array[key, :] = row

    # Return this
    if args.out_centroids:
        np.save(args.out_centroids, output_array)

    if args.out_distances:
        distance_matrix = cdist(output_array, output_array, 'euclidean')
        np.save(args.out_distances, distance_matrix)


if __name__ == '__main__':
    main()
