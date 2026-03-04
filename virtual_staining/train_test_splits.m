function train_test_splits(varargin)

% -------------------------------------------------------------------------
% Split image patches for training and evaluation.
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
        'pth_ct_patches', '', ...
        'pth_histo_patches', '',  ...
        'output_dir', ''  ...
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

 
    split_files(p.pth_ct_patches,p.pth_histo_patches,p.output_dir)

end


function split_files(pthCT_patch,pthHE_patch,output_dir,foreground_mask)
    
    % pthHE_patch: directory with the histology patches
    % pthCT_patch: directory with the corresponding CT patches
    % output_dir (str): Base output directory. 
    % foreground_mask (boolean): 1/0 . If 1, an additional folder is created as output with the foreground/background masks of the µCT images

    if ~exist('foreground_mask','var');foreground_mask=0;end
    % MicroCT     
    output_dir_A_train = fullfile(output_dir, 'A', 'train/');
    output_dir_A_test = fullfile(output_dir, 'A', 'test/');

    % Histology
    output_dir_B_train = fullfile(output_dir, 'B', 'train/');
    output_dir_B_test = fullfile(output_dir, 'B', 'test/');

    if ~isfolder(output_dir_A_train);mkdir(output_dir_A_train);end
    if ~isfolder(output_dir_A_test);mkdir(output_dir_A_test);end
    if ~isfolder(output_dir_B_train);mkdir(output_dir_B_train);end
    if ~isfolder(output_dir_B_test);mkdir(output_dir_B_test);end

    HElist=dir([pthHE_patch,'*.tif']);
    Arry=1:1:length(HElist);
    TrainInd = randsample(Arry, round(0.9*length(Arry))); 
    
    % Create training and validation set
    for kk=1:length(HElist)
        % Load histology image
        HE = imread([pthHE_patch,HElist(kk).name]);
        % Load CT image
        CT = imread([pthCT_patch,HElist(kk).name]);
       
        if any(TrainInd(:) == kk)
            outpth_CT=output_dir_A_train;
            outpth_EVG=output_dir_B_train;
        else
            outpth_CT=output_dir_A_test;
            outpth_EVG=output_dir_B_test;
        end
           
        % Save images
        imwrite(HE,[outpth_EVG,HElist(kk).name]);
        imwrite(CT,[outpth_CT,HElist(kk).name]);

         if foreground_mask
               % Calculate foreground/background mask using Otsu thresholding
               T=graythresh(CT);
               mask=imbinarize(CT,T);
               outpth_MASKFG = [outpth0,'MASFK/']; if ~isfolder(outpth_MASKFG);mkdir(outpth_MASKFG);end
               imwrite(uint8(mask),[outpth_MASKFG,HElist(kk).name])
         end

    end
    disp('Dataset created!')
end
