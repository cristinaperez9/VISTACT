
"""
Same output images from pix2pix as .tif files 
"""

import os
import argparse
import glob as glob
from PIL import Image
from tqdm import tqdm


def save_tif(results_dir: str):
    output_dir = os.path.join(results_dir, 'images_tif')
    os.makedirs(output_dir, exist_ok=True)

    imlist = glob.glob(os.path.join(results_dir, '*fake_B.png'))

    for ifile in tqdm(imlist):
        
        img = Image.open(ifile)
        basename = os.path.basename(ifile).replace('_fake_B.png', '.tif')
        out_path = os.path.join(output_dir, basename)
        img.save(out_path)

    print("All images saved as .tif in", output_dir)


if __name__ =='__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--results_dir',type=str,help='Output directory of pix2pix.')
    args = parser.parse_args()
    save_tif(results_dir=args.results_dir)




