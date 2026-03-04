% -------------------------------------------------------------------------
% Colour deconvolution function developed by F. Piccinini and G. Landini.
% The link to the repository is:
% https://github.com/landinig/IJ-Colour_Deconvolution2/tree/main
% -------------------------------------------------------------------------

function [ImgR_back, ImgG_back, ImgB_back, Dye01_transmittance, Dye02_transmittance, Dye03_transmittance, LUTdye01, LUTdye02, LUTdye03, Q3x3Mat] = Colour_Deconvolution2(ImgR, ImgG, ImgB, StainingVectorID, DyeToBeRemovedID, doIcross)
% AUTHORS:      Filippo Piccinini (Email: filippo.piccinini85@gmail.com)
%               Gabriel Landini (Email: g.landini@bham.ac.uk)
%
% DATE:         July 15, 2020
%
% NAME:         Colour_Deconvolution2 (version 1.0)
%
% DESCRIPTION:  This function implements the ImageJ plugin named Colour
%               Deconvolution 2. Please, see the additional references [1]
%               and [2] for additional details.
%
%
% PARAMETERS:
%
% 	ImgR        Red channel (double precision, with values between 0 and
%               255) of the RGB image to be analysed.
%
%   ImgG        Green channel (double precision, with values between 0 and
%               255) of the RGB image to be analysed.
%
%   ImgB        Blue channel (double precision, with values between 0 and
%               255) of the RGB image to be analysed.
%
%   StainingVectorID    ID represents the staining vector to be used 
%               to deconvolve the input RGB image to be analysed.
%               Currently, these are the options available:
%               1  = "H&E"
%               2  = "H&E 2"
%               3  = "H DAB"
%               4  = "H&E DAB"
%               5  = "NBT/BCIP Red Counterstain II"
%               6  = "H DAB NewFuchsin"
%               7  = "H HRP-Green NewFuchsin"
%               8  = "Feulgen LightGreen"
%               9  = "Giemsa"
%               10 = "FastRed FastBlue DAB"
%               11 = "Methyl Green DAB"
%               12 = "H AEC"
%               13 = "Azan-Mallory"
%               14 = "Masson Trichrome"
%               15 = "Alcian Blue & H"
%               16 = "H PAS"
%               17 = "Brilliant_Blue"
%               18 = "AstraBlue Fuchsin"
%               19 = "RGB"
%               20 = "CMY"
%               3x3 matrix = When the StainingVectorID is a 3by3 matrix, 
%                            the single values are considered as the 
%                            vector coefficients for the dyes, in the form
%                            of:
%                                 SM = StainingVectorID;
%                                 MODx = [SM(1,1), SM(1,2), SM(1,3)];
%                                 MODy = [SM(2,1), SM(2,2), SM(2,3)];
%                                 MODz = [SM(3,1), SM(3,2), SM(3,3)];
%                            That is:
%                                 SM = [MODx(1), MODx(2), MODx(3); ...
%                                       MODy(1), MODy(2), MODy(3); ...
%                                       MODz(1), MODz(2), MODz(3)];
%                            For instance, for the "H&E DAB"
%                            (StainingVectorID = 11) the coefficients
%                            are as:
%                                 StainingVectorID=[0.650,0.072,0.268; ...
%                                                   0.704,0.990,0.570; ...
%                                                   0.286,0.105,0.776];
%                            You can also use the ImageJ plugin to
%                            extract values from ROI manually defined.
%                            Note that in ImageJ the coefficients are
%                            named:
%                                 MODx = [R1, R2, R3];
%                                 MODy = [G1, G2, G3];
%                                 MODz = [B1, B2, B3];
%                            and are shown in the Log window when 
%                            checking the dialog option "Show matrices".
%
%
%   DyeToBeRemovedID    ID represents the dye to be removed
%               during the deconvolution step. The output is the RGB
%               image used as input without the contribution of
%               the dye indicated by ChannelToBeRemovedID.
%               Currently, these are the options available:
%               0  = no dyes are removed!
%               1  = the 1st dye of the StainingVector is removed.
%               2  = the 2nd dye of the StainingVector is removed.
%               3  = the 3rd dye of the StainingVector is removed.
%
%   doIcross    This is the parameter called in the ImageJ Colour
%               Deconvolution 2 plugin witht he name of "Crossed product
%               for Colour 3". If it is 1 it computes the cross-product for
%               Colour 3, otherwise computes the Ruifrok's method.
%
% OUTPUT:
%
% 	ImgR_back   Red channel (double precision, with values between 0 and
%               255) of the RGB image generated after removing the
%               contribution of the dye defined by ChannelToBeRemovedID.
%
%   ImgG_back   Green channel (double precision, with values between 0 and
%               255) of the RGB image generated after removing the
%               contribution of the dye defined by ChannelToBeRemovedID.
%
%   ImgB_back   Blue channel (double precision, with values between 0 and
%               255) of the RGB image generated after removing the
%               contribution of the dye defined by ChannelToBeRemovedID.
%
%   Dye01_tran  Mono-channel image (double precision, with values between
%               0 and 255) representing the transmittance of the 1st dye
%               of the StainingVector used to deconvolve the input RGB
%               image. Note: this corresponds to the "-Colour_1"image
%               obtained in ImageJ in greyscale.
%
%   Dye02_tran  Mono-channel image (double precision, with values between
%               0 and 255) representing the transmittance of the 2nd dye
%               of the StainingVector used to deconvolve the input RGB
%               image. Note: this corresponds to the "-Colour_2"image
%               obtained in ImageJ in greyscale.
%
%   Dye03_tran  Mono-channel image (double precision, with values between
%               0 and 255) representing the transmittance of the 3rd dye
%               of the StainingVector used to deconvolve the input RGB
%               image. Note: this corresponds to the "-Colour_3"image
%               obtained in ImageJ in greyscale.
%
%   LUTdye01    Look-Up-Table (double precision, with values between 0
%               and 255) identified by the StainingVectorID to be applyed
%               to the transmittance channel computed for the 1st
%               dye to obtain a colour representation. Note: the
%               colours of the generated image correspond to those in
%               -Colour_1 image typically generated with the ImageJ Colour
%               Deconvolution plugin.
%
%   LUTdye02    Look-Up-Table (double precision, with values between 0
%               and 255) identified by the StainingVectorID to be applyed
%               to the transmittance channel computed for the 2nd
%               dye to obtain a colour representation. Note: the
%               colours of the generated image correspond to those in
%               -Colour_2 image typically generated with the ImageJ Colour
%               Deconvolution plugin.
%
%   LUTdye03    Look-Up-Table (double precision, with values between 0
%               and 255) identified by the StainingVectorID to be applyed
%               to the transmittance channel computed for the 3rd
%               dye to obtain a colour representation. Note: the
%               colours of the generated image correspond to those in
%               -Colour_3 image typically generated with the ImageJ Colour
%               Deconvolution plugin.
%
%   Q3x3Mat     3x3 matrix used to calculate the deconvolution step to 
%               obtain the corresponding transmittance values for
%               [Stain01, Stain02, Stain03].
%
%
% EXAMPLE OF CALL:
%
%   [ImgR_back, ImgG_back, ImgB_back Dye01_transmittance, Dye02_transmittance, Dye03_transmittance, LUTdye01, LUTdye02, LUTdye03, Q3x3Mat] = Colour_Deconvolution2(ImgR, ImgG, ImgB, StainingVectorID, DyeToBeRemovedID);
%
%
% ADDITIONAL REFERENCES:
%
%   [1] Ruifrok, A. C., & Johnston, D. A. (2001). Quantification of histochemical staining by colour deconvolution. Analytical and quantitative cytology and histology, 23(4), 291-299.
%
%   [2] https://blog.bham.ac.uk/intellimic/g-landini-software/colour-deconvolution-2/

