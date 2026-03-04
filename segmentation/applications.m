% -------------------------------------------------------------------------
% Applications of the 3D collagen segmentation masks obtained after uCT
% virtual staining:
% (1) Projections in the axial, sagittal and coronal plane to identify
%     vascular remodelled regions. Fig.18 A and Fig. 19
% (2) Caclulation of the thickness of the thickened (enlarged) vessels
%     identified with step (1). Fig.4.18 B
% -------------------------------------------------------------------------
% Cristina Almagro-Pérez, ETH Zürich, 2023
% -------------------------------------------------------------------------
clc;clear;close all;
% Please select the following:
application1=1;
application2=0;
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Application 1: projections of the collagen masks
% -------------------------------------------------------------------------
if application1

    fig_4_18A=1;
    fig_4_19A=1;
    fig_4_19B=0;
    fig_4_19C=0;
    model='cGAN'; % Either cGAN or FCN (only for fig_4_19A and fig_4_19B)

    if fig_4_18A
 
        % Load the volume
        pth=''; #DEFINE
        load([pth,'vol_pp.mat'],'vol');

        % Axial projection
        zp=sum(vol,3);
        zp=squeeze(zp);
        figure;imagesc(zp);colormap('jet');
        axis square
        set(gcf,'color','w');

        % Sagittal projection
        xp=sum(vol,2);
        xp=squeeze(xp);
        figure;imagesc(xp);colormap('jet');
        axis square
        set(gcf,'color','w');

        % Coronal projection
        yp=sum(vol,1);
        yp=squeeze(yp);
        figure;imagesc(yp);colormap('jet');
        axis square
        set(gcf,'color','w');
    end

    if fig_4_19B
       % Load images: 3NewSamples - Sample 2 - Volume 2
       if strcmp(model,'FCN')
        pth=''; #DEFINE
        load([pth,'vol_pp.mat'],'vol');
        zp=sum(vol,3);
       elseif strcmp(model,'cGAN')
        pth=''; #DEFINE
        load([pth,'vol_pp.mat'],'vol');
        vol=vol(1:1016,203:end,1:333);
        zp=sum(vol,3);zp=imrotate(zp,90);zp=flipud(zp);
       end
       figure;imagesc(zp);colormap(jet);
    end

    if fig_4_19C
       % 3NewSamples - Sample 1 - Volume 2
        pth=''; #DEFINE
        load([pth,'vol_pp.mat'],'vol');
        zp=sum(vol,3);zp=flipud(zp);zp=fliplr(zp);
        figure;imagesc(zp);colormap(jet);
    end

    if fig_4_19A
        % NewSample - Volume 1
        if strcmp(model,'FCN')
         pth=''; #DEFINE
         load([pth,'vol_pp.mat'],'vol');
         zp=sum(vol,3);zp=imrotate(zp,90);zp=flipud(zp);zp=imrotate(zp,90);
         figure;imagesc(zp);colormap('jet');
         
         pthEVG=''; #DEFINE
         pthCT=''; #DEFINE
         im_name='Human_IPAH_21459-27_33_EVG_190909_1.tif';
         EVG=imread([pthEVG,im_name]);EVG=imrotate(EVG,90);
         CT=imread([pthCT,im_name]);CT=imrotate(CT,90);
         CTc=imadjust(CT);
         figure;
         ax1=subplot(1,2,1);imshow(EVG);
         ax2=subplot(1,2,2);imshow(CTc);
         linkaxes([ax1,ax2]);
         xlim([740 1118]);
         ylim([876 1254]);
         elseif strcmp(model,'cGAN')  
         pth=''; # DEFINE
         load([pth,'vol_pp.mat'],'vol');
         zp=sum(vol,3);zp=imrotate(zp,90);
         figure;imagesc(zp);colormap('jet');
        end
     
    end

end
% -------------------------------------------------------------------------
% Application 2: thickness of thickened vessels
% -------------------------------------------------------------------------

if application2
    
    % Load volume (and process)
    pth='';
    load([pth,'vol_pp.mat'],'vol');
    zp=sum(vol,3);
    figure;imagesc(zp);colormap('jet');
    bv=single(vol(600:1100,1:260,:));
    % Distance transform in 3D 
    vol_dist=bwdist(imcomplement(bv));
    th3D=max(vol_dist(:));
    % 1.63 um/pixel, 2 because the volume is downsampled, 2 because the thickness is double the value obtained with bwdist
    factor=2*2*1.63;
    th3D=th3D*factor; 
    fprintf("The thickness of the blood vessel is %f \n", th3D);
   
    figure;
    a=bv(:,:,100);
    b=vol_dist(:,:,100);
    an=a(90:415,1:195);
    bn=b(90:415,1:195);
    subplot(1,2,1);imshow(an,[]);
    subplot(1,2,2);imagesc(bn);
end
