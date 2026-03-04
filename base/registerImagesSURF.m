function [MOVINGREG] = registerImagesSURF(MOVING,FIXED)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Similarity registration using SURF descriptors 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cristina Almagro-Perez, ETH Zürich/PSI, 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

checkLicense()
pSURF3=0;% Plot inlier SURF points used in registration

% Default spatial referencing objects
fixedRefObj = imref2d(size(FIXED));
movingRefObj = imref2d(size(MOVING));

% Detect SURF features
fixedPoints = detectSURFFeatures(FIXED,'MetricThreshold',712.500000,'NumOctaves',3,'NumScaleLevels',5);
movingPoints = detectSURFFeatures(MOVING,'MetricThreshold',712.500000,'NumOctaves',3,'NumScaleLevels',5);

% Extract features
[fixedFeatures,fixedValidPoints] = extractFeatures(FIXED,fixedPoints,'Upright',false);
[movingFeatures,movingValidPoints] = extractFeatures(MOVING,movingPoints,'Upright',false);

% Match features
indexPairs = matchFeatures(fixedFeatures,movingFeatures,'MatchThreshold',40.000000,'MaxRatio',0.400000);
fixedMatchedPoints = fixedValidPoints(indexPairs(:,1));
movingMatchedPoints = movingValidPoints(indexPairs(:,2));
MOVINGREG.FixedMatchedFeatures = fixedMatchedPoints;
MOVINGREG.MovingMatchedFeatures = movingMatchedPoints;
% Visualize overlayed matching points
if pSURF3
    figure(2);
    subplot(1,2,1);imshow(MOVING);title('H&E');hold on;plot(movingMatchedPoints); %pointsHE.selectStrongest(1000)
    figure(2);
    hold on;subplot(1,2,2);imshow(FIXED);title('CT');hold on;plot(fixedMatchedPoints);

    figure(3); 
    showMatchedFeatures(MOVING,FIXED,movingMatchedPoints,fixedMatchedPoints,"montag");
    title("Candidate point matches");
    legend("Matched points H&E","Matched points microCT");
    set(gcf,'color','w');
end

% Apply transformation - Results may not be identical between runs because of the randomized nature of the algorithm
if length(movingMatchedPoints)>2
[tform,inlierIdx] = estimateGeometricTransform2D(movingMatchedPoints,fixedMatchedPoints,'similarity','MaxNumTrials',2000);  %similarity
    % Plot inlier points
    if pSURF3
    inlierPtsDistorted = movingMatchedPoints(inlierIdx,:);
    inlierPtsOriginal  = fixedMatchedPoints(inlierIdx,:);
    figure; 
    showMatchedFeatures(MOVING,FIXED,inlierPtsDistorted,inlierPtsOriginal,"montag")
    title('Matched Inlier Points')
    legend("Matched points H&E","Matched points microCT");
    set(gcf,'color','w');
    end

    MOVINGREG.Transformation = tform;
    MOVINGREG.RegisteredImage = imwarp(MOVING, movingRefObj, tform, 'OutputView', fixedRefObj, 'SmoothEdges', true);
    MOVINGREG.Succesful=1;
else
    MOVINGREG.Succesful=0;

end
% Store spatial referencing object
MOVINGREG.SpatialRefObj = fixedRefObj;

end

function checkLicense()

% Check for license to Computer Vision Toolbox
CVTStatus = license('test','Video_and_Image_Blockset');
if ~CVTStatus
    error(message('images:imageRegistration:CVTRequired'));
end

end