% Copyright (C) 2020 Filippo Piccinini and Gabriel Landini
% All rights reserved.
% This program is free software; you can redistribute it and/or modify it 
% under the terms of the GNU General Public License version 3 (or higher) 
% as published by the Free Software Foundation. This program is 
% distributed WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
% General Public License for more details.



%% INTERNAL PARAMETERS:
format long
[rowR, colR, nchR]  = size(ImgR);
Dye01_transmittance = zeros(rowR, colR);
Dye02_transmittance = zeros(rowR, colR);
Dye03_transmittance = zeros(rowR, colR);
%Dye01_LUT           = double(zeros(rowR, colR, 3));
%Dye02_LUT           = double(zeros(rowR, colR, 3));
%Dye03_LUT           = double(zeros(rowR, colR, 3));
ImgR_back           = zeros(rowR, colR);
ImgG_back           = zeros(rowR, colR);
ImgB_back          	= zeros(rowR, colR);
Const1ForNoLog0     = 0;
Const2ForNoLog0     = 0;


%% COEFFICIENTS CONNECTED TO THE StainingVectorID:
[SMrow, SMcol, SMnch]  = size(StainingVectorID);
if (SMrow==3 && SMcol==3 && SMnch==1)
    SM = StainingVectorID;
    StainingVectorID = 21;
