function converted_map = convert_label_map(img, classes)
    function converted_px = convert_pixel_val(px, classes)
        class_names = fieldnames(classes);
%         px_vals = 0:class_num - 1 % make this 0-based

        % We should speed this up by using a dictionary here
        k = 1; 
        while ~all(px == classes.(class_names{k}))
            k = k + 1;
        end
        converted_px = k - 1;
    end
        
        
        
        
    h = size(img, 1);
    w = size(img, 2); 
    converted_map = zeros(h, w);

    for i = 1:h
        for j = 1:w
            converted_map(i, j) = convert_pixel_val(squeeze(img(i, j, :)), classes);
        end
    end

end