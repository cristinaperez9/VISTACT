% -------------------------------------------------------------------------
% Generate 3D collagen segmentation masks
% -------------------------------------------------------------------------
% Cristina Almagro-Perez, ETH Zürich, 2023
% -------------------------------------------------------------------------
clear;clc;close all;
current_directory = pwd;
[parent_directory, ~, ~] = fileparts(current_directory);
path(path,[parent_directory,'/base/']);
% -------------------------------------------------------------------------
% Please select the following:
% 1. option1 : from the virtually stained images, gnerate the collagen
% channel after colour deconvolution and segmentation masks 
% 2. option2: Create 3D volume of collagen + postprocess in 3D. Note:
% option2 requires to run option1 before
option1=0;
option2=1;
% -------------------------------------------------------------------------
% Please provide the following:
% 1. pth_pred (str) directory containing the virtually stained images of % volume. Example: (more examples at the bottom of the script)
pth_pred='';
% 2. start_slice (int) and finish_slice (num) - first and last image that % you want to perfom segmentation on (for many volumes there are many
% slices that do not contain any tissue, skipping those will speed up the process)
imlist=dir([pth_pred,'*.tif']);
start_slice=1;
finish_slice=length(imlist);

% -------------------------------------------------------------------------
if option1

    outpth_CC_pred = [pth_pred,'Collagen_Channel/'];if ~isfolder(outpth_CC_pred);mkdir(outpth_CC_pred);end
    outpth_mask_pred = [outpth_CC_pred,'MASK/'];if ~isfolder(outpth_mask_pred);mkdir(outpth_mask_pred);end
    imlist=dir([pth_pred,'*.tif']);
    imlist=natsortfiles(imlist);
    
    for kk=start_slice:finish_slice 
                
        fprintf("Analyzing image %s \n", imlist(kk).name);
    
        % Load the CT stained as EVG
        im=imread([pth_pred,imlist(kk).name]);
    
        % Perform colour deconvolution
        defaultEVG_Collagen=[0.25201, 0.81021, 0.52919; ...    
                             0.57806, 0.63045, 0.518046;...
                             0.5183, 0.5967, 0.6125];
    
        StainingVectorID=defaultEVG_Collagen';
        [~,~,~,imH,imA,imbg,~,~,~,~] = Colour_Deconvolution2(double(im(:,:,1)), double(im(:,:,2)), double(im(:,:,3)), StainingVectorID,0);
        imH(imH>255) = 255;imbg(imbg>255) = 255;imA(imA>255) = 255;
        imH(imH<0) = 0;imbg(imbg<0) = 0;imA(imA<0) = 0;
        imH = floor(imH);imbg = floor(imbg);imA = floor(imA);
        imH=uint8(imH);imA=uint8(imA);imbg=uint8(imbg);
        imwrite(imH,[outpth_CC_pred,imlist(kk).name(1:end-4),'.tif']);
    
        % Segmentation masks of the collagen channel (from microCT)
        imHg = imgaussfilt(imH,2);
        mask_pred = imHg<220;
        % Postprocessing
        mask_pred1 = imclose(mask_pred,strel('disk',6));
        mask_pred2 = bwareaopen(mask_pred1,300);
        mask_pred3 = imdilate(mask_pred2,strel('disk',3));
        mask_pred3=uint8(mask_pred3);

        % Correct the mask
        mask1=bwareaopen(mask_pred3,3000);
        
        % Define mask of microCT ring - only pixels inside will be considered
        radius = floor(size(mask1,1)/2)+1;
        [X, Y] = meshgrid(1:size(mask1,1), 1:size(mask1,2));
        distances = sqrt((X - (size(mask1,1)/2 + 0.5)).^2 + (Y - (size(mask1,2)/2 + 0.5)).^2);
        ringmask = distances <= radius;
        mask1=uint8(mask1.*ringmask);
        imwrite(mask1,[outpth_mask_pred,imlist(kk).name(1:end-4),'.tif']);

    end 
end

% -------------------------------------------------------------------------
% Create 3D volume of collagen + postprocess in 3D (before saving)
% -------------------------------------------------------------------------
if option2
    % Define location where images are saved
    pth=[pth_pred,'/Collagen_Channel/MASK/'];
    imlist=dir([pth,'*.tif']);
    vol=uint8(zeros(2560,2560,length(imlist)));
    fprintf("Creating volume of %d axial slices \n",length(imlist));
    for kk=1:length(imlist)
        vol(:,:,kk)=imread([pth,imlist(kk).name]);
    end
    % Save raw volume (in case it is needed)
    save([pth,'vol_raw.mat'],'vol','-v7.3');
    % Preprocess volume
    % Step I - subsample volume to facilitate rendering in Paraview
    vol=vol(1:2:end,1:2:end,:);
    % Step II: Median filter to remove small objects only present in one slice and not in the slice above or below
    vol = medfilt1(single(vol),3,[],3); 
    vol=logical(vol);
    vol=imclose(vol,strel('sphere',3)); % 3 slices

    % Save postprocess 3D collagen mask in multiple file data types
    % MATLAB
    vol=uint8(vol);
    save([pth,'vol_pp.mat'],'vol','-v7.3');
    % Save as nrrd file
    nrrdWriter([pth,'vol_pp.nrrd'],vol,[1, 1, 1],[0,0,0],'raw');

end

