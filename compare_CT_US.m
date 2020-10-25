% This script generates a user interface to allow manual measurement of
% bone width with CT and US images. Using these data points, the script
% generates a Bland-Altman plot to compare the two modalities
% close all
if ~exist('V', 'var')
    source_table = dicomCollection('Coronal_volume');
    V = dicomreadVolume(source_table);
    V = squeeze(V); % V is in int16 because there are negative values and positive values -> this should be somewhere between +/- 32768
end

% select desired frame
% all transformational values here are empirical
result_dir = 'Recon_results';
tform_dir = 'US_to_CT_tform';

[frame_to_compare, directory] = uigetfile(strcat(result_dir, '/*.dcm'));

% Still working to interface between
% content = dir(frame_to_compare);
% if contains(content.name, erase(frame_to_compare, '.dcm'))
    
% frame_to_compare = 'Feb_6_20_103mm_300iters.dcm';
% frame_to_compare = 'Feb_6_20_99mm.dcm';

switch frame_to_compare
%     case 'Nov_26_19_40mm.dcm'
%         rot = 67;
%         trans_x = 40.5;
%         trans_y = 12;
%         CT_slice_num = 205;
%     case 'Nov_26_19_39mm.dcm'
%         rot = 35; 
%         trans_x = 39.5;
%         trans_y = 12.5;
%         CT_slice_num = 210;
%     case 'Nov_26_19_38mm.dcm'
%         rot = 45; 
%         trans_x = 41.5;
%         trans_y = 12.5;
%         CT_slice_num = 215;
%     case 'Nov_26_19_37mm.dcm'
%         rot = 5; 
%         trans_x = 40.5;
%         trans_y = 12;
%         CT_slice_num = 220;
%     case 'Nov_26_19_36mm.dcm'
%         rot = 30; 
%         trans_x = 42.5;
%         trans_y = 12;
%         CT_slice_num = 225;
    case 'Feb_6_20_99mm_100iters.dcm'
        rot = 80; 
        trans_x = 37;
        trans_y = 9.3;
        CT_slice_num = 220;
    case 'Feb_6_20_100mm_100iters.dcm'
        rot = 80;
        trans_x = 38.3;
        trans_y = 10.3;
        CT_slice_num = 215;
    case 'Feb_6_20_101mm_100iters.dcm'
        rot = 72.5;
        trans_x = 37.6;
        trans_y = 9.5;
        CT_slice_num = 210;
    case 'Feb_6_20_102mm_100iters.dcm'
        rot = 87;
        trans_x = 39;
        trans_y = 10.5;
        CT_slice_num = 205;
    case 'Feb_6_20_103mm_100iters.dcm'
        rot = 76;
        trans_x = 37.8;
        trans_y = 7.5;
        CT_slice_num = 200;
    case 'Feb_6_20_99mm_300iters.dcm'
        rot = 79; 
        trans_x = 38;
        trans_y = 10;
        CT_slice_num = 220;
    case 'Feb_6_20_100mm_300iters.dcm'
        rot = 80;
        trans_x = 38.3;
        trans_y = 10.3;
        CT_slice_num = 215;
    case 'Feb_6_20_101mm_300iters.dcm'
        rot = 73;
        trans_x = 36;
        trans_y = 8.5;
        CT_slice_num = 210;
    case 'Feb_6_20_102mm_300iters.dcm'
        rot = 87;
        trans_x = 39;
        trans_y = 11;
        CT_slice_num = 205;
    case 'Feb_6_20_103mm_300iters.dcm'
        rot = 76;
        trans_x = 37;
        trans_y = 7.5;
        CT_slice_num = 200;
end

CT_spacing = 0.2; % mm
CT_slice = V(:, :, CT_slice_num); % can change it later
CT_slice = double((CT_slice - min(min(CT_slice)))) / double(max(max(CT_slice) - min(min(CT_slice))));
R_CT = imref2d(size(CT_slice), CT_spacing, CT_spacing);

axial_pixel     = size(CT_slice,1);
lateral_pixel   = size(CT_slice,2);
axial_range    = linspace(1, axial_pixel, axial_pixel);
lateral_range  = linspace(1, lateral_pixel, lateral_pixel);

