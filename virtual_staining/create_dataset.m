function create_dataset(varargin)

% -------------------------------------------------------------------------
% Create dataset for style transfer (µCT --> EVG)
% This script takes as input the registered and preprocessed µCT -
% histology image pairs, and prepares image patches for model training.
% -------------------------------------------------------------------------
% Cristina Almagro-Pérez, ETH Zürich, 2023 
% -------------------------------------------------------------------------

% Add base directory for dependencies
current_directory = pwd;
[parent_directory, ~, ~] = fileparts(current_directory);
path(path,[parent_directory,'/base/']);
warning('off');

% Parse name–value pairs into a struct
    p = struct( ...
        'pth_ct', '', ...
        'pth_histo', '',  ...
        'patch_sz', ''  ...
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

 
    generate_image_patches(p.pth_histo,p.pth_ct,p.patch_sz,0)

end





% -------------------------------------------------------------------------
% Functions
% -------------------------------------------------------------------------


function generate_image_patches(pthHE,pthCT,stepSize,gauss_sm)
% -------------------------------------------------------------------------
% This function crops the µCT - histology image pairs into patches of
% specified dimensions. Patches with less than 70% of the pixels outside the 
% inscribed circle of the image are excluded. It also checks the registration 
% accuracy (only patches with a correlation coefficient > 0.45 are saved). 
% It gives the option to apply a gaussian filter to the histology images to
% bring the images closer to the µCT images.
% -------------------------------------------------------------------------

% stepSize (int): size of the cropped patches (512 was used in my case)
% pthHE (str): directory containing the registered histology images (in my case, 2560 x 2560 x 3 images) from all tissue samples
% pthCT (str): directory containing the corresponding CT images
% guass_sm (boolean): 1/0 . If 1, gaussian smoothing applied to the histology images
% foreground_mask (boolean): 1/0 . If 1, an additional folder is created as output with the foreground/background masks of the µCT images

if ~exist('stepSize','var');stepSize=512;end
if ~exist('gauss_sm','var');gauss_sm=0;end


%%%%%%%%%%%%%%%%%%%%%%%%% Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
thr=70; % <70% of the pixels in a patch should be within the inscribed circle of the original image
thr_reg=0.45; % the correlation coefficient between a histology and µCT image patch should be greater than this value 
if stepSize <= 256;PadAmount=50;else;PadAmount=100;end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Define outpth to save patches
nm_output_folder=['Patches_',num2str(stepSize),'/'];
outpthHE = [pthHE,nm_output_folder];if ~isfolder(outpthHE);mkdir(outpthHE);end
outpthCT = [pthCT,nm_output_folder];if ~isfolder(outpthCT);mkdir(outpthCT);end

% Load an image to set initialization parameters
imlist=dir([pthHE,'*.tif']);
imr=imread([pthHE,imlist(1).name]);
[rows,columns,~]=size(imr);
blockSizeR = stepSize; blockSizeC = stepSize;
 

% Calculate how many non-overlapping patches can be obtained per image
wholeBlockRows = floor(rows / stepSize);
wholeBlockCols = floor(columns / stepSize);
num_blocks = wholeBlockRows * wholeBlockCols;
fprintf("The number of %d x %d patches per image is: %d \n", stepSize,stepSize,num_blocks)

for kk=1:length(imlist)
    fprintf("Generating patches for image: %d / %d \n",kk,length(imlist))
    % Load histology
    histo = imread([pthHE,imlist(kk).name]);
    if gauss_sm;histo=imgaussfilt(histo,2);end
    % Load CT
    CT = imread([pthCT,imlist(kk).name]);
   
    % Define the ring mask (inscribed circle of the image: check Fig. 3.10 B Master Thesis)
    radius = floor(size(CT,1)/2)+1;
    [X, Y] = meshgrid(1:size(CT,1), 1:size(CT,2));
    distances = sqrt((X - (size(CT,1)/2 + 0.5)).^2 + (Y - (size(CT,2)/2 + 0.5)).^2);
    ringmask = distances <= radius;

    % Define the padded version of the images
    histop = padarray(histo,[PadAmount,PadAmount],255,'both');
    CTp = padarray(CT,[PadAmount,PadAmount],0,'both');
    
    % Define variable to save crop indices
    crop_ind = zeros(num_blocks,4);

    % Now scan through, getting each block and putting it as a slice of a 3D array.
    sliceNumber = 1;
    for row = 1 : stepSize : rows
      for col = 1 : stepSize : columns
        row1 = row;
        row2 = row1 + blockSizeR - 1;
        col1 = col;
        col2 = col1 + blockSizeC - 1;
        if col2 > columns;continue;end
        
        % Check if the image patch is contained within the inscribed circle:
        oneBlockRING = ringmask(row1:row2, col1:col2,:);
        perc=(sum(oneBlockRING(:))/(size(oneBlockRING,1)*size(oneBlockRING,2)))*100;
        if perc<thr;continue;end
        
        % Extract patch from histology (padded version to check registration)
        row1p=row1+PadAmount;row2p=row2+PadAmount;
        col1p=col1+PadAmount;col2p=col2+PadAmount;
        oneBlockHISTO = histop(row1p-PadAmount:row2p+PadAmount, col1p-PadAmount:col2p+PadAmount,:);
        
        % Extract patch CT image
        oneBlockCT = CTp(row1p-PadAmount:row2p+PadAmount, col1p-PadAmount:col2p+PadAmount,:);

        % Check the correlation between CT and H&E
        % I - Convert the H&E to image looking like CT
        HistoG = oneBlockHISTO;
        HistoG =rgb2gray(HistoG);HistoG = imcomplement(HistoG); HistoG = medfilt2(HistoG);
        %figure;
        %subplot(1,2,1);imshow(HistoG);
        %subplot(1,2,2);imshow(oneBlockCT)
        
        % Refine registration (local registration based on SURF)
        PadAmount = 25;
        oneBlockCTp = padarray(im2uint8(oneBlockCT),[PadAmount PadAmount],0,'both');
        HistoGp = padarray(HistoG,[PadAmount PadAmount],0,'both');
        oneBlockCTp = imhistmatch(oneBlockCTp,HistoGp);
        
        % Initial value of the correlation coefficient before refining registration
        RR0=corr2(HistoGp,oneBlockCTp);
        % try registration
        mvpR =registerImagesSURFlocal(HistoGp,oneBlockCTp);
        if mvpR.Succesful
            % Remove padding
            oneBlockCTnp=oneBlockCTp(PadAmount:end-PadAmount,PadAmount:end-PadAmount);
            mvpRI = mvpR.RegisteredImage(PadAmount:end-PadAmount,PadAmount:end-PadAmount);
            % Calculate correlation coefficient after registration refinement
            RR1=corr2(oneBlockCTnp,mvpRI);
            
            if RR1>RR0 && RR1>thr_reg % use tile as a training image 
                % Register original histology
                % pad histology
                a=oneBlockHISTO(:,:,1);am=mode(a(:));
                b=oneBlockHISTO(:,:,2);bm=mode(b(:));
                c=oneBlockHISTO(:,:,3);cm=mode(c(:));
                a = padarray(im2uint8(a),[PadAmount PadAmount],am,'both');
                b = padarray(im2uint8(b),[PadAmount PadAmount],bm,'both');
                c = padarray(im2uint8(c),[PadAmount PadAmount],cm,'both');
               
                % Registration
                tform=mvpR.Transformation;
                movingRefObj = imref2d(size(HistoGp));fixedRefObj = imref2d(size(HistoGp));
                
                ch1=imwarp(a, movingRefObj, tform, 'OutputView', fixedRefObj, 'SmoothEdges', true,'Fillvalues',am);
                ch2=imwarp(b, movingRefObj, tform, 'OutputView', fixedRefObj, 'SmoothEdges', true,'Fillvalues',bm); 
                ch3=imwarp(c, movingRefObj, tform, 'OutputView', fixedRefObj, 'SmoothEdges', true,'Fillvalues',cm); 
                oneBlockHISTO=cat(3,ch1,ch2,ch3);
    
                % remove padding for the histology
                oneBlockHISTO=oneBlockHISTO(PadAmount:end-PadAmount-1,PadAmount:end-PadAmount-1,:);
                

            end
            
        end
       crop_ind(sliceNumber,:) = [row1,row2,col1,col2];
       if ~exist('RR1','var');RR1=0;end
       RR = max(RR0,RR1);
       % ONLY SAVE PATCHES IF REGISTRATION IS GOOD ENOUGH
       if RR > thr_reg

           % Save histology and CT patches
           oneBlockHISTO=oneBlockHISTO(PadAmount:end-PadAmount-1,PadAmount:end-PadAmount-1,:);
           oneBlockCT=oneBlockCT(PadAmount:end-PadAmount-1,PadAmount:end-PadAmount-1);
           OutputDatafileHISTO = [outpthHE,imlist(kk).name(1:end-4),'_patch_',num2str(sliceNumber),'.tif'];
           imwrite(oneBlockHISTO,OutputDatafileHISTO);
           OutputDatafileCT = [outpthCT,imlist(kk).name(1:end-4),'_patch_',num2str(sliceNumber),'.tif'];
           imwrite(oneBlockCT,OutputDatafileCT);    
               
       end
       sliceNumber = sliceNumber + 1;
          
       
      end
    end
    
    datafile_ind = [outpthHE,imlist(kk).name(1:end-4),'crop_ind.mat'];
    save(datafile_ind,"crop_ind");
   
end

end

