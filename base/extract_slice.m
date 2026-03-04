function [imCT]=extract_slice(vol,z0,beta,alpha,p)
% -------------------------------------------------------------------------
% Extract a Euclidean plane from a 3D volumetric image. The plane is 
% characterized by a point and two angles (alpha, beta). Please specify:
% -------------------------------------------------------------------------
% vol: 3D volumetric image
% z0: the plane passes through the point [x_center,y_center,z0] of the volume.
% beta:  angle with respect the xy plane (z axis).
% alpha: angle with respect the y axis.
% p (boolean): 1/0. If 1 the extracted plane is rendered on a figure.
% -------------------------------------------------------------------------
if ~exist('p','var');p=0;end % plot extracted slice
if ~exist('alpha','var');alpha=0;end 
beta=beta*(pi/180); 
alpha=alpha*(pi/180); 
xv=cos(alpha)*cos(beta);
yv=sin(alpha)*cos(beta);
zv=sin(beta);
v=[xv,yv,zv];
normal=null(v(:).');
normal=normal(:,2)';
x0=round(size(vol,1)/2);
y0=round(size(vol,2)/2);
point=[x0,y0,z0];
[imCT,x,y,z] = obliqueslice(vol,point,normal,'OutputSize','Full','FillValues',0);
if p %plot extracted slice
figure
surf(x,y,z,imCT,'EdgeColor','None','HandleVisibility','off');
grid on
view([-38 12])
colormap(gray)
xlabel('x-axis')
ylabel('y-axis');
zlabel('z-axis');
set(gcf,'color','w');
title('Slice in 3-D Coordinate Space')
hold on
plot3(point(1),point(2),point(3),'or','MarkerFaceColor','r');
plot3(point(1)+[0 normal(1)],point(2)+[0 normal(2)],point(3)+[0 normal(3)], ...
    '-b','MarkerFaceColor','b');
hold off
legend('Point in the volume')
end
end