elseif (SMrow==1 && SMcol==1 && SMnch==1)
    if (StainingVectorID<1 || StainingVectorID>21)
        error('ERROR: StainingVectorID is not correctly defined!');
    end
end
        
if StainingVectorID==1
    % "H&E"
    MODx = [0.644211, 0.092789, 0];
    MODy = [0.716556, 0.954111, 0];
    MODz = [0.266844, 0.283111, 0];
elseif StainingVectorID==2
    % "H&E 2"
    MODx = [0.49015734, 0.04615336, 0];
    MODy = [0.76897085, 0.8420684, 0];
    MODz = [0.41040173, 0.5373925, 0];
elseif StainingVectorID==3
    % "H DAB"
    MODx = [0.650, 0.268, 0];
    MODy = [0.704, 0.570, 0];
    MODz = [0.286, 0.776, 0];
elseif StainingVectorID==4
    % "H&E DAB"
    MODx = [0.650, 0.072, 0.268];
    MODy = [0.704, 0.990, 0.570];
    MODz = [0.286, 0.105, 0.776];
elseif StainingVectorID==5
    % "NBT/BCIP Red Counterstain II"
    MODx = [0.62302786, 0.073615186, 0.7369498];
    MODy = [0.697869, 0.79345673, 0.0010];
    MODz = [0.3532918, 0.6041582, 0.6759475];
elseif StainingVectorID==6
    % "H DAB NewFuchsin"
    MODx = [0.5625407925, 0.26503363, 0.0777851125];
    MODy = [0.70450559, 0.68898016, 0.804293475];
    MODz = [0.4308375625, 0.674584, 0.5886050475];
elseif StainingVectorID==7
    % "H HRP-Green NewFuchsin"
    MODx = [0.8098939567, 0.0777851125, 0.0];
    MODy = [0.4488181033, 0.804293475, 0.0];
    MODz = [0.3714423567, 0.5886050475, 0.0];
elseif StainingVectorID==8
    % "Feulgen LightGreen"
    MODx = [0.46420921, 0.94705542, 0.0];
    MODy = [0.83008335, 0.25373821, 0.0];
    MODz = [0.30827187, 0.19650764, 0.0];
elseif StainingVectorID==9
    % "Giemsa"
    MODx = [0.834750233, 0.092789, 0.0];
    MODy = [0.513556283, 0.954111, 0.0];
    MODz = [0.196330403, 0.283111, 0.0];
elseif StainingVectorID==10
    % "FastRed FastBlue DAB"
    MODx = [0.21393921, 0.74890292, 0.268];
    MODy = [0.85112669, 0.60624161, 0.570];
    MODz = [0.47794022, 0.26731082, 0.776];
elseif StainingVectorID==11
    % "Methyl Green DAB"
    MODx = [0.98003, 0.268, 0.0];
    MODy = [0.144316, 0.570, 0.0];
    MODz = [0.133146, 0.776, 0.0];
elseif StainingVectorID==12
    % "H AEC"
    MODx = [0.650, 0.2743, 0.0];
    MODy = [0.704, 0.6796, 0.0];
    MODz = [0.286, 0.6803, 0.0];
elseif StainingVectorID==13
    % "Azan-Mallory"
    MODx = [0.853033, 0.09289875, 0.10732849];
    MODy = [0.508733, 0.8662008, 0.36765403];
    MODz = [0.112656, 0.49098468, 0.9237484];
