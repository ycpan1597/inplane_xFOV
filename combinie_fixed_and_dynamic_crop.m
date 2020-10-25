data = dicomread('/Volumes/GoogleDrive/My Drive/2016-08-28 in vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Pig_1R/US Data/Mar_13_20/premolar.DCM');
data = squeeze(mean(data, 3));
[h, w, l] = size(data);
load('/Volumes/GoogleDrive/My Drive/US_research_cloud/Current Research/334x331_rect.mat')
rect = int64(rect);

%%
mydata_bw = zeros(rect(4), rect(3), l);
pre_crop_width = 600;
pre_crop_height = 500; 
pre_crop_rect = [w/2-pre_crop_width/2 100 pre_crop_width-1 pre_crop_height-1]; % [x_upperleft, y_upperleft, width, height]
for i = 1:l
    cur = data(:, :, i);
    if i == 1
        mydata_bw(:, :, i) = imcrop(cur, 'rect', [rect(1), rect(2), rect(3) - 1, rect(4) - 1]);
    else
        cur = imcrop(cur, 'rect', pre_crop_rect);
        mydata_bw(:, :, i) = crop_wrt_centroid(cur, rect(3), rect(4));
    end
end

% [h, w, l] = size(mydata_bw);
% exp_date = 'Mar_13_20';
% save('Cropped_image_stacks/Mar_13_20/premolar_334x331.mat', 'mydata_bw', 'h', 'w', 'l', 'exp_date'); 

    