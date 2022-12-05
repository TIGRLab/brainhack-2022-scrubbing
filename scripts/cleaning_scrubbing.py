'''
Perform basic confound cleaning followed by Powers (2014) style scrubbing
'''

import argparse

import os
import json
import nilearn
from nilearn import image as nimg
from nilearn import plotting as nplot
import numpy as np
import nibabel as nib
import pandas as pd


def simplify_ciftify_cols(config):
    '''
    Squish ciftify sq, sqtd, and td cols into
    single --cf-cols argument
    '''

    new_config = {k: v for k, v in config.items() if "cols" not in k}

    all_cols = config['--cf-cols'].split(',')

    if "--cf-sq-cols" in config.keys():
        all_cols += [f"{f}_power2" for f in config['--cf-sq-cols'].split(',')]

    if "--cf-td-cols" in config.keys():
        all_cols += [f"{f}_derivative1" for f in config['--cf-td-cols'].split(',')]

    if "--cf-sqtd-cols" in config.keys():
        all_cols += [
            f"{f}_derivative1_powers2" for f in config['--cf-sqtd-cols'].split(',')]

    new_config['--cf-cols'] = ','.join(all_cols)

    return new_config


def main():

    p = argparse.ArgumentParser(
        description="Perform basic Powers (2014) style scrubbing followed"
        " by confound cleaning")
    p.add_argument("func_img",
                   help="Path to functional nifti image",
                   type=str)
    p.add_argument("confounds",
                   help="Input confound file to be cleaned",
                   type=str)
    p.add_argument("config",
                   help="Cleaning configuration file"
                   " (see: Ciftify clean config)",
                   type=str)
    p.add_argument("--fd_threshold",
                   help="Threshold of motion (mm) to remove TR",
                   default= 0.5,
                   type=float)
    p.add_argument("--scrubs",
                   help="The maximum length (TR) of the island",
                   default=5,
                   type=int)
    p.add_argument("--t_r",
                   help="TR",
                   default=2,
                   type=float)
    p.add_argument("output_file", help="Name of output image", type=str)

    args = p.parse_args()
    with open(args.config, 'r') as f:
        config = json.load(f)
    config = simplify_ciftify_cols(config)
    dummy_trs = config.get('--drop-dummy-TRs')
    detrend = config.get('--detrend')
    standardize = config.get('--standardize')
    low_pass = config.get('--low-pass')
    high_pass = config.get('--high-pass')

    #config = simplify_ciftify_cols("/KIMEL/tigrlab/scratch/jcyu/SPASD_code/SPASD_rest_clean.json")

    # Read the nifti file with functional images
    # Get confounds
    func_file = nimg.load_img(args.func_img)
    confounds_file = pd.read_csv(args.confounds, sep = '\t')
    # Remove dummy scans
    if dummy_trs:
        func_img = func_file.slicer[:,:,:,dummy_trs:]
        confounds_file = confounds_file.loc[dummy_trs:]
    else:
        func_ing = func_file
    img_size = func_img.shape
    signal_img = func_img.get_fdata().reshape(-1,img_size[-1]).T

    confounds_input = confounds_file.values

    # Extract FD
    all_FD = confounds_file['framewise_displacement']
    ## The arguments for _optimize_scrub
    motion_outlier_index = np.where(all_FD > args.fd_threshold)[0]
    n_scans = len(all_FD)

    # Generate the censor_mask
    from nilearn.interfaces.fmriprep.load_confounds_scrub import _optimize_scrub
    censor_mask = _optimize_scrub(motion_outlier_index, n_scans, args.scrubs)

    # Generate the samplemask
    ref_vec = set(range(n_scans))
    censor_idx = set(censor_mask)
    sample_mask = np.array(sorted(list(ref_vec - censor_idx)))

    #Clean with scrubbing!
    clean_img = nilearn.signal.clean(signal_img,
                                 confounds=confounds_input,
                                 detrend=detrend,
                                 standardize=standardize,
                                 low_pass=low_pass,
                                 high_pass=high_pass,
                                 t_r=args.t_r,
                                 sample_mask = sample_mask,
                                 filter = 'butterworth')

    # Reshape the image file into an array of the original size
    clean_img_array = clean_img.T.reshape(*img_size[:-1], len(sample_mask))

    # Save it as a Nifti file
    clean_img_nifti = nib.Nifti1Image(clean_img_array.astype(np.float64), func_img.affine)
    nib.save(clean_img_nifti, f'{args.output_file}')


if __name__ == '__main__':
    main()