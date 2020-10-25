% Read JSON file and overlay the annotations on the original image
close all;
root = './DICOM_annotations';
slice_number = 220;
directory = fullfile(root, strcat('slice_', num2str(slice_number)));
CT_slice_location = fullfile(directory, strcat('slice_', num2str(slice_number), '_CT.dcm'));
US_slice_location = fullfile(directory, strcat('slice_', num2str(slice_number), '_US.dcm'));
US_tform_matfile = fullfile(directory, strcat('slice_', num2str(slice_number), '_US_tform.mat'));

num_replicates = 2;
N = 5; % number of datapoints per set of measurement
US_estimates = zeros(N, num_replicates);
CT_estimates = zeros(N, num_replicates);

mode = "Measure"; % "Display or Measure
method = 1; % 1 or 2 (1 is the free-hand measurement, 2 is the -6 dB measurement)

for i = 1:num_replicates
    [CT_meas, pts, profiles, summaries] = load_osirix_meas(directory, strcat('slice_', num2str(slice_number), '_ROI_', num2str(i), '.json'));
    CT_estimates(:, i) = CT_meas;
    
    % Load corresponding dcm slice (taken from Osirix)
    CT_spacing = 0.2; % mm
    CT_info = dicominfo(CT_slice_location);

    CT_slice = dicomread(CT_info);
    R_CT = imref2d(size(CT_slice), CT_spacing, CT_spacing);

    f1 = figure(1);
    figure(f1)
    imshow(CT_slice, R_CT, [min(min(CT_slice)), max(max(CT_slice))]);
    hold on;

    % converts the points into lines and overlay them on the original image
    for j = 1 : N
        cur_pts = pts{j};
        pt1 = str2num(cur_pts{1});
        pt2 = str2num(cur_pts{2});
        [x1, y1] = intrinsicToWorld(R_CT, pt1(1), pt1(2));
        [x2, y2] = intrinsicToWorld(R_CT, pt2(1), pt2(2));
    %     plot([pt1(1), pt2(1)], [pt1(2), pt2(2)], 'o-');
        plot([x1, x2], [y1, y2], 'o-')
    end
    hold off;
    
    % Load ultrasound
    US_spacing = 0.033;
    US_slice_info = dicominfo(US_slice_location);
    US_slice = double(dicomread(US_slice_info));
    US_slice = double(US_slice - min(min(US_slice))) / double(max(max(US_slice)) - min(min(US_slice))); % turns into a decimal
    US_slice_OG = US_slice;
    
    US_slice_tform = load(US_tform_matfile);
    US_slice_tform = US_slice_tform.tform; % need to unpack the struct first
    rot = US_slice_tform.rot;
    trans_x = US_slice_tform.trans_x;
    trans_y = US_slice_tform.trans_y;

    US_slice = imrotate(US_slice, rot, 'nearest', 'loose'); % I should convert rotation/translation into an affine
    R_US = imref2d(size(US_slice), US_spacing, US_spacing);
    [US_slice, R_US] = imtranslate(US_slice, R_US, [trans_x, trans_y], 'OutputView', 'full');

%     Show how well the two match
    [fused, R_fused] = imfuse(CT_slice, R_CT, US_slice, R_US);
    figure(2); 
    imshow(fused, R_fused);

    figure_length = 1700;
    figure_height = 1000;

    f3 = figure(3);
    figure(f3)
    
    if method == 1
        ax3 = axes('Parent', f3);
        imshow(imcomplement(US_slice), R_US, 'Parent', ax3), axis on, hold on
    elseif method == 2
        f3_1 = subplot(2, 1, 1);
        imshow(imcomplement(US_slice), R_US, 'Parent', f3_1), axis on, hold on
    end
    set(gcf,'Position',[100 100 figure_length figure_height])
    xlim([40, 61]);
    ylim([10, 31]);

    % need to extrapolcate the line beyond the two known points
    for j = 1 : N
        cur_pts = pts{j};
        pt1 = str2num(cur_pts{1});
        pt2 = str2num(cur_pts{2});
        [x1, y1] = intrinsicToWorld(R_CT, pt1(1), pt1(2));
        [x2, y2] = intrinsicToWorld(R_CT, pt2(1), pt2(2));
        
        if method == 1
            x_extended = get(ax3, 'XLim');
        elseif method == 2
            x_extended = get(f3_1, 'XLim');
        end
        
        m = (y2 - y1) / (x2 - x1); % slope
        b = y2 - m * x2; % offset
        y_extended = zeros(1, 2);
        y_extended(1) = m * x_extended(1) + b;
        y_extended(2) = m * x_extended(2) + b;
        
        if strcmp(mode, "Display")
            plot([x1, x2], [y1, y2], 'r*', 'Markersize', 12)
            plot(x_extended, y_extended, '-')
        
        elseif strcmp(mode, "Measure")
            
            
            
            if method == 1
