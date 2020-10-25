% Select one or several DCM cineloop files
starting_dir = '/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Raw Data';
[files, directory] = uigetfile(fullfile(starting_dir, '*.DCM'), 'MultiSelect', 'On');
if isa(files, 'char')
    files = {files};
end

% Extract date from the path and create a folder with that date
pathparts = strsplit(directory, '/');
exp_date = pathparts(end - 1);
exp_date = exp_date{1}; % text is wrapped in curly braces
fprintf('Experiment was done on %s; please correct file path if incorrect\n', exp_date);

save_to = fullfile('/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Cropped_image_stacks', exp_date);
if ~exist(save_to, 'dir')
    mkdir(save_to);
else
    disp('Directory already exists, check if window size is the same to avoid overwriting')
    ls(save_to);
end
%%
range_set = false;
use_existing_rect = false;
thresh = 7; % applicable if using "crop_wrt_centroid"

if use_existing_rect
    load(uigetfile('*.mat'));
    range_set = true;
end
tic
for i = 1:length(files)
    
    % assuming that the rect from the previous forloop is still in memory
    myinfo = dicominfo(fullfile(directory, files{i}));
    mydata = dicomread(myinfo);
    mydata_bw = squeeze(mean(mydata,3));
    [h_before, w_before, l_before] = size(mydata_bw);

    % This rectangle crops out text
    pre_crop_width = 600;
    pre_crop_height = 500;
    pre_crop_rect = [w_before/2-pre_crop_width/2 100 pre_crop_width-1 pre_crop_height-1];

    if ~range_set
        % Another way of cropping
        [cropped, rect] = imcrop(mydata_bw(:, :, 1)/255); % rect must be called "rect" otherwise files won't load properly
        rect = int64(rect);
        save(sprintf('%dx%d_rect.mat', rect(3), rect(4)), 'rect');
        range_set = true;
    end
    
    mydata_bw_cropped = zeros(rect(4), rect(3), l_before);

    for j = 1:l_before
        fprintf('%d\n', j);
        cur = mydata_bw(:, :, j);
        mydata_bw_cropped(:, :, j) = imcrop(cur, 'rect', [rect(1), rect(2), rect(3) - 1, rect(4) - 1]);
        
        % If you want to crop with respect to the centroid (very sensitive
        % to the threshold of the image --> not very robust)
%         if j == 1 % The first image should not be moved to the center of the image b/c that might mess up multi-planar alignment with CT
%             mydata_bw_cropped(:, :, j) = imcrop(cur, 'rect', [rect(1), rect(2), rect(3) - 1, rect(4) - 1]); % There might be a minus 1 in the height and width of the rectangle
%         else
%             cur = imcrop(cur, 'rect', pre_crop_rect);
%             mydata_bw_cropped(:, :, j) = crop_wrt_centroid(cur, thresh, rect(3), rect(4));
%         end
    end
    mydata_bw = mydata_bw_cropped;
    [h, w, l] = size(mydata_bw);

    var_name = sprintf('%s_%dx%d.mat', erase(files{i}, ".DCM"), h, w);
    save(fullfile(save_to, var_name), 'mydata_bw', 'h', 'w', 'l', 'exp_date'); 
end
toc