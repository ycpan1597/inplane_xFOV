function images = process_dcm_images_for_registration(d, post_crop_width, post_crop_height)
    
    directory = dir(d);
    w_before = 960;
    pre_crop_width = 600;
    pre_crop_height = 500;
    pre_crop_rect = [w_before/2-pre_crop_width/2 100 pre_crop_width-1 pre_crop_height-1];
    
    l = 0;
    files = {};
    for i = 1:length(directory)
        if contains(lower(directory(i).name), '.dcm')
            l = l + 1;
            files{end + 1} = directory(i).name;
        end
    end
    
    images = zeros(post_crop_height, post_crop_width, l); 
    
    for i = 1:length(files)
        img = dicomread(fullfile(d, files{i}));
        img = squeeze(mean(img, 3));
        pre_cropped = imcrop(img, 'rect', pre_crop_rect);
        padded_pre_cropped = padarray(pre_cropped, [w_before, w_before], 0, 'both');
        centroid_crop = crop_wrt_centroid(padded_pre_cropped, post_crop_width, post_crop_height);
        images(:, :, i) = centroid_crop;
    end
end