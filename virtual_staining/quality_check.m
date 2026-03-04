
% Check every patch for quality check.
% Visual inspection that only well-registered patches are used.

% Specify the output directories (e.g., Patches_512) obtained from
% create_dataset.m
pthCT_patch='';
pthHE_patch='';

outpthCT=[pthCT_patch,'HighQuality/']; if ~isfolder(outpthCT);mkdir(outpthCT);end
outpthHE=[pthHE_patch,'HighQuality/']; if ~isfolder(outpthHE);mkdir(outpthHE);end

imlist=dir([pthCT_patch,'*.tif']);
for kk=1:length(imlist)
    fprintf("Image %s \n",imlist(kk).name)
    CT=imread([pthCT_patch,imlist(kk).name]);
    figure;imshow(CT);
    HE=imread([pthHE_patch,imlist(kk).name]);
    figure;imshow(HE);
    figure(kk);imshowpair(imcomplement(CT),rgb2gray(HE));
    prompt = "Keep image? y/n [y]: ";
    txt = input(prompt,"s");
    if isempty(txt)
    txt = 'y';
    end
    if strcmp(txt,'y')
        imwrite(CT,[outpthCT,imlist(kk).name])
        imwrite(HE,[outpthHE,imlist(kk).name])
    end
    close all
end 



