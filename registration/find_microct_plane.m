function find_microct_plane(varargin)

p = struct('pthCT', '', ...
        'pthHE', '', ...
        'outpth', '',...
        'start_slice', '',...
        'finish_slice', '',...
        'res_microct', '');

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

% -------------------------------------------------------------------------
% Find the µCT plane corresponding to a histological patch
% Adaptation of "Histology to μCT Data Matching Using
% Landmarks and a Density Biased RANSAC" by Chicherova et al.

% Note for PSI users: it requires large memory (CPU). I run it in RA cluster, requesting 300G.
% -------------------------------------------------------------------------
% Cristina Almagro-Pérez, ETH Zürich, 2023
% -------------------------------------------------------------------------

% pthCT: directory containing the axial slices of the μCT volume at the original resolution
% pthHE: directory containing the histology patches at the resolution of the μCT (1.63 μm/pixel)
% outpth: output directory.
% start_slice: First axial slice that you expect the histology can correspond (e.g. first slice with tissue)
% finish_slice: Last axial slice that you expect the histology can correspond (e.g. last slice with tissue)

% -------------------------------------------------------------------------


% Set all to 1 to have directly as output the corresponding µCT plane
extract_features_volume=1;
extract_features_histology=1;
match_save_features=1;
plane_fitting=1;
save_plane_HR=1;

if p.res_microct < 4
    res_HE=4.016;  % Desired reduced resolution
else
    res_HE=p.res_microct;
end


if ~isfolder(p.outpth);mkdir(p.outpth);end
% -------------------------------------------------------------------------

% Add base directory for dependencies
current_directory = pwd;
[parent_directory, ~, ~] = fileparts(current_directory);
path(path,[parent_directory,'/base/']);
path(path,[parent_directory,'/base/SliVo/Feature_detection/']);
path(path,[parent_directory,'/base/SliVo/main/']);
path(path,[parent_directory,'/base/SliVo/MatlabFns/Robust/']);

warning('off');

output_f_hr = [p.pthCT,'CTvolHR.mat'];
if ~isfile(output_f_hr)
    fprintf("Saving μCT volume at high resolution");
    imlist=dir([p.pthCT,'*.tif']);
    imref=imread([p.pthCT,imlist(1).name]);
    sz=size(imref);
    CTvol=zeros(sz(1),sz(2),length(imlist));
    for kk=1:length(imlist)
        disp(kk)
        CTvol(:,:,kk)=imread([p.pthCT,imlist(kk).name]);
     end
    CTvol=uint16(CTvol);
    save([p.pthCT,'CTvolHR.mat'],'CTvol','-v7.3');
end

output_f_lr = [p.pthCT,'CTvol.mat'];
if ~isfile(output_f_lr)
    fprintf("Saving μCT volume at a reduced resolution");
    imlist=dir([p.pthCT,'*.tif']);
    imref=imread([p.pthCT,imlist(1).name]);
    imrefn=imresize(imref,p.res_microCT/res_HE);
    sz=size(imrefn);

    CTvol=zeros(sz(1),sz(2),length(imlist));
    for kk=1:length(imlist)
        disp(kk)
        im0=imread([p.pthCT,imlist(kk).name]);
        CTvol(:,:,kk)=imresize(im0,p.res_microCT/res_HE);
    end

    CTvol=uint16(CTvol);
    save([p.pthCT,'CTvol.mat'],'CTvol','-v7.3');
end


% -------------------------------------------------------------------------
%% 1) Extract features in the microCT volume at the reduced resolution
if extract_features_volume 
    fprintf("Extracting features of microCT volume \n");
    output_3Ddata=[p.outpth,'data/Features/3D_stack_vol/'];
    datafile_vol=[p.pthCT,'CTvol.mat'];
    if ~isfolder(output_3Ddata);mkdir(output_3Ddata);end
    load(datafile_vol);
    CTvol=CTvol(:,:,1:2:end); % The thickness of a histology image comprises 2 microCT slices
    % Preprocess microCT before extracting features
    CTvolp=uint8(zeros(size(CTvol))); 
    for kk=1:size(CTvol,3)
        CTslice=CTvol(:,:,kk);
        CTslice=(double(CTslice)-min(double(CTslice(:))))/(max(double(CTslice(:)))-min(double(CTslice(:))));      
        CTslice=uint8(CTslice*255);
        CTslice=imadjust(CTslice);
        CTvolp(:,:,kk)=CTslice;
    end
    fprintf("Volume processed \n")
    % Extract and save features
    for j=1:size(CTvolp,3)
        filename=sprintf('Feature_3Dslice%i.txt',j);
        output_file=[output_3Ddata filename];
        thresh=0.0002;feature_detector = 'SURF';
        save_keys(output_file,CTvolp(:,:,j),feature_detector,thresh);
        fprintf('Feaures for microCT slice %i computed\n',j);
    end
