% -------------------------------------------------------------------------
% Evaluate registration using annotated fiducial points
% -------------------------------------------------------------------------
% Cristina Almagro-Pérez, ETH Zürich, PSI, 19/05/2023
% -------------------------------------------------------------------------
clear;clc;close all;
% Add base folder to the current path
current_directory = pwd;
[parent_directory, ~, ~] = fileparts(current_directory);
path(path,[parent_directory,'/base/']);
warning('off');

pth=''; % Location with annotated fiducials
pthCT=[pth,'CT\'];pthHisto=[pth,'Histo\'];pthHistoR=[pth,'HistoRegistered\'];
pthHistoRE=[pth,'HistoRegisteredElastix_nocrop\'];
if 0
% Convert 'xml' files with fiducial points into MATLAB variables
read_xml_files(pthCT);read_xml_files(pthHisto);read_xml_files(pthHistoR);
end

if 1
elastix=1;
% --------------- Calculate TRE between CT and Histo ----------------------
pthCTM=[pthCT,'matfiles_manual\'];
matlist=dir([pthCTM,'*mat']);
distances=[];
for kk=1:length(matlist)
    
    % Load points CT
    pointsCT=load([pthCTM, matlist(kk).name]);
    pointsCT=pointsCT.manual_coordinates;
    
    % Load points (unregistered) Histo
    pointsHisto=load([pthHisto,'matfiles_manual\',matlist(kk).name]);
    pointsHisto=pointsHisto.manual_coordinates;
    
    % Calculate TRE
    dist=sqrt((pointsCT(:,1)-pointsHisto(:,1)).^2+(pointsCT(:,2)-pointsHisto(:,2)).^2); %pixels
    factor=1.63/1000; %1.63um/pixel (TRE in mm)
    dist=dist*factor; %mm
    distances=[distances;dist];
  
end
outpth=[pth,'TRE/'];if ~isfolder(outpth);mkdir(outpth);end
datafile=[outpth,'TRE_non_registered.mat'];
save(datafile,'distances');

% --------------- Calculate TRE between CT and Registered Histo -----------
pthCTM=[pthCT,'matfiles_manual\'];
matlist=dir([pthCTM,'*mat']);
distances=[];
for kk=1:length(matlist)
    
    % Load points CT
    pointsCT=load([pthCTM, matlist(kk).name]);
    pointsCT=pointsCT.manual_coordinates;
    
    % Load points (unregistered) Histo
    pointsHisto=load([pthHistoR,'matfiles_manual\',matlist(kk).name]);
    pointsHisto=pointsHisto.manual_coordinates;
    
    % Calculate TRE
    dist=sqrt((pointsCT(:,1)-pointsHisto(:,1)).^2+(pointsCT(:,2)-pointsHisto(:,2)).^2); %pixels
    factor=1.63/1000; %1.63um/pixel (TRE in mm)
    dist=dist*factor; %mm
    distances=[distances;dist];
  
end
outpth=[pth,'TRE/'];if ~isfolder(outpth);mkdir(outpth);end
datafile=[outpth,'TRE_registered.mat'];
save(datafile,'distances');
end
% --------- Calculate TRE between CT and Registered Histo (Elastix) -------
pthCTM=[pthCT,'matfiles_manual\'];
matlist=dir([pthCTM,'*mat']);
distances=[];
for kk=1:length(matlist)
    
    % Load points CT
    pointsCT=load([pthCTM, matlist(kk).name]);
    pointsCT=pointsCT.manual_coordinates;
    
    % Load points (unregistered) Histo
    pointsHisto=load([pthHistoRE,'matfiles_manual\',matlist(kk).name]);
    pointsHisto=pointsHisto.manual_coordinates;
    
    % Calculate TRE
    dist=sqrt((pointsCT(:,1)-pointsHisto(:,1)).^2+(pointsCT(:,2)-pointsHisto(:,2)).^2); %pixels
    factor=1.63/1000; %1.63um/pixel (TRE in mm)
    dist=dist*factor; %mm
    distances=[distances;dist];
  
end
outpth=[pth,'TRE/'];if ~isfolder(outpth);mkdir(outpth);end
datafile=[outpth,'TRE_registered_Elastix.mat'];
save(datafile,'distances');




% -------------------------- Graph TRE ------------------------------------
if 1
   pth0=''; % Location with TRE metrics
   nm={'HeartHE','LungEVG','LungHE'};
   NR=[]; %non-registered distances
   R=[];
   for kk=1:length(nm)
       pth=[pth0,nm{kk},'\TRE\'];
       % Load non registered distances
       load([pth,'TRE_non_registered.mat']);
       NR=[NR;distances]; clearvars distances
       % Load registered distances
       load([pth,'TRE_registered.mat']);
       R=[R;distances]; clearvars distances   
   end

% only my method
g = [NR,R];

figure;
boxplot(g,'Labels',{'Pre-registration','After registration',},'Whisker',1,'OutlierSize',6);%'LineWidth',1.5); %default value for OutlierSize is 6

title('Target registration error (TRE)')
ylabel('TRE [mm]','interpreter','Tex')
box on
set(gcf,'color','w');
set(gca,'FontSize', 15);
%Specify color of the box
h = findobj(gca,'Tag','Box');
for j=1:length(h)
    patch(get(h(j),'XData'),get(h(j),'YData'),[0 43 107]/255,'FaceAlpha',.5);
end

H=gca;
H.LineWidth=1.5; %change to the desired value 
h = findobj(gca,'tag','Median');
set(h,'LineWidth',1.5);
axis square


%% 
% only my method

datafile='C:\Users\crist\Desktop\Master_thesis\EvaluationRegistration\HeartHE\TRE\TRE_registered_Elastix.mat';
load(datafile);
distances=[distances;distances;distances];

g =[NR,distances,R];
figure;
boxplot(g,'Labels',{'Pre-registration','Elastix','Ours'},'Whisker',1,'OutlierSize',10);%'LineWidth',1.5); %default value for OutlierSize is 6

title('Target registration error (TRE)')
ylabel('TRE [mm]','interpreter','Tex')
box on
set(gcf,'color','w');
set(gca,'FontSize', 15);
%Specify color of the box
h = findobj(gca,'Tag','Box');
for j=1:length(h)
    patch(get(h(j),'XData'),get(h(j),'YData'),[0 43 107]/255,'FaceAlpha',.5);
end

H=gca;
H.LineWidth=1.5; %change to the desired value 
h = findobj(gca,'tag','Median');
set(h,'LineWidth',1.5);
axis square
    
    
    
end