elseif StainingVectorID==14
    % "Masson Trichrome"
    MODx = [0.7995107, 0.09997159, 0.0];
    MODy = [0.5913521, 0.73738605, 0.0];
    MODz = [0.10528667, 0.6680326, 0.0];
elseif StainingVectorID==15
    % "Alcian blue & H"
    MODx = [0.874622, 0.552556, 0.0];
    MODy = [0.457711, 0.7544, 0.0];
    MODz = [0.158256, 0.353744, 0.0];
elseif StainingVectorID==16
    % "H PAS"
    MODx = [0.644211, 0.175411, 0.0];
    MODy = [0.716556, 0.972178, 0.0];
    MODz = [0.266844, 0.154589, 0.0];
elseif StainingVectorID==17
    % "Brilliant_Blue"
    MODx = [0.31465548, 0.383573, 0.7433543];
    MODy = [0.6602395, 0.5271141, 0.51731443];
    MODz = [0.68196464, 0.7583024, 0.4240403];
elseif StainingVectorID==18
    % "AstraBlue Fuchsin"
    MODx = [0.92045766, 0.13336428, 0.0];
    MODy = [0.35425216, 0.8301452, 0.0];
    MODz = [0.16511545, 0.5413621, 0.0];
elseif StainingVectorID==19
    % "RGB"
    %MODx = [0.0, 1.0, 1.0];
    %MODy = [1.0, 0.0, 1.0];
    %MODz = [1.0, 1.0, 0.0];
    MODx = [0.001, 1.0, 1.0];
    MODy = [1.0, 0.001, 1.0];
    MODz = [1.0, 1.0, 0.001];
elseif StainingVectorID==20
    % "CMY"
    MODx = [1.0, 0.0, 0.0];
    MODy = [0.0, 1.0, 0.0];
    MODz = [0.0, 0.0, 1.0];
elseif StainingVectorID==21
    % "User values"
    MODx = [SM(1,1), SM(1,2), SM(1,3)];
    MODy = [SM(2,1), SM(2,2), SM(2,3)];
    MODz = [SM(3,1), SM(3,2), SM(3,3)];
end


%% COEFFICIENTS NORMALIZATION:

% Column-vector normalization to have 1 as final length of the columns in the 3D space.
len  = [0, 0, 0];
cosx = [0, 0, 0];
cosy = [0, 0, 0];
cosz = [0, 0, 0];
for i = 1:3
    len(i) = sqrt(MODx(i)*MODx(i) + MODy(i)*MODy(i) + MODz(i)*MODz(i)); % Normalization to have the lenght of the column equal to 1.
    if (len(i) ~= 0)
        cosx(i) = MODx(i)/len(i);
        cosy(i) = MODy(i)/len(i);
        cosz(i) = MODz(i)/len(i);
    end
end

% translation matrix
if (cosx(2)==0.0)
    if (cosy(2)==0.0)
        if (cosz(2)==0.0)
            %2nd colour is unspecified
            cosx(2)=cosz(1);
            cosy(2)=cosx(1);
            cosz(2)=cosy(1);
        end
    end
end

if cosx(3)==0.0
    if cosy(3)==0.0
        if cosz(3)==0.0
            %3rd colour is unspecified
            if doIcross==1
                cosx(3) = cosy(1) * cosz(2) - cosz(1) * cosy(2);
                cosy(3) = cosz(1) * cosx(2) - cosx(1) * cosz(2);
                cosz(3) = cosx(1) * cosy(2) - cosy(1) * cosx(2);
            else
                if ((cosx(1)*cosx(1) + cosx(2)*cosx(2))> 1)
                    %Colour_3 has a negative R component
                    cosx(3)=0.0;
                else
                    cosx(3)=sqrt(1.0-(cosx(1)*cosx(1))-(cosx(2)*cosx(2)));
                end

                if ((cosy(1)*cosy(1) + cosy(2)*cosy(2))> 1)
                    %Colour_3 has a negative G component
                    cosy(3)=0.0;
                else
                    cosy(3)=sqrt(1.0-(cosy(1)*cosy(1))-(cosy(2)*cosy(2)));
                end

                if ((cosz(1)*cosz(1) + cosz(2)*cosz(2))> 1)
                    %Colour_3 has a negative B component
                    cosz(3)=0.0;
                else 
                    cosz(3)=sqrt(1.0-(cosz(1)*cosz(1))-(cosz(2)*cosz(2)));
                end
            end
        end
    end
