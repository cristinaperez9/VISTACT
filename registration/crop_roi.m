function crop_roi(varargin)

% =========================================================
% Crop ROI based on provided bounding box
% =========================================================

p = struct( ...
        'pth_histo_reg', '', ...
        'bb', [] ... 
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

% Get the directory of this script
thisFile  = mfilename('fullpath');
thisDir   = fileparts(thisFile);

% Build path to ../base relative to this script
baseDir   = fullfile(thisDir, '..', 'base');

% Add it to MATLAB path
addpath(baseDir);

outpth=[p.pth_histo_reg,'roi/'];
if ~isfolder(outpth);mkdir(outpth);end

imlist=dir([p.pth_histo_reg,'*.tif']);
imlist=natsortfiles(imlist);
for kk=1:length(imlist)
    
    % Load image 
    im1x=imread([p.pth_histo_reg,imlist(kk).name]);
    % Crop region
    bb = p.bb;
    tl = bb(1:2);   
    br = bb(3:4);   
    im1xn=im1x(tl(2):br(2),tl(1):br(1),:);
    % Save
    imwrite(im1xn,[outpth,imlist(kk).name]);

end
end