% Goal is to turn the modified_panoramic_withcheckpoint.m into a function
% and call it multiple times. 
function [previous_image, attr] = panoramic_reconstruct_v2(file_path, varargin)
                                
    p = inputParser;
    p.addParameter('has_checkpoint', false);
    p.addParameter('start_frame', 1);
    p.addParameter('frame_step', 1);
    p.addParameter('end_frame', -1);
    p.addParameter('pad_size', 0);
    p.addParameter('iters', 200);
    p.addParameter('min_step_length', 1e-4);
    p.addParameter('max_step_length', 6.25e-2);
    p.addParameter('show_plot', false);
    p.addParameter('rm_offset', true);
    p.addParameter('show_fused_image', false);
    p.addParameter('err_ratio_threshold', 6);
    p.addParameter('useful_pixel_threshold', 0);    % max = 255 -> uses nothing; min = 0 => uses everything
    p.addParameter('disp_opt', false);              % displays optimization info
    p.addParameter('method', "mean_squares")        % uses mean_squares as the cost function
    
    parse(p, varargin{:});
    opts = p.Results;
    
    has_checkpoint = opts.has_checkpoint;
    start_frame = opts.start_frame;
    frame_step = opts.frame_step;
    end_frame = opts.end_frame;
    pad_size = opts.pad_size;
    iters = opts.iters;
    min_step_length = opts.min_step_length;
    max_step_length = opts.max_step_length;
    show_plot = opts.show_plot;
    rm_offset = opts.rm_offset;
    show_fused_image = opts.show_fused_image;
    err_ratio_threshold = opts.err_ratio_threshold;
    useful_pixel_threshold = opts.useful_pixel_threshold;
    disp_opt = opts.disp_opt;
    method = opts.method;
                                
    transformation_type = 'rigid';                           
    
    attr = struct();
    file = load(file_path);
    mydata_bw = file.mydata_bw;
    mydata_bw = padarray(mydata_bw, [pad_size, pad_size, 0], 0);
    min_intensity = min(min(min(mydata_bw)));
    max_intensity = max(max(max(mydata_bw)));
    
    display_range = [min_intensity max_intensity];
    
    if end_frame == -1
        end_frame = size(mydata_bw, 3);
    end
    
    block_size = 10;
    frames_to_read = start_frame:block_size:end_frame;
    
%     all_frames_to_read = start_frame: frame_step: length(mydata_bw);
    
    all_xforms = cell(numel(frames_to_read), 1); % stores all transformation matrices
    
%     ref = padarray(squeeze(mydata_bw(:, :, 1)), [pad_size, pad_size], 0); % choose any frame; just for the size
    ref = mydata_bw(:, :, frames_to_read(1));
    
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

% %     metric = registration.metric.MeanSquares;
    metric = registration.metric.MattesMutualInformation; % doesn't work as well
    
%     RegularStepGradientDescent parameters
    optimizer = registration.optimizer.RegularStepGradientDescent();
    optimizer.MaximumIterations = iters;
    optimizer.MinimumStepLength = min_step_length;
    optimizer.MaximumStepLength = max_step_length;
    
%     This optimizer doesn't give good cumulative results, but we can use 
%     it for correction of specific pairs
%     optimizer = registration.optimizer.OnePlusOneEvolutionary();
%     optimizer.MaximumIterations = iters;
    
    if show_plot
        figure();
    end
    
    err_ratios = [];
    angs = [];
    directions = {};
    skipped = 0;
    data_to_register = mydata_bw;
    num_corrections = 0;
    differences = zeros(length(frames_to_read) - 1, 1);