end

leng = sqrt(cosx(3)*cosx(3) + cosy(3)*cosy(3) + cosz(3)*cosz(3));
if (leng ~= 0 && leng ~= 1)
    cosx(3)= cosx(3)/leng;
    cosy(3)= cosy(3)/leng;
    cosz(3)= cosz(3)/leng;
end

COS3x3Mat = [cosx(1) cosy(1) cosz(1); ...
             cosx(2) cosy(2) cosz(2); ...
             cosx(3) cosy(3) cosz(3)];


%% MATRIX Q USED FOR THE COLOUR DECONVOLUTION:

% Check the determinant to understand if the matrix is invertible
if det(COS3x3Mat)>=-0.001 && det(COS3x3Mat)<=0.001
    % Check column 1
    if (COS3x3Mat(1,1)+COS3x3Mat(2,1)+COS3x3Mat(3,1)==0)
        cosx(1) = 0.001;
        cosx(2) = 0.001;
        cosx(3) = 0.001;
    end
    % Check column 2
    if (COS3x3Mat(1,2)+COS3x3Mat(2,2)+COS3x3Mat(3,2)==0)
        cosy(1) = 0.001;
        cosy(2) = 0.001;
        cosy(3) = 0.001;
    end
    % Check column 3
    if (COS3x3Mat(1,3)+COS3x3Mat(2,3)+COS3x3Mat(3,3)==0)
        cosz(1) = 0.001;
        cosz(2) = 0.001;
        cosz(3) = 0.001;
    end
    % Check row 1
    if (COS3x3Mat(1,1)+COS3x3Mat(1,2)+COS3x3Mat(1,3)==0)
        cosx(1) = 0.001;
        cosy(1) = 0.001;
        cosz(1) = 0.001;
    end
    % Check row 2
    if (COS3x3Mat(2,1)+COS3x3Mat(2,2)+COS3x3Mat(2,3)==0)
        cosx(2) = 0.001;
        cosy(2) = 0.001;
        cosz(2) = 0.001;
    end
    % Check row 3
    if (COS3x3Mat(3,1)+COS3x3Mat(3,2)+COS3x3Mat(3,3)==0)
        cosx(3) = 0.001;
        cosy(3) = 0.001;
        cosz(3) = 0.001;
    end
    % Check diagonal 1
    if (COS3x3Mat(1,1)+COS3x3Mat(2,2)+COS3x3Mat(3,3)==0)
        cosx(1) = 0.001;
        cosy(2) = 0.001;
        cosz(3) = 0.001;
    end
    % Check diagonal 2
    if (COS3x3Mat(1,3)+COS3x3Mat(2,2)+COS3x3Mat(3,1)==0)
        cosz(1) = 0.001;
        cosy(2) = 0.001;
        cosx(3) = 0.001;
    end
    
    COS3x3Mat = [cosx(1) cosy(1) cosz(1); ...
                 cosx(2) cosy(2) cosz(2); ...
                 cosx(3) cosy(3) cosz(3)];
    
    if det(COS3x3Mat)>=-0.001 && det(COS3x3Mat)<=0.001
        for k = 1:3
            if (cosx(k)==0); cosx(k)=0.001; end
            if (cosy(k)==0); cosy(k)=0.001; end
            if (cosz(k)==0); cosy(k)=0.001; end
        end
        
        COS3x3Mat = [cosx(1) cosy(1) cosz(1); ...
                     cosx(2) cosy(2) cosz(2); ...
                     cosx(3) cosy(3) cosz(3)];
                 
        if det(COS3x3Mat)>=-0.001 && det(COS3x3Mat)<=0.001         
            disp('WARNING: the vector matrix is non invertible! So, the images of the stainings (e.r. images with names: Stain0#_transmittance, and Stain0#_LUT) are OK, but the images with name "Img#_back" are unreliable!');
        end
    end
