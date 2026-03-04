function coregister_pairs(varargin)

p = struct('pthCT', '', ...
        'pthHE', '', ...
        'outpth', '');

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

%--------------------------------------------------------------------------
% Global and local registration for pixel-wise correspondance between 
% histology and µCT
% -------------------------------------------------------------------------
% Cristina Almagro Perez, 2023, PSI
% -------------------------------------------------------------------------
% pthCT
% pthHE
% outpth



% Add base directory for dependencies
current_directory = pwd;
[parent_directory, ~, ~] = fileparts(current_directory);
path(path,[parent_directory,'/base/']);
warning('off');

scale=2.5; % Perform registration in 1/scale versions of the images
extra=700; 

% Default settings
p=1; %plot images
save_plot=1; % save overlayed images after registration
save_moving=1; % save registered image
local=0; %Perform patch-based registration

imlist=dir([p.pthHE,'*.tif']); 
imlist=natsortfiles(imlist);
if ~isfolder(p.outpth);mkdir(p.outpth);end
if ~isfolder([p.outpth,'QualitativeEvaluation/']);mkdir([p.outpth,'QualitativeEvaluation/']);end

for kk=1:length(imlist) 

nmHE=imlist(kk).name;nmCT=nmHE;
fprintf("Registering image %s \n ", nmHE)
% Load CT image
CT=imread([p.pthCT,nmCT]);CT0=CT;
CT=im2uint8(CT);CT=imresize(CT,1/scale); 
CT=imadjust(CT);

% Load histology
HE=imread([p.pthHE,nmHE]);HEHR0=HE;
% Transform histology to simulate microCT intensities and crop
HE=rgb2gray(HE);HE = imcomplement(HE); HE = medfilt2(HE);
HE0=HE;HE0=imresize(HE0,1/scale);

% Crop some of the extra pixels left for the cropped histology
HE=HE(extra:end-extra,extra:end-extra,:); HE=imresize(HE,1/scale);


%% Registration for cropped and non-cropped version and select the best
% Registration for cropped version
rf0=CT;mv1_0=HE;
[PadAmount1,tform1,D1,RR1,rf1,mv1,mvE1,szPad1]=register(mv1_0,rf0,p,local);

% Registration for non-cropped version
mv2_0=HE0;
[PadAmount2,tform2,D2,RR2,rf2,mv2,mvE2,szPad2]=register(mv2_0,rf0,p,local);

if RR1>RR2
    mv0=mv1_0;PadAmount=PadAmount1;tform=tform1;D=D1;RR=RR1;
    mv=mv1;rf=rf1;mvE=mvE1;szPad=szPad1;
else
    mv0=mv2_0;PadAmount=PadAmount2;tform=tform2;D=D2;RR=RR2;
    mv=mv2;rf=rf2;mvE=mvE2;szPad=szPad2;
end
%% Save visualization of registration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot 1
if save_moving
imwrite(mvE,[p.outpth,'QualitativeEvaluation/',nmHE(1:end-4),'_output.tif']);
end

% Plot 2 and 3
if save_plot
h=figure(111);title(nmHE);
subplot(2,2,1);imshow(rf); title('Fixed image: microCT');
subplot(2,2,2);imshow(mv);title('Moving image: H&E');
subplot(2,2,3);imshowpair(rf,mv);title('Overlay before registration');
subplot(2,2,4);imshowpair(rf,mvE);title('Overlay after registration');
set(gcf,'color','w');
print(h,[p.outpth,'QualitativeEvaluation/',nmHE(1:end-4)],'-djpeg');

%Save overlayed images after registration 
close all;
h=figure(112);
set(gcf,'color','w');
imshowpair(rf,mvE);
title(['RR: ',num2str(RR)]);
print(h,[p.outpth,'QualitativeEvaluation/',nmHE(1:end-4),'_registered'],'-djpeg');
end

%% Register and save RGB high resolution H&E %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if RR1>RR2 
    HEHR=HEHR0(extra:end-extra,extra:end-extra,:); 
end

HEHR=preprocessHEHR(HEHR,round(PadAmount*scale));
% REGISTER AFFINELY 
tform.T(3,1:2)=tform.T(3,1:2)*scale;
movingRefObj = imref2d(size(HEHR));fixedRefObj = imref2d(size(HEHR));
a=HEHR(:,:,1);am=mode(a(:));
b=HEHR(:,:,2);bm=mode(b(:));
c=HEHR(:,:,3);cm=mode(c(:));
ch1=imwarp(a, movingRefObj, tform, 'OutputView', fixedRefObj, 'SmoothEdges', true,'Fillvalues',am);
ch2=imwarp(b, movingRefObj, tform, 'OutputView', fixedRefObj, 'SmoothEdges', true,'Fillvalues',bm); 
ch3=imwarp(c, movingRefObj, tform, 'OutputView', fixedRefObj, 'SmoothEdges', true,'Fillvalues',cm); 
HEHRG=cat(3,ch1,ch2,ch3);
 