%     previous_image = double(zeros([size(data_to_register, 1), size(data_to_register, 2)]));
    attr.x_error = [];
    attr.y_error = [];
    attr.num_points = [];
    
    % we'll be dividing the total image set into chucks that are block_size
    % large
    tic
    for i = 1:length(frames_to_read) - 2
        
        fprintf('block1 from %d to %d\n', frames_to_read(i), frames_to_read(i+1) - 1);
        fprintf('block2 from %d to %d\n', frames_to_read(i+1), frames_to_read(i+2) - 1);
        block1 = data_to_register(:, :, frames_to_read(i):frames_to_read(i+1) - 1);
        block2 = data_to_register(:, :, frames_to_read(i+1):frames_to_read(i+2) - 1);
        
        if i == 1
        % within the block, we want to do several registrations
            registered_block1 = register_block(block1); % a larger image than the one before
            registered_block2 = register_block(block2);
        else
            registered_block1 = registered_block2; % this way we reduce unnecessary repeats
            registered_block2 = register_block(block2);
        end
               
        
        current = registered_block1;
        next = registered_block2;
        
%         current = medfilt2(current, [3, 3]);
%         next = medfilt2(next, [3, 3]);

%         current = padarray(imfilter(current, fspecial('gaussian')), [pad_size, pad_size], 0);
%         next = padarray(imfilter(next, fspecial('gaussian')), [pad_size, pad_size], 0);
        
        % compute the amount of useful information in the next frame; don't
        % use the frame if below a threshold
        next_percent = find_percent_of_useful_pixels(next);
        if next_percent < useful_pixel_threshold
            disp('Skipped')
            skipped = skipped + 1;
            continue
        end
        
        if strcmp(lower(method), 'surf')
        
            FIXED = data_to_register(:, :, frames_to_read(i+1) - 1);
            MOVING = data_to_register(:, :, frames_to_read(i+1));

            % Get linear indices to finite valued data
            finiteIdx = isfinite(FIXED(:));

            % Replace NaN values with 0
            FIXED(isnan(FIXED)) = 0;

            % Replace Inf values with 1
            FIXED(FIXED==Inf) = 1;

            % Replace -Inf values with 0
            FIXED(FIXED==-Inf) = 0;

            % Normalize input data to range in [0,1].
            FIXEDmin = min(FIXED(:));
            FIXEDmax = max(FIXED(:));
            if isequal(FIXEDmax,FIXEDmin)
                FIXED = 0*FIXED;
            else
                FIXED(finiteIdx) = (FIXED(finiteIdx) - FIXEDmin) ./ (FIXEDmax - FIXEDmin);
            end

            % Normalize MOVING image

            % Get linear indices to finite valued data
            finiteIdx = isfinite(MOVING(:));

            % Replace NaN values with 0
            MOVING(isnan(MOVING)) = 0;

            % Replace Inf values with 1
            MOVING(MOVING==Inf) = 1;

            % Replace -Inf values with 0
            MOVING(MOVING==-Inf) = 0;

            % Normalize input data to range in [0,1].
            MOVINGmin = min(MOVING(:));
            MOVINGmax = max(MOVING(:));
            if isequal(MOVINGmax,MOVINGmin)
                MOVING = 0*MOVING;
            else
                MOVING(finiteIdx) = (MOVING(finiteIdx) - MOVINGmin) ./ (MOVINGmax - MOVINGmin);
            end

            % Default spatial referencing objects
            fixedRefObj = imref2d(size(FIXED));
            movingRefObj = imref2d(size(MOVING));

            % Detect SURF features
            fixedPoints = detectSURFFeatures(FIXED,'MetricThreshold',750.000000,'NumOctaves',3,'NumScaleLevels',5);
            movingPoints = detectSURFFeatures(MOVING,'MetricThreshold',750.000000,'NumOctaves',3,'NumScaleLevels',5);

            % Extract features
            [fixedFeatures,fixedValidPoints] = extractFeatures(FIXED,fixedPoints,'Upright',false);
            [movingFeatures,movingValidPoints] = extractFeatures(MOVING,movingPoints,'Upright',false);

            % Match features
            indexPairs = matchFeatures(fixedFeatures,movingFeatures,'MatchThreshold',80.000000,'MaxRatio',0.500000);
            fixedMatchedPoints = fixedValidPoints(indexPairs(:,1));
            movingMatchedPoints = movingValidPoints(indexPairs(:,2));
            MOVINGREG.FixedMatchedFeatures = fixedMatchedPoints;
            MOVINGREG.MovingMatchedFeatures = movingMatchedPoints;

            % Apply transformation - Results may not be identical between runs because of the randomized nature of the algorithm
            tformReg = estimateGeometricTransform(movingMatchedPoints,fixedMatchedPoints,'affine');
            