end

% Matrix inversion (I double check: it works!)
% NOTE: this is the code to mathematically invert a 3x3 matrix without
% calling the Matlab function "M3x3inv = inv(M3x3)".
% NOTE: Q3x3Mat = inv(COS3x3Mat);
% NOTE: COS3x3Mat = inv(Q3x3Mat);
A = cosy(2) - cosx(2) * cosy(1) / cosx(1);
V = cosz(2) - cosx(2) * cosz(1) / cosx(1);
C = cosz(3) - cosy(3) * V/A + cosx(3) * (V/A * cosy(1) / cosx(1) - cosz(1) / cosx(1));
q2 = (-cosx(3) / cosx(1) - cosx(3) / A * cosx(2) / cosx(1) * cosy(1) / cosx(1) + cosy(3) / A * cosx(2) / cosx(1)) / C;
q1 = -q2 * V / A - cosx(2) / (cosx(1) * A);
q0 = 1.0 / cosx(1) - q1 * cosy(1) / cosx(1) - q2 * cosz(1) / cosx(1);
q5 = (-cosy(3) / A + cosx(3) / A * cosy(1) / cosx(1)) / C;
q4 = -q5 * V / A + 1.0 / A;
q3 = -q4 * cosy(1) / cosx(1) - q5 * cosz(1) / cosx(1);
q8 = 1.0 / C;
q7 = -q8 * V / A;
q6 = -q7 * cosy(1) / cosx(1) - q8 * cosz(1) / cosx(1);
Q3x3Mat = [q0, q3, q6; q1, q4, q7; q2, q5, q8]; % THIS SHOULD BE THE ONE IN THE JAVA CODE
Q3x3MatInverted = COS3x3Mat; % NOTE: "Q3x3MatInverted = inv(Q3x3Mat)"


%% TRANSMITTANCE COMPUTATION:

for r = 1:rowR
    for c = 1:colR
        RGB1 = [ImgR(r,c), ImgG(r,c), ImgB(r,c)];
        if Const1ForNoLog0==0
            RGB1(RGB1==0)=1;
        end
        
        % Version1
        ACC = -log((RGB1+Const1ForNoLog0)./(255+Const1ForNoLog0));
        Dye01Dye02Dye03_Transmittance_v1 = 255.*exp(-ACC*Q3x3Mat);
        
        % Creation of the single mono-channels for the transmittance
        Dye01_transmittance(r,c) = Dye01Dye02Dye03_Transmittance_v1(1);
        Dye02_transmittance(r,c) = Dye01Dye02Dye03_Transmittance_v1(2);
        Dye03_transmittance(r,c) = Dye01Dye02Dye03_Transmittance_v1(3);
    end
end


%% LUT COMPUTATION:

rLUT = double(zeros(256,3));
gLUT = double(zeros(256,3));
bLUT = double(zeros(256,3));
for i= 1:3
    for j = 0:255
        if cosx(i)<0
            rLUT(256-j, i) = 255 + (j * cosx(i));
        else
            rLUT(256-j, i) = 255 - (j * cosx(i));
        end
        
        if cosy(i)<0
            gLUT(256-j, i) = 255 + (j * cosy(i));
        else
            gLUT(256-j, i) = 255 - (j * cosy(i));
        end
        
        if cosz(i)<0
            bLUT(256-j, i) = 255 + (j * cosz(i));
        else
            bLUT(256-j, i) = 255 - (j * cosz(i));
        end
    end
end

% Compute LUT in the format of ImageJ/Fiji
LUTdye01(:,1) = rLUT(:,1);
LUTdye01(:,2) = gLUT(:,1);
LUTdye01(:,3) = bLUT(:,1);
LUTdye02(:,1) = rLUT(:,2);
LUTdye02(:,2) = gLUT(:,2);
LUTdye02(:,3) = bLUT(:,2);
LUTdye03(:,1) = rLUT(:,3);
LUTdye03(:,2) = gLUT(:,3);
LUTdye03(:,3) = bLUT(:,3);
LUTdye01 = LUTdye01./255;
LUTdye02 = LUTdye02./255;
LUTdye03 = LUTdye03./255;
%LUTdye01 = round(LUTdye01.*255); % Use this to obtain the same values of the ImageJ Colour Deconvolution plugin. Basically, it is a uint8 conversion with rounded values.
%LUTdye02 = round(LUTdye02.*255); % Use this to obtain the same values of the ImageJ Colour Deconvolution plugin. Basically, it is a uint8 conversion with rounded values.
%LUTdye03 = round(LUTdye03.*255); % Use this to obtain the same values of the ImageJ Colour Deconvolution plugin. Basically, it is a uint8 conversion with rounded values.

