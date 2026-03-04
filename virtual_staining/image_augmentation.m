
% Data augmentation for underrepresented biological structures such as
% blood vessels


find_bv = 1;
augment = 1;
% SPECIFY THE FOLLOWING:
pthCT_patch_train = ''; % MicroCT patches in the training folder (e.g., ...A/train)
pthHE_patch_test = ''; % Histology patches in the training folder (e.g., ...B/train)

if find_bv

    % Select images to perform data augmentation:
    % For example, in VISTACT, we identified blood vessels and pulmonary
    % airways since these structures were underrepresented compared to lung
    % parenchyma.

    outpthCT=[pthCT_patch_train,'blood_vessels/']; if ~isfolder(outpthCT);mkdir(outpthCT);end
    outpthHE=[pthHE_patch_train,'blood_vessels/']; if ~isfolder(outpthHE);mkdir(outpthHE);end
    
    imlist=dir([pthCT_patch,'*.tif']);
    imlist = imlist(~contains({imlist.name}, 'aug'));
    for kk=1:length(imlist)
        fprintf("Image %s \n",imlist(kk).name)
        HE=imread([pthHE_patch,imlist(kk).name]);
        CT=imread([pthCT_patch,imlist(kk).name]);
        figure(kk);imshow(HE);
        prompt = "Keep image? y/n [y]: ";
        txt = input(prompt,"s");
        if isempty(txt)
        txt = 'y';
        end
        if strcmp(txt,'y')
            imwrite(CT,[outpthCT,imlist(kk).name])
            imwrite(HE,[outpthHE,imlist(kk).name])
        end
        close all
    end 
end

if augment
    % Define image folders
    gray_folder = [pthCT_patch_train,'blood_vessels/'];
    color_folder = [pthHE_patch_train,'blood_vessels/'];
    output_gray_folder = pthCT_patch_train;
    output_color_folder = pthHE_patch_train;
    
    % Get a list of all images
    gray_images = dir(fullfile(gray_folder, '*.tif')); % Adjust the extension if needed
    color_images = dir(fullfile(color_folder, '*.tif'));
    
    % Check if both directories have the same number of images
    if length(gray_images) ~= length(color_images)
        error('The number of microCT and histology images must be the same');
    end
    
    % Create output directories if they don't exist
    if ~exist(output_gray_folder, 'dir')
        mkdir(output_gray_folder);
    end
    if ~exist(output_color_folder, 'dir')
        mkdir(output_color_folder);
    end
    
    % Define the number of augmentations
    num_augmentations = 10;
   
    % Loop over each image
    for i = 1:length(gray_images)
        gray_image = imread(fullfile(gray_images(i).folder, gray_images(i).name));
        color_image = imread(fullfile(color_images(i).folder, color_images(i).name));
    
        for j = 1:num_augmentations
            % Apply the same augmentation to both images
            rand_transformation = randomAffine2d('XReflection',true, 'YReflection', true, 'Rotation', [-90 90],'Scale', [0.9 1.3]);
        
            % Calculate the optimal output view for the transformation
            outputView = affineOutputView(size(gray_image), rand_transformation);
            
            % Apply the transformation to the grayscale image with the calculated output view
            gray_augmented = imwarp(gray_image, rand_transformation, 'OutputView', outputView);
            
            % Crop the augmented image to ensure it matches the original size
            gray_augmented = imcrop(gray_augmented, [1, 1, size(gray_image, 2)-1, size(gray_image, 1)-1]);
            
            % Apply the same transformation and cropping to the color image
            color_augmented = imwarp(color_image, rand_transformation, 'OutputView', outputView,'FillValues', 255);
            color_augmented = imcrop(color_augmented, [1, 1, size(color_image, 2)-1, size(color_image, 1)-1]);
                
            % Save the augmented images
            [~, baseFileName, ~] = fileparts(gray_images(i).name);
            augmented_gray_filename = sprintf('%s_aug%d.png', baseFileName, j);
            augmented_color_filename = sprintf('%s_aug%d.png', baseFileName, j);

            if j == 1
                gray_augmented = gray_image;
                color_augmented = color_image;
            end
    
            imwrite(gray_augmented, fullfile(output_gray_folder, augmented_gray_filename));
            imwrite(color_augmented, fullfile(output_color_folder, augmented_color_filename));
        end
    end


 
end