end

%% 2) Extract features in histology images
if extract_features_histology
    fprintf("Extracting features in histology patches \n")
    output_2Ddata=[p.outpth,'data/Features/2Dslices/'];
    if ~isfolder(output_2Ddata);mkdir(output_2Ddata);end
     
     
    imlist=dir([p.pthHE,'*tif']);
    for kk=1:length(imlist)
        im=imread([p.pthHE,imlist(kk).name]);
        % Convert histology from 1.63um/pixel to 4um/pixel
        im=imresize(im,p.res_microCT/res_HE);
        % Preprocess H&E
        img=rgb2gray(im);
        imgc_inv = imcomplement(img); 
        HE = medfilt2(imgc_inv);
        extra=round(size(HE,1)/4)/2;
        HE = HE(extra:end-extra,extra:end-extra);
        
        % Extract features for each slice and save
        filename=[imlist(kk).name(1:end-4), '.txt'];
        output_file=[output_2Ddata filename];
        thresh=0.0002;
        feature_detector = 'SURF';
        save_keys(output_file,HE,feature_detector,thresh);
        fprintf('Feaures for histology patch %i\n',kk);
    end
end
%% 3) Match descriptor vectors
if match_save_features
    % Define directories where SURF descriptors are saved
    pthHEf=[p.outpth,'data/Features/2Dslices/'];
    pthCTf=[p.outpth,'data/Features/3D_stack_vol/'];
    outpth_match=[p.outpth,'Matches/'];
    if ~isfolder(outpth_match);mkdir(outpth_match);end

    txtlist=dir([pthHEf,'*.txt']);
    txtlist=natsortfiles(txtlist);
    % Employ parallel pooling
    num_workers=8;
    parpool(num_workers,'IdleTimeout',Inf);


    imlistCT=dir([pthCTf,'*.txt']);
    fprintf("The 3D volume has %d sections \n",length(imlistCT));

    disp(pthCTf)
    parfor kk=1:length(txtlist)
        % Match the features
        fprintf('Matching features for slice %s \n', txtlist(kk).name(1:end-4))
        [des2D, locs2D]=feature_load([pthHEf txtlist(kk).name], 'SURF');
        % Count how many sections are in the 3D volume
        
        
        FeatureCoordinates_3D=cell(1,length(imlistCT));

        for j=1:length(imlistCT)
            filename_3Dslice=sprintf('Feature_3Dslice%i.txt',j);
            [des3D,locs3D]=feature_load([pthCTf filename_3Dslice],'SURF');
            [number,coor2Dslice,coor3D]= match_features(des2D,locs2D,des3D,locs3D); 
            FeatureCoordinates_3D{j}=coor3D(:,1:2);
        end

    parsave_1variable([outpth_match txtlist(kk).name(1:end-4),'.mat'], FeatureCoordinates_3D);

    end

end
    
