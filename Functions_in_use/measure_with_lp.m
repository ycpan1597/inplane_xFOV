function [cur_coord] = measure_with_lp(img, dx, dy, varargin)
    defaultLineWidth = 1;
    defaultMyTitle = 'Title';
    defaultPrevCoord = [0 0; 0 0];
    defaultNumPoints = 100;
    colors = {'red', 'green', 'blue', 'cyan', 'magenta', 'white', 'black'}; % all colors
    
    p = inputParser;
    valid2DInput = @(x) (ndims(x) == 2 || ndims(x) == 3) && size(x, 1) > 1 && size(x, 2) > 1; % must be an image
    
    p.addRequired('img', valid2DInput);
    p.addRequired('dx');
    p.addRequired('dy');
    p.addOptional('prev_coord', defaultPrevCoord);
    p.addParameter('num_points', defaultNumPoints);
    p.addParameter('lw', defaultLineWidth);
    p.addParameter('my_title', defaultMyTitle);
    
    parse(p, img, dx, dy, varargin{:});
    opt = p.Results; % This is a struct containing all of the optional parameters
    prev_coord = opt.prev_coord;
    lw = opt.lw;
    my_title = opt.my_title;
    num_points = opt.num_points;
%     fprintf('prev_coord = %d\n', opt.prev_coord);
%     
% 
    f = figure();
    figure(f);
    set(f, 'Position', [100, 100, 1000, 800])
    set(0,'DefaultTextInterpreter','none')
    
    sp1 = subplot(2, 1, 1);
    imshow(img, [], 'Parent', sp1), hold on
    axis on
    title(my_title);
    sp2 = subplot(2, 1, 2); hold on
    xlabel('Distance (mm)')
    ylabel('Intensity');
    
    key = 0;
    cur_coord = [];
    j = 1;
    color_index = 1;
    
    if any(prev_coord(:))
        for i = 1:size(prev_coord, 3)
            
            if color_index > length(colors)
                color_index = color_indx - length(colors);
            end
            
            line_pos = prev_coord(:, :, i);
            drawline(sp1, 'Position', line_pos, 'Color', colors{color_index});
            [cx, cy, c] = improfile(img, [line_pos(1, 1), line_pos(2, 1)], [line_pos(1, 2), line_pos(2, 2)], num_points);
            plot_profile(cx, cy, normalize_intensity(mean(c, 3)), dx, dy, sp2, lw, colors{color_index}); hold on
            color_index = color_index + 1;
        end
    else
        while key ~= 27
    %         [p1, p2] = ginput(2);
    %         fprintf('X: %.2f~%.2f, Y: %.2f~%.2f', p1(1), p1(2), p2(1), p2(2));
    %         plot(p1, p2, '-', 'Parent', sp1, 'LineWidth', opt.lw)
            if color_index > length(colors)
                color_index = color_indx - length(colors);
            end
            
            line = drawline(sp1, 'Color', colors{color_index});
            pause() % allows you to adjust the line
            line_pos = line.Position;
            cur_coord(:, :, j) = line_pos;
            j = j + 1;

    %         [cx, cy, c] = improfile(img, [p1(1), p1(2)], [p2(1), p2(2)]); 
            [cx, cy, c] = improfile(img, [line_pos(1, 1), line_pos(2, 1)], [line_pos(1, 2), line_pos(2, 2)], num_points);
            plot_profile(cx, cy, normalize_intensity(mean(c, 3)), dx, dy, sp2, lw, colors{color_index}); hold on
            set(findall(f,'-property','FontSize'),'FontSize',15)
            color_index = color_index + 1;
            key = getkeywait(); % press esc to escape
        end
    end
    
end