function [rfp,mvp,szPadHisto,szPadCT]=preprocess(rf,mv,ext)
% -------------------------------------------------------------------------
% Pad images for registration
% -------------------------------------------------------------------------
% Cristina Almagro-Pérez, ETH Zürich, 2023
% -------------------------------------------------------------------------
PadValue=0;

% Pad to match the largest size image & add extra padding
sz=[max(size(mv,1),size(rf,1)), max(size(mv,2),size(rf,2))];

% Histology image
szim=[sz(1)-size(mv,1) sz(2)-size(mv,2)];
szA=floor(szim/2);szB=szim-szA+ext;szA=szA+ext;
mvp=padarray(mv,szA,PadValue,'pre');
mvp=padarray(mvp,szB,PadValue,'post');
szPadHisto=[szA,szB]; %padding added to the histo

% MicroCT plane
szim=[sz(1)-size(rf,1) sz(2)-size(rf,2)];
szA=floor(szim/2);szB=szim-szA+ext;szA=szA+ext;
rfp=padarray(rf,szA,PadValue,'pre');
rfp=padarray(rfp,szB,PadValue,'post');
szPadCT=[szA,szB]; %padding added to the ct

end