% % Dye01: apply of the LUT
% clear r c
% for r = 1:rowR
%     for c = 1:colR
%         Dye01_LUT(r,c,1) = rLUT(1+uint8(round(Dye01_transmittance(r,c))), 1);
%         Dye01_LUT(r,c,2) = gLUT(1+uint8(round(Dye01_transmittance(r,c))), 1);
%         Dye01_LUT(r,c,3) = bLUT(1+uint8(round(Dye01_transmittance(r,c))), 1);
%     end
% end
% 
% % Dye02: apply of the LUT
% clear r c
% for r = 1:rowR
%     for c = 1:colR
%         Dye02_LUT(r,c,1) = rLUT(1+uint8(round(Dye02_transmittance(r,c))), 2);
%         Dye02_LUT(r,c,2) = gLUT(1+uint8(round(Dye02_transmittance(r,c))), 2);
%         Dye02_LUT(r,c,3) = bLUT(1+uint8(round(Dye02_transmittance(r,c))), 2);
%     end
% end
% 
% % Dye03: apply of the LUT
% clear r c
% for r = 1:rowR
%     for c = 1:colR
%         Dye03_LUT(r,c,1) = rLUT(1+uint8(round(Dye03_transmittance(r,c))), 3);
%         Dye03_LUT(r,c,2) = gLUT(1+uint8(round(Dye03_transmittance(r,c))), 3);
%         Dye03_LUT(r,c,3) = bLUT(1+uint8(round(Dye03_transmittance(r,c))), 3);
%     end
% end


%% REMOVE THE CONTRIBUTION OF A STAINING FROM THE RGB IMAGE:

% Select the stain to be removed:
if DyeToBeRemovedID == 1
    Dye01_transmittance = double(255.*ones(rowR, colR, 1));
elseif DyeToBeRemovedID == 2
    Dye02_transmittance = double(255.*ones(rowR, colR, 1));
elseif DyeToBeRemovedID == 3
    Dye03_transmittance = double(255.*ones(rowR, colR, 1));
end
    
% Use the Q3x3MatInverted to go back in RGB
for r = 1:rowR
    for c = 1:colR
        Dye01Dye02Dye03_transmittance = [Dye01_transmittance(r,c), Dye02_transmittance(r,c), Dye03_transmittance(r,c)];
        ACC2 = -log((Dye01Dye02Dye03_transmittance+Const2ForNoLog0)./(255+Const2ForNoLog0))*Q3x3MatInverted;
        RGB_backNoNorm = exp(-ACC2);
        RGB_back = (255.*RGB_backNoNorm);
        ImgR_back(r,c) = RGB_back(1);
        ImgG_back(r,c) = RGB_back(2);
        ImgB_back(r,c) = RGB_back(3);
    end
end
ImgR_back(ImgR_back>255) = 255;
ImgG_back(ImgG_back>255) = 255;
ImgB_back(ImgB_back>255) = 255;
ImgR_back(ImgR_back<0) = 0;
ImgG_back(ImgG_back<0) = 0;
ImgB_back(ImgB_back<0) = 0;
ImgR_back = floor(ImgR_back); % Use this to obtain the same values of the ImageJ Colour Deconvolution plugin. Basically, it is a uint8 conversion with rounded values.
ImgG_back = floor(ImgG_back); % Use this to obtain the same values of the ImageJ Colour Deconvolution plugin. Basically, it is a uint8 conversion with rounded values.
ImgB_back = floor(ImgB_back); % Use this to obtain the same values of the ImageJ Colour Deconvolution plugin. Basically, it is a uint8 conversion with rounded values.


%% OUTPUT SETTINGS:

format short