xMinWorldLimit = min(lateral_range);
xMaxWorldLimit = max(lateral_range);
yMinWorldLimit = min(axial_range);
yMaxWorldLimit = max(axial_range);
all_RAs = imref2d(size(CT_slice), [xMinWorldLimit, xMaxWorldLimit], [yMinWorldLimit, yMaxWorldLimit]);

overscan_size = 3; 
over_scan_xMinWorldLimit = min((xMinWorldLimit - round(xMaxWorldLimit)/1) + (0:(overscan_size*size(CT_slice,2)-1)));
over_scan_xMaxWorldLimit = max((xMinWorldLimit - round(xMaxWorldLimit)/1) + (0:(overscan_size*size(CT_slice,2)-1)));
over_scan_yMinWorldLimit = min((yMinWorldLimit - round(yMaxWorldLimit)/1) + (0:(overscan_size*size(CT_slice,1)-1)));
over_scan_yMaxWorldLimit = max((yMinWorldLimit - round(yMaxWorldLimit)/1) + (0:(overscan_size*size(CT_slice,1)-1)));
overscan_RAs = imref2d(overscan_size*size(CT_slice), [over_scan_xMinWorldLimit, over_scan_xMaxWorldLimit], [over_scan_yMinWorldLimit, over_scan_yMaxWorldLimit]);

US_spacing = 0.033;
% file_dir = '/Users/preston/MATLAB-Drive/Recon_results';
US_slice_info = dicominfo(fullfile(result_dir, frame_to_compare));
US_slice = double(dicomread(US_slice_info));
US_slice = double(US_slice - min(min(US_slice))) / double(max(max(US_slice)) - min(min(US_slice))); % turns into a decimal
US_slice_OG = US_slice;

US_slice = imrotate(US_slice, rot, 'nearest', 'loose'); % I should convert rotation/translation into an affine
R_US = imref2d(size(US_slice), US_spacing, US_spacing);
[US_slice, R_US] = imtranslate(US_slice, R_US, [trans_x, trans_y], 'OutputView', 'full');

% need an overscan_RA so that both transformed images can be fit together
% imshowpair(imwarp(US_slice_OG, R_US, tform, 'FillValues', 0, 'OutputView', overscan_RAs), R_US, CT_slice, R_CT); % not working at the moment.. 

[fused, R_fused] = imfuse(CT_slice, R_CT, US_slice, R_US);
fused = double(fused - min(min(fused))) ./ double(max(max(fused)) - min(min(fused))); % turns into a decimal


% subplot(2, 1, 1)
% imshowpair(US_slice, R_US, CT_slice, R_CT, 'montage')
% title(sprintf("Frame: %s", frame_to_compare))

% subplot(2, 1, 2)
f1 = figure(1);
imshow(fused, R_fused, [0, 1])
title(erase(frame_to_compare, '.dcm'), 'Interpreter','none', 'fontsize', 15)
axis tight
axis off
xlim([40, 60]);
ylim([8, 43]);
% saveas(f1, fullfile('/Users/preston/Desktop', strcat(frame_to_compare, '.svg')))

% Convert the rot, trans_x, and trans_y of each US reconstruction into a
% struct for future usage
fname = strcat(erase(frame_to_compare, '.dcm'), '_tform.mat');
tform = struct();
tform.rot = rot;
tform.trans_x = trans_x;
tform.trans_y = trans_y;
tform.CT_slice_num = CT_slice_num;
save(fullfile(tform_dir, fname), 'tform')

%%
figure(1);
subplot(2, 2, 1:2);
set(gcf,'Position',[100 100 1700 1000])
imshow(fused, R_fused, [0, 1]), hold on
set(gca,'FontSize',20)
ylabel('mm');
xlabel('mm');
xlim([35, 75]);
ylim([5, 45]);
% find profile

% 5 set lines for measuring bone width
num_lines = 10;
y_first_line = 20;
y_step = 0.5;
x_line = [40, 70];
y_pos = zeros(num_lines, 1);
for i = 1:num_lines
    y_pos(i) = y_first_line + (i - 1) * y_step;
end

user_defined_cutline = false;

US_estimates = zeros(num_lines, 1);
CT_estimates = zeros(num_lines, 1);

figure_length = 1700;
figure_height = 1000;

%Display one of the cut-lines
line_to_display = 1;
x = x_line;
y = [y_pos(line_to_display) y_pos(line_to_display)];

