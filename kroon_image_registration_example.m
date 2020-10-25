% clean
clear all; close all; clc;

load('/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Cropped_image_stacks/Sep_17_20/98mm_504x369.mat');

type='d';
scale = [1 1 1];
x0 = [0 0 0];

% options = optimoptions(@lsqnonlin, 'MaxFunctionEvaluations', 500 * length(x0), 'PlotFcns', 'optimplotresnorm');
options = optimoptions(@lsqnonlin, 'MaxFunctionEvaluations', 500 * length(x0));

optimizer = registration.optimizer.RegularStepGradientDescent();
optimizer.MaximumIterations = 400;
metric = registration.metric.MeanSquares();
%% simply compare kroon and matlab
moving = mydata_bw(:, :, 127);
fixed = mydata_bw(:, :, 126);
[x] = lsqnonlin(@(x)affine_registration_image(x,scale,moving,fixed,type), x0);
x=x.*scale;
M=make_transformation_matrix(x(1:2),x(3));
Icor=affine_transform(moving,M,3); % 3 stands for cubic interpolation

figure('Position', [10 10 1000 600])
subplot(1, 2, 1)
imshowpair(Icor, fixed)
title(sprintf('Using Kroon, normalized difference=%.2f', norm(imabsdiff(Icor, fixed))/norm(fixed)));

tformReg = imregtform(moving, fixed, 'rigid', optimizer, metric);
warpped = imwarp(moving, tformReg, 'OutputView', imref2d(size(fixed)));
subplot(1, 2, 2)
imshowpair(warpped, fixed);
title(sprintf('Using Matlab, normalized difference=%.2f', norm(imabsdiff(warpped, fixed))/norm(fixed)))

%% compare effect of padding size on both kroon and matlab
pad_size = 0:1:10;
norm_diff = zeros(length(pad_size), 2); 
moving = mydata_bw(:, :, 127);
fixed = mydata_bw(:, :, 126);

for i = 1:length(pad_size)
    moving_padded = padarray(moving, [pad_size(i), pad_size(i)], 0);
    fixed_padded = padarray(fixed, [pad_size(i), pad_size(i)], 0);

%     [x]= lsqnonlin(@(x)affine_registration_image(x,scale,moving,fixed,type), x0, [], [], optimset('Display','iter','MaxIter',100, 'PlotFcns', 'optimplotresnorm'));
    [x] = lsqnonlin(@(x)affine_registration_image(x,scale,moving_padded,fixed_padded,type), x0);
    x=x.*scale;
    M=make_transformation_matrix(x(1:2),x(3));
    Icor=affine_transform(moving,M,3); % 3 stands for cubic interpolation
    norm_diff(i, 1) = norm(Icor - fixed)/norm(fixed);
    
    tformReg = imregtform(moving_padded, fixed_padded, 'rigid', optimizer, metric);
    warpped = imwarp(moving, tformReg, 'OutputView', imref2d(size(fixed)));
    norm_diff(i, 2)= norm(imabsdiff(warpped, fixed))/norm(fixed);
end
plot(pad_size, norm_diff(:, 2), '.-', 'DisplayName', 'Matlab'); hold on
plot(pad_size, norm_diff(:, 1), '.-', 'DisplayName', 'Kroon'); hold off
legend()
xlabel('Number of padded pixels (per direction)')
ylabel('Normalized difference after registration')
set(findall(gcf,'-property','FontSize'),'FontSize',18)

%% Accumulate transforms
frames_to_read = 150:1:175;
tforms = zeros(3, 3, length(frames_to_read) - 1);
matlab_difference = zeros(length(frames_to_read) - 1, 1);
kroon_difference = zeros(length(frames_to_read) - 1, 1);
padded_data = padarray(mydata_bw, [1, 1], 0);

tic
for i = 1:length(frames_to_read) - 1 % kroon took 83 s and matlab imregtform took 57 s for 100 images
    cur = double(padded_data(:, :, frames_to_read(i)));
    next = double(padded_data(:, :, frames_to_read(i + 1)));

    % Smooth both images for faster registration
    cur=imfilter(cur,fspecial('gaussian'));
    next=imfilter(next,fspecial('gaussian'));
    
    current_ref_obj = imref2d(size(cur));
    next_ref_obj = imref2d(size(next));
        