% CROP
HEHRGc=uint8(zeros(size(HEHRG)));HEHRGc(:,:,1)=HEHRGc(:,:,1)+am;HEHRGc(:,:,2)=HEHRGc(:,:,2)+bm;HEHRGc(:,:,3)=HEHRGc(:,:,3)+cm;
HEHRGc(round(szPad(1)*scale):end-round(szPad(2)*scale),round(szPad(1)*scale):end-round(szPad(2)*scale),:)=HEHRG(round(szPad(1)*scale):end-round(szPad(2)*scale),round(szPad(1)*scale):end-round(szPad(2)*scale),:);
% PATCH-BASED REGISTRATION FOR LOCAL REFINEMENT
if local
    sz=size(D);D=imresize(D,sz(1:2)*scale);D=scale.*D;
    HEHRE=imwarp(HEHRGc,D);
else
    HEHRE=HEHRGc;
end

% REMOVE PADDING AND SAVE IMAGE
sz=size(CT0);
half=round(sz(1)/2); % CT is square
ctr=round(size(HEHRE)/2);ctr=ctr(1);
imfHR=HEHRE(ctr-half:ctr+half,ctr-half:ctr+half,:);
imfHR=imresize(imfHR,sz);
imwrite(imfHR,[p.outpth,nmHE]);
h=figure(555);imshowpair(CT0,imfHR,"checkerboard");
print(h,[p.outpth,'QualitativeEvaluation/',nmHE(1:end-4),'_checkerboard'],'-dtiff');
% Save registration variables
save([p.outpth,nmHE(1:end-4),'.mat'],'tform','D','scale','szPad','RR1','RR2');

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Auxiliary function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [PadAmount,tform,D,RR,rf,mv,mvE,szPad]=register(mv,rf,p,local)
   
    %% Preprocessing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    PadAmount=50; 
    [rf,mv,szPadHisto,szPadCT]=preprocess(rf,mv,PadAmount);
    szPad=szPadCT;
    if p 
        figure(1);sgtitle('Before registration')
        subplot(1,2,1);imshow(rf); title('Fixed image: microCT')
        subplot(1,2,2);imshow(mv);title('Moving image: H&E')
        set(gcf,'color','w');
    end
    
    %% Global registration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Rough registration using SURF descriptors
    mvG0 =registerImagesSURF(mv,rf);
    if mvG0.Succesful
    tform1=mvG0.Transformation;
    mvG1=mvG0.RegisteredImage;
    RRt1=corr2(rf,mvG1);
    RRt2=0;
    else
        RRt1=0;
    
        % Apply histogram matching and check if registration improves
        mv=imhistmatch(mv,rf); 
        mvG0 =registerImagesSURF(mv,rf);
        if mvG0.Succesful
        tform2=mvG0.Transformation;
        mvG2=mvG0.RegisteredImage;
        RRt2=corr2(rf,mvG2);
        else
            RRt2=0;
        end
    end
    if RRt1>RRt2;tform=tform1;mvG=mvG1;else;tform=tform2;mvG=mvG2;end
    
    if p
    figure(2);
    subplot(1,2,1);imshowpair(rf,mv);title('Before rough registration')
    subplot(1,2,2);imshowpair(rf,mvG);title('After rough registration')
    set(gcf,'color','w');
    end

    %% Crop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    mvGc=uint8(zeros(size(rf)));
    mvGc(szPad(1):end-szPad(2),szPad(1):end-szPad(2))=mvG(szPad(1):end-szPad(2),szPad(1):end-szPad(2));
    
    if p
    figure(5);
    subplot(1,2,1);imshowpair(rf,mvG);title('Before cropping')
    subplot(1,2,2);imshowpair(rf,mvGc);title('After cropping')
    set(gcf,'color','w');
    end

    %% Patch-based registration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if local
    
    % Remove the padding to perform registration.
    rfNP=rf(szPad+1:end-szPad,szPad+1:end-szPad);
    mvNP=mvGc(szPad+1:end-szPad,szPad+1:end-szPad);
    a=rfNP>0;
    RR0=corr2(mvNP(a),rfNP(a));fprintf("RR before elastic registration: %f \n",RR0);
   
    PadAmountP = 100; % padding used in patch-based registration
    [mvE,D] =local_registration(mvNP,rfNP,PadAmountP);
    RR1=corr2(mvE(a),rfNP(a));fprintf("RR after elastic registration: %f \n",RR1);
    RR=RR1;
    

    if p
    figure(6);
    subplot(1,2,1);imshowpair(rf,mvGc);title('Before elastic registration')
    subplot(1,2,2);imshowpair(rf,mvE);title('After elastic registration')
    set(gcf,'color','w');
    end
    else
        mvE=mvGc;
        D='';
        RR=max(RRt1,RRt2); % global RR if local registration not performed
        
    end
    
end
end