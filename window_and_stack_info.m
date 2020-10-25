close all;
[file, path] = uigetfile('/Users/preston/MATLAB-Drive/Cropped_image_stacks/*.mat', 'MultiSelect', 'on');

if isa(file, 'char')
    file = {file};
end

fig = figure(1);
for i = 1:length(file)
    load(fullfile(path, file{i}));
    fprintf('h = %d, w = %d\n', h, w);
    arr = zeros(size(mydata_bw, 3), 1); % image file here is uint8
    for j = 1:size(mydata_bw, 3)
        image = mydata_bw(:, :, j);
%         arr(j) = 100 * sum(sum(mydata_bw(:, :, j) > 5)) / (h * w);
        arr(j) = find_percent_of_useful_pixels(image);
    end
    plot(arr, 'LineWidth', 3); hold on
end
hold off;
legend(file, 'Interpreter','none');
xlabel('Frame number')
ylabel('Percent of non-zero pixels')
set(findall(gcf,'-property','FontSize'),'FontSize',18)
% title(sprintf('%s\n%% of non-zero pixels each frame', file), 'fontsize', 15)

% saveas(fig, fullfile('/Users/preston/Desktop', sprintf('%dmm_nonzero_percentage.png', slice)))