%             tformReg = find_rigid_transform(movingMatchedPoints.Location', fixedMatchedPoints.Location');
            
            [tformed_x, tformed_y] = transformPointsForward(tformReg, movingMatchedPoints.Location(:, 1), movingMatchedPoints.Location(:, 2));
            x_error = norm(fixedMatchedPoints.Location(:, 1) - tformed_x) / norm(fixedMatchedPoints.Location(:, 1));
            y_error = norm(fixedMatchedPoints.Location(:, 2) - tformed_y) / norm(fixedMatchedPoints.Location(:, 2));
            
            attr.x_error = [attr.x_error, x_error];
            attr.y_error = [attr.y_error, y_error];
            attr.num_points = [attr.num_points, size(fixedMatchedPoints.Location, 1)];

    %         MOVINGREG.Transformation = tform;
    %         MOVINGREG.RegisteredImage = imwarp(MOVING, movingRefObj, tform, 'OutputView', fixedRefObj, 'SmoothEdges', true);
    % 
    %         % Store spatial referencing object
    %         MOVINGREG.SpatialRefObj = fixedRefObj;



        elseif strcmp(lower(method), 'mean_squares')
            if rm_offset
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

        %         Coarse alignment
                init_Tform = affine2d();
                init_Tform.T(3,1:2) = [round(translation_x, 3), round(translation_y, 3)]; % purposely round (introduce error) to avoid getting a singular matrix
                tformReg = imregtform(next, current, transformation_type, optimizer, metric, 'InitialTransformation', init_Tform, 'DisplayOptimization', disp_opt); % somehow this causes the error to diverge in some rare cases?
            else
                tformReg = imregtform(next, current, transformation_type, optimizer, metric, 'DisplayOptimization', disp_opt);
            end
        end

        difference = norm(current - imwarp(next, tformReg, 'OutputView', all_RAs)) / norm(current);

%         if difference > 0.5
%             warning('Rigid registration unsuccessful; trying affine instead');
%              tformReg = imregtform(next, current, 'affine', optimizer, metric, 'DisplayOptimization', disp_opt);
%              difference = norm(current - imwarp(next, tformReg, 'OutputView', all_RAs)) / norm(current);
%              if difference > 0.5 % still no luck
%                  error('Bad registration')
%              end
%         end

        differences(i) = difference;
        tformReg_cur = tformReg; 
            
        all_xforms{i} = tformReg; % stores each transformation matrix; .T is NOT the transpose; it's the transformation matrix itself (as opposed to the class)
        
        if show_plot
            subplot(2,2,1); imshow(current, all_RAs, 'DisplayRange', display_range);
            title(sprintf('frame %d',frames_to_read(i)));

            subplot(2,2,2); imshow(next, all_RAs, 'DisplayRange', display_range);
            title(sprintf('frame %d',frames_to_read(i+1)));

            subplot(2,2,3);
        end
        
        if i == 1
            
            previous_image = imwarp(next, tformReg, 'FillValues', 0, 'OutputView', overscan_RAs);
%             previous_image = imwarp(next, tformReg, 'FillValues', 0, 'OutputView', all_RAs);
            current_combined_tform = tformReg.T;
            if show_plot
                imshow(previous_image, overscan_RAs, 'DisplayRange', display_range);
            end
        else
