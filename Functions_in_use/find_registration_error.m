%find_registration_error Calculates the relative error before and after
%registration
%
%   find_registration_error(cur, next, tform) Warps next to current using
%   tform (tform needs to be an affine2D object) and computes relative
%   error before and after registration.
%   
%   find_registration_error(cur, next) Registers next to current and
%   computes relative error before and after registration.
%   MinimumStepLength = 1e-3, MaximumIterations = 100;

function error_ratio = find_registration_error(show_fused_image, current, next, tform)
    switch nargin
        case 4
            % passes to the main function
        case 3
            current_ref_obj = imref2d(size(current));
            next_ref_obj = imref2d(size(next));

            % using insight learned from the registration estimator:
            % Align centers
            [x_current, y_current] = meshgrid(1:size(current,2),1:size(current,1));
            [x_next,y_next] = meshgrid(1:size(next,2),1:size(next,1));
            sum_current_intensity = sum(current(:));
            sum_next_intensity = sum(next(:));
            cur_x_COM = (current_ref_obj.PixelExtentInWorldX .* (sum(x_current(:).*double(current(:))) ./ sum_current_intensity)) + current_ref_obj.XWorldLimits(1);
            cur_y_COM = (current_ref_obj.PixelExtentInWorldY .* (sum(y_current(:).*double(current(:))) ./ sum_current_intensity)) + current_ref_obj.YWorldLimits(1);
            next_x_COM = (next_ref_obj.PixelExtentInWorldX .* (sum(x_next(:).*double(next(:))) ./ sum_next_intensity)) + next_ref_obj.XWorldLimits(1);
            next_y_COM = (next_ref_obj.PixelExtentInWorldY .* (sum(y_next(:).*double(next(:))) ./ sum_next_intensity)) + next_ref_obj.YWorldLimits(1);
            translation_x = cur_x_COM - next_x_COM;
            translation_y = cur_y_COM - next_y_COM;

            % Coarse alignment
            init_Tform = affine2d();
            init_Tform.T(3,1:2) = [round(translation_x, 2), round(translation_y, 2)];
            
            metric = registration.metric.MeanSquares();
            optimizer = registration.optimizer.RegularStepGradientDescent();
            optimizer.MaximumIterations = 100;
            optimizer.MinimumStepLength = 1e-3;
            optimizer.MaximumStepLength = 6.25e-2;
            tform = imregtform(next, current, 'rigid', optimizer, metric, 'InitialTransformation', init_Tform);
            
        otherwise
            disp('Wrong number of inputs')
    end
    
    axial_pixel     = size(current,1);
    lateral_pixel   = size(current,2);
    axial_range    = linspace(1, axial_pixel, axial_pixel);
    lateral_range  = linspace(1, lateral_pixel, lateral_pixel);

    xMinWorldLimit = min(lateral_range);
    xMaxWorldLimit = max(lateral_range);
    yMinWorldLimit = min(axial_range); 
    yMaxWorldLimit = max(axial_range); 
    all_RAs = imref2d(size(current), [xMinWorldLimit, xMaxWorldLimit], [yMinWorldLimit, yMaxWorldLimit]);

    overscan_size = 3; 
    overscan_xMinWorldLimit = min((xMinWorldLimit - round(xMaxWorldLimit)/1) + (0:(overscan_size*size(current,2)-1)));
    overscan_xMaxWorldLimit = max((xMinWorldLimit - round(xMaxWorldLimit)/1) + (0:(overscan_size*size(current,2)-1)));
    overscan_yMinWorldLimit = min((yMinWorldLimit - round(yMaxWorldLimit)/1) + (0:(overscan_size*size(current,1)-1)));
    overscan_yMaxWorldLimit = max((yMinWorldLimit - round(yMaxWorldLimit)/1) + (0:(overscan_size*size(current,1)-1)));
    overscan_RAs = imref2d(overscan_size*size(current), [overscan_xMinWorldLimit, overscan_xMaxWorldLimit], [overscan_yMinWorldLimit, overscan_yMaxWorldLimit]);

    center = [(overscan_xMinWorldLimit + overscan_xMaxWorldLimit)/2 - overscan_xMinWorldLimit, (overscan_yMinWorldLimit + overscan_yMaxWorldLimit)/2 - overscan_yMinWorldLimit];

    % convert cur and next into the overscan coordinate system so that
    % there would be the same number of pixels
    tform_identity = affine2d([1 0 0; 0 1 0; 0 0 1]);
    [cur_overscan, ~] = imwarp(current, all_RAs, tform_identity, 'FillValues', double(0), 'OutputView', overscan_RAs);
    [next_overscan, ~] = imwarp(next, all_RAs, tform_identity, 'FillValues', double(0), 'OutputView', overscan_RAs);
    
    error_before = imabsdiff(cur_overscan, next_overscan);
    error_in_center_before = norm(error_before(center(2) - floor(axial_pixel/2):center(2) + floor(axial_pixel/2), center(1) - floor(lateral_pixel/2):center(1) + floor(lateral_pixel/2)));
    
    [transformed_overscan, ~] = imwarp(next, all_RAs, tform, 'FillValues', double(0), 'OutputView', overscan_RAs);
    error_after = imabsdiff(cur_overscan, transformed_overscan);
    error_in_center_after = norm(error_after(center(2) - floor(axial_pixel/2):center(2) + floor(axial_pixel/2), center(1) - floor(lateral_pixel/2):center(1) + floor(lateral_pixel/2)));
    
    error_ratio = error_in_center_after / error_in_center_before;
    
    % what happens if we don't extract the center
    error_ratio = norm(error_after) / norm(error_before);
    
    ha = tight_subplot(2, 2, [0.1, 0], 0.1, 0.1);
    
    fontsize = 15;
    if show_fused_image
        axes(ha(1));
%         subplot(2, 2, 1)
        imshowpair(cur_overscan, next_overscan);
        xlim([300, 800])
        ylim([300, 800])
        title('Overlaid before registration', 'fontsize', fontsize)
        
        axes(ha(2));
%         subplot(2, 2, 2)
        imshowpair(transformed_overscan, cur_overscan);
        title('Overlaid after registration', 'fontsize', fontsize)
%         title(sprintf('error ratio = %.4f', error_ratio));
        xlim([300, 800])
        ylim([300, 800])
        
        axes(ha(3));
%         subplot(2, 2, 3)
        imshow(imabsdiff(cur_overscan, next_overscan), [0, 255]);
        xlim([300, 800])
        ylim([300, 800])
        title(sprintf('Abs. Diff before registration\nL2 norm = %.2f', norm(error_before)), 'fontsize', fontsize)
        
        axes(ha(4));
%         subplot(2, 2, 4)
        imshow(error_after, [0, 255]);
        xlim([300, 800])
        ylim([300, 800])
        title(sprintf('Abs. Diff after registration\nL2 norm = %.2f, err. ratio = %.2f', norm(error_after), error_ratio), 'fontsize', fontsize)
    end
end