plot(x, y, 'b-', 'Linewidth', 2);
[line_profile_x, line_profile_y, line_profile] = improfile(R_fused.XWorldLimits, R_fused.YWorldLimits, fused, x, y, 2500);

line_profile_axis = sqrt(line_profile_x.^2 + linspace(0, line_profile_y(end) - line_profile_y(1), length(line_profile_x))'.^2);
line_profile = squeeze(line_profile);

line_profile(:, 1) = 7 * (line_profile(:, 1) - min(line_profile(:, 1))) / (max(line_profile(:, 1)));
line_profile(:, 2) = 7 * (line_profile(:, 2) - min(line_profile(:, 2))) / (max(line_profile(:, 2)));

plot(line_profile_axis, line_profile(:, 1) + y_pos(line_to_display), 'm-', 'Linewidth', 2);
plot(line_profile_axis, line_profile(:, 2) + y_pos(line_to_display), 'g-', 'Linewidth', 2);

legend('cut line', 'US', 'CT', 'fontsize', 20);

subplot(2, 2, 3);
imshow(US_slice, R_US); axis on; hold on
plot(line_profile_axis, line_profile(:, 1) + y_pos(line_to_display), 'm-', 'Linewidth', 2);
set(gca,'FontSize',20)
ylabel('mm');
xlabel('mm');

subplot(2, 2, 4);
imshow(CT_slice, R_CT); axis on; hold on
plot(line_profile_axis, line_profile(:, 2) + y_pos(line_to_display), 'g-', 'Linewidth', 2); hold off
set(gca,'FontSize',20)
ylabel('mm');
xlabel('mm');
% trying to register the final images together; not so easy at the moment
% figure(2);
% metric = registration.metric.MeanSquares();
% optimizer = registration.optimizer.RegularStepGradientDescent();
% tformed = imregister(US_slice, R_US, CT_slice, R_CT, 'rigid', optimizer, metric);
% imshowpair(CT_slice, tformed);
%%
for j = 1:num_lines
    % user-defined line
    if user_defined_cutline
        [x, y] = ginput(2);
    else
        x = x_line;
        y = [y_pos(j) y_pos(j)];
    end
    figure(1);
    plot(x, y, 'b-', 'Linewidth', 2); hold off;
    [line_profile_x, line_profile_y, line_profile] = improfile(R_fused.XWorldLimits, R_fused.YWorldLimits, fused, x, y, 2500);
    
    line_profile_axis = sqrt(line_profile_x.^2 + linspace(0, line_profile_y(end) - line_profile_y(1), length(line_profile_x))'.^2);
    line_profile = squeeze(line_profile);

    figure(2);
    title(sprintf('US image, %d/%d', j, num_lines));
    x_US_line(1) = find_x_thresh(line_profile_axis, line_profile(:, 1));
    x_US_line(2) = find_x_thresh(line_profile_axis, line_profile(:, 1));
%     xline(x_US_line(1), 'r.')
%     xline(x_US_line(2), 'r.')
%     
%     [x_US_line, y_US_line] = ginput(2);
%     xline(x_US_line(1), 'r.')
%     xline(x_US_line(2), 'r.')
    
    US_estimate = x_US_line(2) - x_US_line(1);
    US_estimates(j) = US_estimate;
%     legend(sprintf('US estimate: %.2f', US_estimate));
%     hold off

    figure(3);
    title(sprintf('CT image, %d/%d', j, num_lines));
    x_CT_line(1) = find_x_thresh(line_profile_axis, line_profile(:, 2));
    x_CT_line(2) = find_x_thresh(line_profile_axis, line_profile(:, 2));
%     xline(x_US_line(1), 'r.')
%     set(gcf,'Position',[100 100 figure_length figure_height])
%     plot(line_profile_axis, line_profile(:, 2), 'g-'), hold on
%     yticks(0:0.01:1);
    % plot(x_US_line, [y_US_line(1), y_US_line(1)], 'r.-');
%     [x_CT_line, y_CT_line] = ginput(2);
%     xline(x_CT_line(1), 'g.')
%     xline(x_CT_line(2), 'g.')
    
    CT_estimate = x_CT_line(2) - x_CT_line(1);
    CT_estimates(j) = CT_estimate;
    % plot(x_CT_line, [y_CT_line(1), y_CT_line(1)], 'g.-');
%     legend(sprintf('CT estimate: %.2f', CT_estimate));
%     hold off
end


% US_estimates (second set, different y locations) = [9.1765, 9.5863,
% 9.9507, 10.3833, 18.7932]'
% CT_estimates (second set, different y locations) = [13.3435, 13.7078,
% 14.1176, 13.8899, 14.3454]'

%% A different way of measuring bone width (overlay intensity on image)
% Need at least 1 replicate
n_replicates = 2;
US_estimates = zeros(num_lines, n_replicates);
CT_estimates = zeros(num_lines, n_replicates);

for j = 1:num_lines
    % user-defined line
    if user_defined_cutline
        [x, y] = ginput(2);
    else
        x = x_line;
        y = [y_pos(j) y_pos(j)];
    end
    
    [line_profile_x, line_profile_y, line_profile] = improfile(R_fused.XWorldLimits, R_fused.YWorldLimits, fused, x, y, 2500);
    line_profile_axis = sqrt(line_profile_x.^2 + linspace(0, line_profile_y(end) - line_profile_y(1), length(line_profile_x))'.^2);
    line_profile = squeeze(line_profile);
    
    line_profile(:, 1) = 7 * (line_profile(:, 1) - min(line_profile(:, 1))) / (max(line_profile(:, 1)));
    line_profile(:, 2) = 7 * (line_profile(:, 2) - min(line_profile(:, 2))) / (max(line_profile(:, 2)));
    
    for n = 1:n_replicates
    
        figure(2);
        imshow(imcomplement(US_slice), R_US); axis on; hold on
        plot(x, y, 'b-', 'Linewidth', 2);
        plot(line_profile_axis, line_profile(:, 1) + y_pos(j), 'm-', 'Linewidth', 2); hold off
        xlim([40, 60])
        ylim([10, 30])
        set(gca,'FontSize',20)
        set(gcf,'Position',[100 100 figure_length figure_height])
        ylabel('mm');
        xlabel('mm');
        title("click on the left side of bone"); [left_x_US, ~] = ginput(1);
        title("click on the right side of bone"); [right_x_US, ~] = ginput(1);

        US_estimate = right_x_US - left_x_US;
        US_estimates(j, n) = US_estimate;

        figure(3);
        imshow(imcomplement(CT_slice), R_CT); axis on; hold on
        plot(x, y, 'b-', 'Linewidth', 2);
        plot(line_profile_axis, line_profile(:, 2) + y_pos(j), 'g-', 'Linewidth', 2); hold off
        xlim([40, 60])
        ylim([10, 30])
        set(gca,'FontSize',20)
        set(gcf,'Position',[100 100 figure_length figure_height])
        ylabel('mm');
        xlabel('mm');
        title("click on the left side of bone"); [left_x_CT, ~] = ginput(1);
        title("click on the right side of bone"); [right_x_CT, ~] = ginput(1);

        CT_estimate = right_x_CT - left_x_CT;
        CT_estimates(j, n) = CT_estimate;
    end
end
%% Run the most recent analysis
% Use calculateCI(data1, data2, num_lines) to get the CI for difference in
% mean. 
close all;
load('US_estimates_01_08.mat')
load('CT_estimates_01_08.mat')
[rpc1, fig1] = BlandAltman(US_estimates(:, 1), CT_estimates(:, 1), {'US', 'CT', 'mm'}, 'Comparison between US and CT (1st set)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});
% [rpc2, fig2] = BlandAltman(US_estimates(:, 2), CT_estimates(:, 2), {'US', 'CT', 'mm'}, 'Comparison between US and CT (2nd set)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});
% [rpc3, fig3] = BlandAltman(US_estimates(:, 1), US_estimates(:, 2), {'US_1', 'US_2', 'mm'}, 'Comparison between 1st and 2nd (US)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});
% [rpc4, fig4] = BlandAltman(CT_estimates(:, 1), CT_estimates(:, 2), {'CT_1', 'CT_2', 'mm'}, 'Comparison between 1st and 2nd (CT)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});
% fig1.Position=[0.0475, 0.0759, 0.6, 0.4];
% fig2.Position=[0.0475, 0.0759, 0.6, 0.4];
% fig3.Position=[0.0475, 0.0759, 0.6, 0.4];
% fig4.Position=[0.0475, 0.0759, 0.6, 0.4];

