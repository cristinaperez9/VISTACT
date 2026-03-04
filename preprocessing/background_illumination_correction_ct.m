function background_illumination_correction_ct(varargin)

% -------------------------------------------------------------------------
% Background illumination correction in CT.
% Correction of the 'local tomography artefact'.
% -------------------------------------------------------------------------
% Cristina Almagro-Pérez, ETH Zürich, 2023

% Please provide the following:
% 1. pth_ct: (str) directory containing all axial slices of a uCT volume; 
%         the images in the directory are expected to be in 16-bit format.
% 2. perc_norm (logical: 1/0). If 1, the images are also normalized using
%               the 1 and 99 percentiles. It is useful if images are used 
%               as the input of a deep learning algorithm.
% 3. remove_bubbles (logical: 1/0). If 1, air bubbles will be masked with
%               the mode value of the image. If the images do not contain 
%               air bubbles I will set it to 0.

perc_norm=1;
remove_bubbles=1;


p = struct( ...
        'pth_ct', '', ...
        'pp_pix2pix', 0 ... 
    );

    if mod(numel(varargin), 2) ~= 0
        error('Arguments must be name–value pairs.');
    end

    for k = 1:2:numel(varargin)
        name  = varargin{k};
        value = varargin{k+1};

        if isfield(p, name)
            p.(name) = value;
        else
            error('Unknown parameter name: %s', name);
        end
    end


imlist=dir([p.pth_ct,'*.tif']);
outpth=[p.pth_ct,'preprocessed/']; if ~isfolder(outpth);mkdir(outpth);end

for kk=1:length(imlist)
    
    fprintf("Processing image %d \n",kk)
    im=imread([p.pth_ct,imlist(kk).name]);

    % Mask air bubbles in CT images
    if remove_bubbles
    myim=im(:);myim=myim(myim~=0);myim=myim(myim~=max(myim));
    val = mode(myim(:));
    mybw=im==0; 
    se = strel('disk',12);
    mybw=imdilate(mybw,se);
    im(mybw)=val;
    end
    
    % Background illumination correction
    % strcut_element_bg used with images of 1.63 um/pixel of dimensions 2560 x 2560 pixels
    struct_element_bg=round(7*2.54);
    im=bg_correction(im,struct_element_bg);
    
    % Percentile normalization
    if perc_norm
        min_val=single(prctile(im(:),1));
        max_val=single(prctile(im(:),99));
        im = (single(im) - min_val) ./ (max_val - min_val);
    end

    if p.pp_pix2pix
        I8 = im2uint8(im);         
        I_rgb = repmat(I8, [1 1 3]); % size: [H W 3], type: uint8
        white_img = uint8(255 * ones(size(I_rgb), 'like', I_rgb));
        im = [I_rgb, white_img];
        % Make sure the subfolder exists
        out_sub = fullfile(outpth, 'test');
        if ~exist(out_sub, 'dir')
            mkdir(out_sub);
        end
        imwrite(im, fullfile(out_sub, imlist(kk).name));
       
    else
        % Save image in 16-bit format
        im = im2uint16(im);
        imwrite(im,[outpth,imlist(kk).name]);
    end
    
    

end


end


% -------------------------------------------------------------------------
% Auxiliary function
% -------------------------------------------------------------------------
function [img_orig1]=bg_correction(img_orig1,struct_element_bg)

    mmm = size(img_orig1,1); 
    nnn = size(img_orig1,2); 

    [YY, XX] = meshgrid(1:nnn, 1:mmm);
    z1 = double(imerode(img_orig1,strel('disk',struct_element_bg)));
    [muhat,sigmahat] = normfit(z1(:));
    z1(z1<muhat-3*sigmahat | z1>muhat+3*sigmahat) = NaN;
    
    X = [ones(mmm*nnn, 1), YY(:), XX(:)];
    X1 = X(~isnan(z1(:)),:);

    M = X1\z1(~isnan(z1(:)));
    back = reshape(X*M, mmm, nnn);
    img_orig1 = double(img_orig1)-back;
    img_orig1 = img_orig1 - min(img_orig1(:));
    img_orig1 = uint16(img_orig1);

end