%% 4) Find the corresponding microCT plane using RANSAC plane fitting
% Plane at low resolution (4um/pixel)
if plane_fitting
    fprintf("RANSAC plane fitting \n");
    datafile_vol=[p.pthCT,'CTvol.mat'];
    pth_matchings=[p.outpth,'Matches/'];
    outpth_low=[p.outpth,'/data/FoundPlane/low_resolution/'];
    if ~isfolder(outpth_low);mkdir(outpth_low);end
   
    load(datafile_vol,'CTvol');CTvol=CTvol(:,:,1:2:end);
    [X_size,Y_size,Z_size] = size(CTvol);
    match_list = dir([pth_matchings,'*.mat']);
    match_list=natsortfiles(match_list);
    
    % Employ parallel pooling
    num_workers=8;
    parpool(num_workers,'IdleTimeout',Inf);
    
    start_slice=round(p.start_slice/2);
    finish_slice=round(p.finish_slice/2);

    % Parameters
    myoptions.number=0;
    myoptions.angle=pi/8;
    myoptions.size=[X_size, Y_size];
    myoptions.lower_limit=start_slice;myoptions.upper_limit=finish_slice;
    myoptions.filter_radius_ratio=2.8;

    parfor kk=1:length(match_list)
   
    % load coordinates
    datafile_coords=[pth_matchings,match_list(kk).name];
    fprintf("Saving microCT plane for %s \n",match_list(kk).name);
    FeatureCoordinates_3D=load(datafile_coords);FeatureCoordinates_3D=FeatureCoordinates_3D.FeatureCoordinates_3D;
    fprintf("Start slice: %d, Finish slice: %d \n",start_slice,finish_slice)

    [B,~]=matching_plane(FeatureCoordinates_3D, myoptions);
    fprintf("matching plane done \n")
    datafile_vec=[outpth_low,'Normal_vec_toPlane_',match_list(kk).name];
    %save(datafile_vec,'B','P','-mat')
    parsave_Bvariable(datafile_vec,B);
    

    % show cut image
    [x_mesh, y_mesh]=meshgrid(1:X_size,1:Y_size);
    Z=-(y_mesh.*B(1) + x_mesh.*B(2) + B(4))/B(3);

    Slice_ransac = interp3(single(CTvol),x_mesh,y_mesh,Z); %cut a slice from 3D volume
    datafile_image = [outpth_low,'FoundMatch_in_3D_',match_list(kk).name(1:end-4),'.tif'];
    % Normalize and save image - convert to uint16
    a=(double(Slice_ransac)-min(double(Slice_ransac(:))))/(max(double(Slice_ransac(:)))-min(double(Slice_ransac(:))));
    Slice_ransac=uint8(a*255);
    imwrite(Slice_ransac, datafile_image,'Compression','None')


    end

end

if save_plane_HR
    fprintf("Saving µCT plane at high resolution \n");
    outpth_high=[p.outpth,'/data/FoundPlane/high_resolution/'];
    if ~isfolder(outpth_high);mkdir(outpth_high);end
    PthLow=[p.outpth,'/data/FoundPlane/low_resolution/'];
    % Load microCT volume at high resolution
    DatafileVol=[pthCT,'CTvolHR.mat'];load(DatafileVol);
    fprintf("Volume loaded \n");

    % Resize volume
    scale=res_HE/p.res_microCT;
    numZslices=size(CTvol,3);
    numZslices=round(numZslices/2);
    X_size_lr=round(size(CTvol,1)/scale);Y_size_lr=X_size_lr;
    scalez=numZslices/X_size_lr;
    
    CTvol=imresize3(CTvol,[size(CTvol,1),size(CTvol,2),scalez*size(CTvol,1)]);
    %disp("Volume dimensions:");disp(size(CTvol));
    
    % Loop through H&E patches
    imlist=dir([p.pthHE,'*.tif']);
    imlist=natsortfiles(imlist);
    
for kk=1:length(imlist)
    fprintf("Analyzing image %s \n",imlist(kk).name)
    % Load B
    DatafileParam=[PthLow,'Normal_vec_toPlane_',imlist(kk).name(1:end-4),'.mat'];
    load(DatafileParam);
    % Transform B
    X_size=1040;Y_size=1040;[x_mesh, y_mesh]=meshgrid(1:X_size,1:Y_size);
    Z=-(y_mesh.*B(1) + x_mesh.*B(2) + B(4))/B(3);
    z0=Z(round(X_size/2),round(Y_size/2));z0=z0*scale;
    ctr=round(size(CTvol,1)/2);
    Dn=-B(1)*ctr-B(2)*ctr-B(3)*z0;
    myBB=[B(1),B(2),B(3),Dn];
    myBB = myBB/norm(myBB);
    
    X_size=size(CTvol,1);Y_size=size(CTvol,2);[x_mesh, y_mesh]=meshgrid(1:X_size,1:Y_size);
    Z=-(y_mesh.*myBB(1) + x_mesh.*myBB(2) + myBB(4))/myBB(3);
    Slice_ransac = interp3(single(CTvol),x_mesh,y_mesh,Z);
    
    a=(double(Slice_ransac)-min(double(Slice_ransac(:))))/(max(double(Slice_ransac(:)))-min(double(Slice_ransac(:))));
    HR=uint16(a*65535);
    % Save results
    save([outpth_high,imlist(kk).name(1:end-4),'_.mat'],'HR');
    imwrite(HR,[outpth_high,imlist(kk).name]);

end
end

end


% -------------------------------------------------------------------------
% Auxiliary functions
% -------------------------------------------------------------------------
function parsave_1variable(fname,FeatureCoordinates_3D)
  save(fname, 'FeatureCoordinates_3D')
end

function parsave_Bvariable(fname, B)
  save(fname, 'B')
end