%     [x_current, y_current] = meshgrid(1:size(cur,2),1:size(cur,1));
%     [x_next,y_next] = meshgrid(1:size(next,2),1:size(next,1));
%     sum_current_intensity = sum(cur(:));
%     sum_next_intensity = sum(next(:));
%     cur_x_COM = (current_ref_obj.PixelExtentInWorldX .* (sum(x_current(:).*double(cur(:))) ./ sum_current_intensity)) + current_ref_obj.XWorldLimits(1);
%     cur_y_COM = (current_ref_obj.PixelExtentInWorldY .* (sum(y_current(:).*double(cur(:))) ./ sum_current_intensity)) + current_ref_obj.YWorldLimits(1);
%     next_x_COM = (next_ref_obj.PixelExtentInWorldX .* (sum(x_next(:).*double(next(:))) ./ sum_next_intensity)) + next_ref_obj.XWorldLimits(1);
%     next_y_COM = (next_ref_obj.PixelExtentInWorldY .* (sum(y_next(:).*double(next(:))) ./ sum_next_intensity)) + next_ref_obj.YWorldLimits(1);
%     translation_x = cur_x_COM - next_x_COM;
%     translation_y = cur_y_COM - next_y_COM;
%     
%     init_Tform = affine2d();
%     init_Tform.T(3,1:2) = [translation_x, translation_y];
%     
%     tformReg = imregtform(next, cur, 'rigid', optimizer, metric); % this step matches current (moving) to the next (fixed)
%     matlab_tformed = imwarp(next, tformReg, 'OutputView', imref2d(size(cur)));
%     matlab_difference(i) = norm(cur - matlab_tformed) / norm(cur);

    [x]= lsqnonlin(@(x)affine_registration_image(x,scale,next,cur,type), x0); % register next back to current (, [], [], optimset('PlotFcns', 'optimplotresnorm'))
    % @(x)affine_registration_image(x,scale,I1s,I2s,type) produces the error
    % that is to be minimized with 5 independent parameters (translateX
    % translateY rotate resizeX resizeY)

    % [0 0 0 100 100] are the starting values of tx, ty, theta, sx, and sy

    % optimset('Display','iter','MaxIter',100) - optimization parameters used
    % by lsqnonlin
    
    % Scale the translation, resize and rotation parameters to the real values
    x=x.*scale;

    % Make the affine transformation matrix
    M=make_transformation_matrix(x(1:2),x(3));
    
    tforms(:, :, i) = M;
    
    kroon_tformed = affine_transform(next, M, 3);
    kroon_difference(i) = norm(cur - kroon_tformed) / norm(cur);
    
    if i == 1 
        combined_M = inv(M);
        combined_image = cur;
    else
        combined_M = combined_M * inv(M);
%         combined_M = M * combined_M;
        tformed_image = affine_transform(next, inv(combined_M), 3);
        combined_image = max(combined_image, tformed_image);
    end
    imshow(combined_image, []);
    pause(); 
end
toc
% imshow(combined_image, [])
%%
close all
plot(matlab_difference)
hold on; plot(kroon_difference)
legend('matlab', 'kroon')
xlabel('frames')
ylabel('normalized difference after registration')
set(findall(gcf,'-property','FontSize'),'FontSize',18)
%%
ref = mydata_bw(:, :, 1); % original size
axial_pixel     = size(ref,1);
lateral_pixel   = size(ref,2);
axial_range    = linspace(1, axial_pixel, axial_pixel);
lateral_range  = linspace(1, lateral_pixel, lateral_pixel);

xMinWorldLimit = min(lateral_range);
xMaxWorldLimit = max(lateral_range);
yMinWorldLimit = min(axial_range);
yMaxWorldLimit = max(axial_range);
all_RAs = imref2d(size(ref), [xMinWorldLimit, xMaxWorldLimit], [yMinWorldLimit, yMaxWorldLimit]);

overscan_size = 4;
over_scan_xMinWorldLimit = min((xMinWorldLimit - round(xMaxWorldLimit)/1) + (0:(overscan_size*size(ref,2)-1)));
over_scan_xMaxWorldLimit = max((xMinWorldLimit - round(xMaxWorldLimit)/1) + (0:(overscan_size*size(ref,2)-1)));
over_scan_yMinWorldLimit = min((yMinWorldLimit - round(yMaxWorldLimit)/1) + (0:(overscan_size*size(ref,1)-1)));
over_scan_yMaxWorldLimit = max((yMinWorldLimit - round(yMaxWorldLimit)/1) + (0:(overscan_size*size(ref,1)-1)));
overscan_RAs = imref2d(overscan_size*size(ref), [over_scan_xMinWorldLimit, over_scan_xMaxWorldLimit], [over_scan_yMinWorldLimit, over_scan_yMaxWorldLimit]);

img1_warpped = imwarp(ref, affine2d(eye(3)), 'FillValues', 0, 'OutputView', overscan_RAs);
imshow(img1, [0, 255])
figure; imshow(img1_warpped, [0, 255])

%% Test out kroon's affine transform
img = imread('/Volumes/GoogleDrive/My Drive/Umich Research/2020-03-25 Dental Segmentation/nickel.jpg');
M = [1 0 300; 0 1 100; 0 0 1];
tformed_img = affine_transform(img, inv(M));
imshowpair(img, tformed_img);
