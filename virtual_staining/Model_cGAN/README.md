# cGAN architecture using *pix2pix* framework

I used the following repository that has a pytorch implementation:
```bash
git clone https://github.com/junyanz/pytorch-CycleGAN-and-pix2pix.git
```
Following the guidelines included in the above repository, do the following:
```bash
cd pytorch-CycleGAN-and-pix2pix
conda env create -f environment.yml
conda activate pytorch-CycleGAN-and-pix2pix
```
## Parameters
If a parameter is not specified below is because the default option was used.

During training time:

In *base_options.py*:

- --batch_size = 5
- --num_threads = 0
- --preprocess = none
- --dataset_mode = aligned
- --input_nc=1
- --model=pix2pix

In *train_options.py*
- --no_html=False

During test time:

In *base_options.py*:

- --epoch: 150 (select the best epoch to perform inference)
- --load_size: 2560 (when infrence in the axial slices of µCT volumes) or 512 (when inference in the validation set)

In *test_options.py*:
- --num_test= [specify the number of images in the validation set or the number of axial slices of the µCT volume] 




These are the commands I run:

### 1. Save dataset as required by pix2pix
```bash
python datasets/combine_A_and_B.py --fold_A /das/work/p20/p20847/DeepLearning/Datasets/StyleTransferEVG/pix2pix/A/ --fold_B /das/work/p20/p20847/DeepLearning/Datasets/StyleTransferEVG/pix2pix/B/ --fold_AB /das/work/p20/p20847/DeepLearning/Datasets/StyleTransferEVG/pix2pix/
```

### 2. Train the network
```bash
python train.py --dataroot /das/work/p20/p20847/DeepLearning/Datasets/StyleTransferEVG/pix2pix/ --name mydata512_pix2pix_v2 --model pix2pix --direction AtoB
```
#### Visualization 
The generator and discriminator losses during training can be visualized using visdom. Please, run the following:
```bash
python -m visdom.server -port 8097
```
You will obtain an URL. Please, copy this URL onto your login node. Despite the training was performed in ra-gpu-002, this command was run in the loging node (e.g. ra-l-002) to visualize the results in Firefox browser.

### 3. Inference
```bash
python test.py --dataroot  /das/work/p20/p20847/DeepLearning/Datasets/StyleTransferEVG/pix2pix/ --name mydata512_pix2pix --model pix2pix --direction AtoB
```