%             err_ratio = find_registration_error(show_fused_image, current, next, tformReg);
%             if err_ratio > err_ratio_threshold
%                 disp('Error ratio exceeded threshold; excluding it from reconstruction');
%                 cont = input('Continue? (Y/N) ', 's');
%                 if cont == 'N'
%                     attributes.err_ratios = err_ratios;
%                     return;
%                 end
%             end

            old_current_combined_tform = current_combined_tform;
            current_combined_tform = tformReg.T*current_combined_tform; %this step is important; combines all the transform together so that the next frame can be placed at the right position and orientation
            tformReg.T = current_combined_tform;
            
            % We use a diferent optimizer here to correct for any
            % registration that looked wrong
            if i > 2 && abs(ang - angs(end)) > 4 % if the angle difference is greater than some threshold degrees
                num_corrections = num_corrections + 1;
                correction_optimizer = registration.optimizer.OnePlusOneEvolutionary();
                correction_optimizer.MaximumIterations = 200;
                correction_metric = registration.metric.MeanSquares();
                try
                    if rm_offset
                        tformReg_corrected = imregtform(next, current, transformation_type, correction_optimizer, correction_metric, 'InitialTransformation', init_Tform, 'DisplayOptimization', disp_opt); % somehow this causes the error to diverge in some rare cases?
                    else
                        tformReg_corrected = imregtform(next, current, transformation_type, correction_optimizer, correction_metric, 'DisplayOptimization', disp_opt);
                    end
                    all_xforms{i} = tformReg_corrected;
                    current_combined_tform = tformReg_corrected.T*old_current_combined_tform;
                    tformReg.T = current_combined_tform;
                catch
                    elapsed_time = toc();
                    fprintf('Registration failed between frame %d and frame %d; returning early', frames_to_read(i), frames_to_read(i+1));
                    break;
                end
                
            end
        end
            
            
            
        [transformed, ~] = imwarp(next, tformReg, 'FillValues', 0, 'OutputView', overscan_RAs);
%         [transformed, ~] = imwarp(next, tformReg, 'FillValues', 0, 'OutputView', all_RAs);

        previous_image = max(previous_image, transformed); %this step accumulates all images

        if show_plot
            imshow(previous_image, overscan_RAs, 'DisplayRange', display_range); hold on
            title(sprintf('%.2f%% done', (i + 1) * 100/length(frames_to_read)));
        end
%             quiver(x_center, y_center, dx, dy, 'r', 'Linewidth', 3);
        xlim([over_scan_xMinWorldLimit, over_scan_xMaxWorldLimit]);
        ylim([over_scan_yMinWorldLimit, over_scan_yMaxWorldLimit]);

%             disp(sprintf('%.2f%% done, error ratio between frames: %.4f', (i + 1) * 100/length(frames_to_read), err_ratio))
        fprintf('%.2f%% done\n', (i + 1) * 100/length(frames_to_read));
%             err_ratios = [err_ratios, err_ratio];

        if show_plot
            subplot(2,2,4);
            ylabel('%');
            title('Percentage of pixels over the threshold');
        end
%             
%             quiver(previous_dx, previous_dy, 'r', 'Linewidth', 2);
%             set(gca, 'YDir', 'reverse');
        
        [~, ~, ang] = convert_tform_to_vector(tformReg, 1);
        angs = [angs, ang];
        [~, ~, cur_ang] = convert_tform_to_vector(tformReg_cur, 1);
%         if cur_ang > 10
%             fprintf('i = %d, i+1 = %d\n', i, i+1);
%             registrationEstimator(next, current);
%             
%             break;
%         end
        
        if show_plot
            drawnow;
        end
        
    end
    elapsed_time = toc();
%     attributes.directions = directions;
    attr.h = file.h;
    attr.w = file.w;
    attr.l = file.l;
    attr.err_ratios = err_ratios;
    attr.all_xforms = all_xforms;
    attr.angs = angs;
    attr.skipped = skipped;
    attr.num_corrections = num_corrections;
    attr.differences = differences;
    attr.time = elapsed_time;
    fprintf('Took %.2fs; corrected %d frames with a different optimizer\n', elapsed_time, num_corrections)
end
