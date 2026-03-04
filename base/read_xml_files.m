function read_xml_files(pth)
% Code to open xml files
%pth='C:\Users\crist\Desktop\Master_thesis\EvaluationRegistration\HeartHE\HistoRegistered\';
outpth=[pth,'matfiles_manual\']; if ~isfolder(outpth);mkdir(outpth);end

imlist=dir([pth,'*xml']);
for j=1:length(imlist)
filename=[pth,imlist(j).name];
fileID=fopen(filename);
%find x coordinates
A = fscanf(fileID,'%s');
k = strfind(A,'X');
l = k(1:2:end);
x = l + 2;
%find y coordinates
k = strfind(A,'Y');
l = k(1:2:end);
y = l + 2;
manual_coordinates=zeros(length(x),2);
for kk=1:length(x) % number of total coordinates
    a=A(x(kk)+3);
    if isstrprop(a,'digit')
        mx=str2double(A(x(kk):x(kk)+3)); ch=isnan(mx);
    else
        mx=str2double(A(x(kk):x(kk)+2)); ch=isnan(mx);
    end
    
    if ch==1; mx=str2double(A(x(kk):x(kk)+1)); ch=isnan(mx);end
    if ch==1; mx=str2double(A(x(kk):x(kk)));end
    manual_coordinates(kk,1)=mx;
    
    a=A(y(kk)+3);
    if isstrprop(a,'digit')
       my=str2double(A(y(kk):y(kk)+3)); ch=isnan(my);
    else
       my=str2double(A(y(kk):y(kk)+2)); ch=isnan(my);
    end
    
    if ch==1; my=str2double(A(y(kk):y(kk)+1));ch=isnan(my);end
    if ch==1; my=str2double(A(y(kk):y(kk)));end
    manual_coordinates(kk,2)=my;
end
save([outpth,imlist(j).name(1:end-3) 'mat'],'manual_coordinates');
end
end
