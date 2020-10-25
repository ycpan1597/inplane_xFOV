% Convert ROIs exported with the "ExportROIs" plug-in from Horos into pairs
% of points that draw a polygon
close all; 

% csvfile = '/Users/preston/Desktop/ROIs_from_plugin.csv';

[filename, pathname] = uigetfile('*.csv');
csvfile = fullfile(pathname, filename);
M = readmatrix(csvfile);
slice_number = M(1, 1);
% img = dicomread(sprintf('/Volumes/GoogleDrive/My Drive/US_research_cloud/Current Research/Coronal_volume/IMG%04d.dcm', slice_number));
img = select_and_read_dcm('/Users/preston/Documents/Horos Data/DATABASE.noindex/40000/39203.dcm');

num_of_points = M(:, 15); % useful for extracting all ROI xy positions
% name_of_rois = M(:, 8); % DOESN"T WORK - readmatrix converts string to NaN
name_of_rois = ["class 1", "class 2", "class 3"];
start_of_xy_positions = 16;
rois = cell(3, 1); 
for i = 1:size(M, 1)
    cur_roi_positions = M(i, start_of_xy_positions: start_of_xy_positions + num_of_points(i) * 5 - 1);
    cleaned_cur_roi_positions = zeros(num_of_points(i), 2);
    cleaned_idx = 1;
    for j = 1 : 5: length(cur_roi_positions)
        cleaned_cur_roi_positions(cleaned_idx, 1) = cur_roi_positions(j+3);
        cleaned_cur_roi_positions(cleaned_idx, 2) = cur_roi_positions(j+4);
        cleaned_idx = cleaned_idx + 1;
    rois{i} = cleaned_cur_roi_positions;
    end
end

mask = zeros(size(img)); % base of mask
for i = 1:size(M, 1)
%     patch(rois{i}(:, 1), rois{i}(:, 2), colors(i), 'Parent', ax2); hold on
    BW = poly2mask(rois{i}(:, 1), rois{i}(:, 2), size(img, 1), size(img, 2));
    mask(BW) = i;
end

f1 = figure(1);
ax1 = subplot(2, 1, 1);
imshow(img, [], 'Parent', ax1);
axis on
ax2 = subplot(2, 1, 2);
axis on
imshow(mask, [], 'Parent', ax2);
f1.Position = [600, 400, 550, 800];

% imwrite(img, 'slice343-image.png');
% imwrite(ax2, 'slice343-label.png');


%%
img = dicomread('/Volumes/GoogleDrive/My Drive/US_research_cloud/Current Research/Coronal_volume/IMG0343.dcm');
imshow(img); hold on
plot(rois{1}(:, 1), rois{1}(:, 2), 'r.-');