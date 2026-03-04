# ---------------------------------------------------------------------------------------------------------
# Script to calculate the lpips (Learned Perceptual Image Patch Similarity) metric.
# This script is from the following repository:
# https://github.com/richzhang/PerceptualSimilarity
# All credit goes to the authors of such repository. I only included the final lines to calculate what is 
# the mean (± standard deviation) lpips of a set of images. The original code only provided the lpips metric 
# for each individual pair of images
# ---------------------------------------------------------------------------------------------------------
# Cristina Almagro-Pérez, ETH Zürich, 2023
# ---------------------------------------------------------------------------------------------------------


import argparse
import os
import lpips
import statistics
import numpy as np

parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-d0','--dir0', type=str, default='./imgs/ex_dir0')
parser.add_argument('-d1','--dir1', type=str, default='./imgs/ex_dir1')
parser.add_argument('-o','--out', type=str, default='./imgs/example_dists.txt')
parser.add_argument('-v','--version', type=str, default='0.1')
parser.add_argument('--use_gpu', action='store_true', help='turn on flag to use GPU')

opt = parser.parse_args()

## Initializing the model
loss_fn = lpips.LPIPS(net='alex',version=opt.version)
if(opt.use_gpu):
	loss_fn.cuda()

# crawl directories
f = open(opt.out,'w')
files = os.listdir(opt.dir0)

# Added by me to provide with the mean value of the whole validation set
lpips_all=[]

for file in files:
	if(os.path.exists(os.path.join(opt.dir1,file))):
		# Load images
		img0 = lpips.im2tensor(lpips.load_image(os.path.join(opt.dir0,file))) # RGB image from [-1,1]
		img1 = lpips.im2tensor(lpips.load_image(os.path.join(opt.dir1,file)))

		if(opt.use_gpu):
			img0 = img0.cuda()
			img1 = img1.cuda()

		# Compute distance
		dist01 = loss_fn.forward(img0,img1)
		lpips_all.append(dist01.detach().cpu().numpy()[0][0][0][0])
		print('%s: %.3f'%(file,dist01))
		f.writelines('%s: %.6f\n'%(file,dist01))

# Calculate mean value
print(lpips_all)
print(type(lpips_all))
lpips_mean=statistics.mean(lpips_all)
print('%s: %.3f'%('The average lpips is:',lpips_mean))
f.writelines('%s: %.6f\n'%('The average lpips is:',lpips_mean))
# Calculate standard deviation
lpips_all = np.array(lpips_all)
lpips_std = np.std(lpips_all)
#lpips_std=statistics.stdev(lpips_all)
print('%s: %.3f'%('The std lpips is:',lpips_std))
f.writelines('%s: %.6f\n'%('The std lpips is:',lpips_std))




f.close()
