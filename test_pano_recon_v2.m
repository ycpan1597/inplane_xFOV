clear all; close all; clc

start = 300;
step = 1;
last = 400; % -1 uses the length of the stack

iters = 200;
min_step_length = 1e-4;
max_step_length = 6.25e-2; % default = 6.25e-2
show_plot = false;
rm_offset = false; % doesn't seem to help that much
useful_pixel_threshold = 0; % max = 100(%) -> uses nothing; min = 0 => uses everything
disp_opt = false;
method = 'surf'; % mean_squares or SURF

savefiles = false;

image_dir = '/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Cropped_image_stacks';

[current_file, sub_dir] = uigetfile(strcat(image_dir, '/*.mat'), 'MultiSelect', 'On');
pathparts = strsplit(sub_dir, '/');
exp_date = pathparts(end - 1);
exp_date = exp_date{1}; % text is wrapped in curly braces
fprintf('Experiment was done on %s; please correct file path if incorrect\n', exp_date);
if isa(current_file, 'char')
    current_file = {current_file};
end

save_to = fullfile('/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Recon_results', exp_date); 

% If we wanted to save files, check if any file already exists to avoid overwriting
if savefiles
    for i = 1:length(current_file)
        filename = fullfile(save_to, sprintf('%s_%diters_%s', erase(current_file{i}, '.mat'), iters, method));
        filename = strcat(filename, '.png');
        if exist(filename, 'file')
            fprintf("The file %s already exists; change filename or overwrite\n", filename);
        end
    end
else
    disp('Not saving the reconstructions');
end

%% Enables user to reconstruct multiple files sequentially; results can be saved using "savefiles"

for i = 1:length(current_file)
    [recon, attr] = panoramic_reconstruct_v2(fullfile(sub_dir, current_file{i}),...
                                          'start_frame', start,...
                                          'frame_step', step,...
                                          'end_frame', last,...
                                          'pad_size', 0,...
                                          'iters', iters,...
                                          'min_step_length', min_step_length,...
                                          'max_step_length', max_step_length,...
                                          'show_plot', false,...
                                          'rm_offset', rm_offset,...
                                          'useful_pixel_threshold', useful_pixel_threshold,...
                                          'disp_opt', disp_opt,...
                                          'method', method);

    recon = uint8(recon);
    clean_filename = erase(current_file{i}, '.mat');
    
    close all;
    f1 = figure(1);
    imshow(recon, [0, 255]);
    f1.Position = [542, 546, 800, 1000];
    last_for_saving = last;
    if last == -1
        last_for_saving = attr.l;
    end
    title(sprintf(['%s, %.2fs\n',...
                  'Frame=%d:%d:%d (size=%dx%d)\n',...
                  'iters=%d, min-step-length=%.5f, max-step-length=%.5f\n',...
                  'skip-threshold=%.2f%% (%d/%d frames), %d frames corrected with one-plus-one'],...
                  clean_filename, attr.time, start, step, last_for_saving, attr.h, attr.w, iters, min_step_length, max_step_length, useful_pixel_threshold, attr.skipped, length(start:step:last), attr.num_corrections));

%     f2 = figure(2);
%     plot(start: step: last_for_saving-step, attr.angs, 'b.-')
%     xlabel('Frames')
%     ylabel('Accumulated rotation relative to first frame (deg)')
    


    filename = fullfile(save_to, sprintf('%s_%diters_%s', clean_filename, iters, method));
    if savefiles
        if ~exist(save_to, 'dir')
            mkdir(save_to);
        else
            disp('Directory already exists, check if window size is the same to avoid overwriting')
            ls(save_to);
        end 
        saveas(f1, strcat(filename, '.png'));
        dicomwrite(recon, strcat(filename, '.dcm'));
    end
    set(findall(gcf,'-property','FontSize'),'FontSize',20)
    
%     figure()
%     subplot(1, 2, 1)
%     plot(attr.x_error); hold on;
%     plot(attr.y_error); hold off;
%     legend(sprintf('x error, avg = %.2f', mean(attr.x_error)), sprintf('y error, avg = %.2f', mean(attr.y_error)))
%     xlabel(sprintf('Frame (%d~%d)', start, last));
%     ylabel('Normalized error in x and y');
%     % set(findall(gcf,'-property','FontSize'),'FontSize',16)
% 
%     subplot(1, 2, 2)
%     scatter(attr.num_points, attr.x_error); hold on;
%     scatter(attr.num_points, attr.y_error); hold off;
%     legend('x error', 'y error')
%     xlabel('Number of matched points');
%     ylabel('Normalized error in x and y');
%     set(findall(gcf,'-property','FontSize'),'FontSize',16)
%     set(gcf, 'Position', [100, 300, 1500, 500])
%     
%     title(current_file{i})
end
% figure()
% plot(attr.differences); hold on
% xlabel('Frame number');
% ylabel('Normalized difference between frames');
% yline(mean(attr.differences))
% set(findall(gcf,'-property','FontSize'),'FontSize',16); hold off



%%
clf
angs = [];
for i=1:numel(attr.all_xforms) - 1
    cur = attr.all_xforms{i};
    [~, ~, ang] = convert_tform_to_vector(cur, 1);
%     plot(cur(3, 1), cur(3, 2), 'r.-'); hold on
    angs = [angs ang];
end
hold off
plot(start: step: last_for_saving-step, angs)
