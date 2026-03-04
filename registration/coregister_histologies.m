function coregister_histologies(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Register histologies roughly to bring them to the same frame
% Rough Intensity-based rigid registration in downscaled images
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cristina Almagro Perez, 2023, PSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
% Please specify the following:
% pth_histo: directory containing the histologies to be co-registered. 
% -------------------------------------------------------------------------

p = struct( ...
        'pth_histo', '');

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

% Add base directory for dependencies
current_directory = pwd;
[parent_directory, ~, ~] = fileparts(current_directory);
path(path,[parent_directory,'/base/']);
warning('off');

% Define output directory to save co-registered histologies
outpth=[p.pth_histo,'Co-Registered/'];
if ~isfolder(outpth);mkdir(outpth);end

files=dir([p.pth_histo,'*.tif']);
files=natsortfiles(files);

% Registration will be calculated on images downsampled by 1/scale
scale=20; 
% Configuration
[optimizer,metric] = imregconfig('monomodal');

% Step 1 - Define the order of registration
ref=round(length(files)/2);
ind1=ref:-1:1; %first half of images
ind2=ref:1:length(files); %second half of images

% Step 2 - Find the largest image dimensions
MaxRow=0;
MaxCol=0;
for kk=1:length(files)
    im=imread([p.pth_histo,files(kk).name]);
    [Row,Col,~]=size(im);
    if Row>MaxRow;MaxRow=Row;end
    if Col>MaxCol;MaxCol=Col;end
end

% Step 3 - Pad reference image (if required) and save.
central=imread([p.pth_histo,files(ref).name]);
RowPad=MaxRow-size(central,1);ColPad=MaxCol-size(central,2);pr1=floor(RowPad/2);pr2=RowPad-pr1;pc1=floor(ColPad/2);pc2=ColPad-pc1;
centralp = padarray(im2uint8(central),[pr1 pc1],255,'pre');centralp=padarray(im2uint8(centralp),[pr2 pc2],255,'post');
imwrite(centralp,[outpth,files(ref).name]);

% Step 4 - Calculate the registration parameters in downscaled version
for i=1:2
if i==1;ind=ind1;elseif i==2;ind=ind2;end
for kk=1:length(ind)-1
    rf_ind=ind(kk);
    mv_ind=ind(kk+1);
    fprintf("############################################### \n")
    fprintf("Reference image: %s \n",files(rf_ind).name)
    fprintf("Moving image: %s \n",files(mv_ind).name)
    ref0=imread([outpth,files(rf_ind).name]);
    mv0=imread([p.pth_histo,files(mv_ind).name]);
    
    mv=im2gray(imresize(mv0,1/scale));
    rf=im2gray(imresize(ref0,1/scale));
    tform = imregtform(mv,rf,'rigid',optimizer,metric);
    reg = imregister(mv,rf,'rigid',optimizer,metric);
    figure;
    subplot(1,2,1);imshowpair(rf,mv);title('Before registration');
    subplot(1,2,2);imshowpair(rf,reg);title('After registration');

    tform.T(3,1:2)=tform.T(3,1:2)*scale;
    movingRefObj = imref2d(size(mv0));fixedRefObj = imref2d(size(ref0));
    mvR = imwarp(mv0, movingRefObj, tform, 'OutputView', fixedRefObj, 'SmoothEdges', true,'FillValues',255);
    imwrite(mvR,[outpth,files(mv_ind).name]);
 
end
end
end
