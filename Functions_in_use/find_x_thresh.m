function x_thresh = find_x_thresh(line_profile_axis, line_profile, figure_handle)
    % prompts the user to click the local minimum and maximum around a 
    % soft-hard tissue interface, and automatically generates the 
    % +/-6dB line to assist manual measurement
    
    plot(figure_handle, line_profile_axis, line_profile(:, 1), 'b-'); hold on;
    set(gcf,'Position',[100 100 1700 1000])
    yticks(0:0.01:1);
    
    factor = 0.5;
    title("click on the left side of interface"); [~, left_y] = ginput(1);
    title("click on the right side of interface"); [~, right_y] = ginput(1);
    
    if left_y > right_y
    y_thresh = left_y - (left_y - right_y)*factor;
    else
    y_thresh = left_y + (right_y - left_y)*factor;
    end
    yline(y_thresh, 'k-');
    [x_thresh, y_thresh] = ginput(1);
    scatter(x_thresh, y_thresh, 'r.'); hold off;
end