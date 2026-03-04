function evaluate_virtual_staining(varargin)

% -------------------------------------------------------------------------
% Evaluate VISTACT with PSNR (Peak-Signal-to-Noise-Ratio), SSIM (Structural
% Similarity Index Measure), and MSE (Mean Squared Error).
% -------------------------------------------------------------------------
% Cristina Almagro-Pérez, ETH Zürich, 2023

% Please provide the following:
% 1. pth_gt (str): location of ground truth histology image patchesof the
%                  test set.
% 2. pth_pred (str): location of VISTACT images after virtual staining.


p = struct( ...
        'pth_gt', '', ...
        'pth_pred', '' ...
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




imlist=dir([p.pth_gt,'*.tif']);

% Initialize metrics
mse_all=zeros(1,length(imlist));
ssim_all=zeros(1,length(imlist));
psnr_all=zeros(1,length(imlist));

for kk=1:length(imlist)
    
    im_pred=imread([p.pth_pred,imlist(kk).name(1:end-4),'_fake_B.png']);
    im_gt=imread([p.pth_gt,imlist(kk).name]);
    
    % MSE
    mse_all(1,kk) = immse(im_pred,im_gt);
    
    % SSIM - calculated in grayscale images
    EVGg=rgb2gray(im_pred);
    EVGGTg=rgb2gray(im_gt);
    ssim_all(1,kk) = ssim(EVGg,EVGGTg); %order matters

    %PSNR
    % A greater value indicates better image quality
    % Max value for uint8 images is 255
    [peaksnr,snr] = psnr(im_pred,im_gt); %order matters
    psnr_all(1,kk)=peaksnr;

end

%% Calculate the mean values and the standard deviation
fprintf("The mean value for MSE is %f and the std %f \n", mean(mse_all),std(mse_all));
fprintf("The mean value for SSIM is %f and the std %f \n", mean(ssim_all),std(ssim_all));
fprintf("The mean value for PSNR is %f and the std %f \n", mean(psnr_all),std(psnr_all));
end