% first way
%                 plot(ax3, [x1, x2], [y1, y2], 'r*', 'Markersize', 12)                
                plot(ax3, x_extended, y_extended, '-')
                title("click on the left side of bone"); [left_x_US, left_y_US] = ginput(1);
                title("click on the right side of bone"); [right_x_US, right_y_US] = ginput(1);
                US_estimate = sqrt((right_x_US - left_x_US)^2 + (right_y_US - left_y_US)^2);
                
            elseif method == 2
% second way            
                [line_profile_x, line_profile_y, line_profile] = improfile(R_US.XWorldLimits, R_US.YWorldLimits, US_slice, x_extended, y_extended, 2500);
                line_profile_axis = sqrt((line_profile_x - line_profile_x(1)).^2 + (line_profile_y - line_profile_y(1)).^2);
                f3_2 = subplot(2, 1, 2);
                plot(f3_1, x_extended, y_extended, '-')
                plot(f3_2, line_profile_axis, line_profile); % subtract the first x and y coordinate to make distance correct
                xlabel('Distance (mm)')
                ylabel('Intensity (up to 1)')
                set(gcf,'Position',[100 100 figure_length figure_height])
                left_x_US = find_x_thresh(line_profile_axis, line_profile, f3_2);
                right_x_US = find_x_thresh(line_profile_axis, line_profile, f3_2);
                US_estimate = right_x_US - left_x_US; % this is in mm
            end
            
            
            
            US_estimates(j, i) = US_estimate;
            disp(sprintf('US = %.2f, CT = %.2f, diff = %.2f%%', US_estimate, CT_meas(j), 100 * abs(US_estimate - CT_meas(j))/CT_meas(j))) ;
        end
    end
    hold off;
    pause(1);
    close all;
end
%%
US_estimates = sort(US_estimates, 'ascend');
CT_estimates = sort(CT_estimates, 'ascend');
width_meas_dir = '/Users/preston/MATLAB-Drive/Width_measurements';
cd(width_meas_dir)
save(sprintf('%d_CT_estimates.mat', slice_number), 'CT_estimates');
save(sprintf('%d_US_estimates.mat', slice_number), 'US_estimates');
cd ..

%%
if strcmp(mode, "Measure")
    close all;
    [rpc1, fig1] = BlandAltman(US_estimates(:, 1), CT_estimates(:, 1), {'US', 'CT', 'mm'}, 'Comparison between US and CT (1st set)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});
    [rpc2, fig2] = BlandAltman(US_estimates(:, 2), CT_estimates(:, 2), {'US', 'CT', 'mm'}, 'Comparison between US and CT (2nd set)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});
    [rpc3, fig3] = BlandAltman(US_estimates(:, 1), US_estimates(:, 2), {'US_1', 'US_2', 'mm'}, 'Comparison between 1st and 2nd US (By Preston)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});
    [rpc4, fig4] = BlandAltman(CT_estimates(:, 1), CT_estimates(:, 2), {'CT_1', 'CT_2', 'mm'}, 'Comparison between 1st and 2nd CT (By Preston)', {'Bone width'}, 'baInfo', {'SD' , 'RPC(%)'});
    fig1.Position=[0.0475, 0.0759, 0.6, 0.4];
    fig2.Position=[0.0475, 0.0759, 0.6, 0.4];
    fig3.Position=[0.0475, 0.0759, 0.6, 0.4];
    fig4.Position=[0.0475, 0.0759, 0.6, 0.4];
    
    plot_directory = '/Users/preston/MATLAB-Drive/Bland_Altman_Plots';
    saveas(fig1, fullfile(plot_directory, sprintf('slice_%d_CT_US_1.png', slice_number)));
    saveas(fig2, fullfile(plot_directory, sprintf('slice_%d_CT_US_2.png', slice_number))); 
    saveas(fig3, fullfile(plot_directory, sprintf('slice_%d_US_US.png', slice_number))); 
    saveas(fig4, fullfile(plot_directory, sprintf('slice_%d_CT_CT.png', slice_number))); 
end