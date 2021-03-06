% This function takes in images that are pre-cropped (i.e. without US text)
% and returns an image based on the center of mass of the image

function cropped = crop_wrt_centroid(img, thresh, rect_width, rect_height)
    clf
    [pre_crop_height, pre_crop_width] = size(img);
    larger_dimension = max(pre_crop_height, pre_crop_width);
    
    img = padarray(img, [larger_dimension, larger_dimension], 0, 'both'); % first we want to pad the image with enough zeros
    
    % Simply finding the centroid of the entire image - sometimes this
    % could be outside of the image of interest, and you could actually end
    % up REDUCING the amount of information!
%     binaryImage = true(size(img));
%     labeledImage = logical(binaryImage);
%     measurements = regionprops(labeledImage, img, 'WeightedCentroid');
%     COM = measurements.WeightedCentroid;

    % Finding the centroid of the largest component (useful information) -
    % hmm this bit doesn't work well    
    binaryImage = img > thresh; % 20 is an arbitrary threshold
    binaryImage = bwareaopen(binaryImage, 300); % remove components smaller than 1000 pixels
    binaryImage = logical(binaryImage);
    measurements = regionprops(binaryImage, 'Centroid');
    COM = measurements.Centroid;
    
    x_upperleft = int64(COM(1)) - int64(rect_width/2); 
    y_upperleft = int64(COM(2)) - int64(rect_height/2);
    
%     Pad image with zero to increase field of view
%     if x_upperleft + rect_width > pre_crop_width % exceed x direction pixels
%         disp('horzcat!');
%         img = horzcat(img, zeros(pre_crop_height, int64(x_upperleft) + rect_width - pre_crop_width + 1));
%     elseif y_upperleft + rect_height > pre_crop_height
%         disp('vertcat!');
%         img = vertcat(img, zeros(int64(y_upperleft) + rect_height - pre_crop_height + 1, pre_crop_width));
%     end
    imshow(img, [0, 255]); hold on
    plot(COM(1), COM(2), 'g.', 'Markersize', 10);
    drawrectangle('Position', [x_upperleft, y_upperleft, rect_width - 1, rect_height - 1]);
    pause()
    cropped = imcrop(img, 'rect', [x_upperleft, y_upperleft, rect_width - 1, rect_height - 1]);
end