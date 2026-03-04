
############################################################################################
# Convert histologies from .svs format (raw microscopy format) to readable format in python 
############################################################################################
# Cristina Almagro-Perez, February 2023, PSI, Switzerland
############################################################################################

import glob
import os
import argparse
import slideio  # ('pip install slideio' on terminal)
from PIL import Image


###########################################################################################
# Auxiliary function
###########################################################################################

def change_resolution(pth0, nm_outpth, resHisto, resNew=None, factor=None):
    """
    Convert .svs histology slides to .tif at a new resolution.

    Parameters
    ----------
    pth0 : str
        Directory containing the serial histological sections in .svs format.
    nm_outpth : str
        Name of the output subdirectory where .tif files will be saved.
    resHisto : float
        Original resolution of the histology in µm/pixel.
    resNew : float, optional
        New desired resolution in µm/pixel. Either resNew or factor must be provided.
    factor : float, optional
        Rescaling factor such that factor = resNew / resHisto.
    """
    imlist = glob.glob(os.path.join(pth0, '*.svs'))  # List of '.svs' files
    if not imlist:
        print(f"No .svs files found in {pth0}")
        return

    outpth = os.path.join(pth0, nm_outpth)
    os.makedirs(outpth, exist_ok=True)

    # Determine effective factor
    if factor is None:
        if resNew is None:
            raise ValueError("Either resNew or factor must be provided.")
        factor_eff = resNew / resHisto
    else:
        factor_eff = factor

    for count, image_path in enumerate(imlist):
        print(f"Downsampling image {count+1}/{len(imlist)} with name: {os.path.basename(image_path)}")
        slide = slideio.open_slide(image_path, 'SVS')
        scene = slide.get_scene(0)
        print(slide.num_scenes, scene.name, scene.rect, scene.resolution)

        # Read metadata
        raw_string = slide.raw_metadata
        print(raw_string.split("|"))

        width20x = scene.rect[2]
        output_name = os.path.basename(image_path).replace(".svs", ".tif")

        # Calculate new width
        width_new_res = round(width20x / factor_eff)
        image = scene.read_block(size=(width_new_res, 0))
        print("Image dimensions in the new resolution:", image.shape)

        # Save image in tif format
        output_datafile = os.path.join(outpth, output_name)
        im = Image.fromarray(image)
        im.save(output_datafile)


###########################################################################################
# Command-line interface
###########################################################################################

def parse_args():
    parser = argparse.ArgumentParser(
        description="Convert .svs histology slides to .tif at a new resolution."
    )

    parser.add_argument(
        "--pth",
        type=str,
        required=True,
        help="Directory containing the serial histological sections in .svs format.",
    )

    parser.add_argument(
        "--nm_outpth",
        type=str,
        required=True,
        help="Name of the output subdirectory where .tif files will be saved "
             "(e.g. 'res_microCT', '1x').",
    )

    parser.add_argument(
        "--resHisto",
        type=float,
        required=True,
        help="Original resolution of the histology in µm/pixel (e.g. 0.5).",
    )

    # Mutually exclusive: user must specify either resNew OR factor
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--resNew",
        type=float,
        help="New desired resolution in µm/pixel. "
             "factor will be computed as resNew / resHisto.",
    )
    group.add_argument(
        "--factor",
        type=float,
        help="Rescaling factor such that factor = resNew / resHisto.",
    )

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    change_resolution(
        pth0=args.pth,
        nm_outpth=args.nm_outpth,
        resHisto=args.resHisto,
        resNew=args.resNew,
        factor=args.factor,
    )