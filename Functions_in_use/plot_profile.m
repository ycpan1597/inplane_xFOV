function plot_profile(cx, cy, c, dx, dy, axis_handle, linewidth, my_color)
    cx = sort(cx);
    cy = sort(cy);
    cx_centered = cx - min(cx);
    cy_centered = cy - min(cy);
    dist_axis = sqrt((cx_centered * dx).^2 + (cy_centered * dy).^2);
    plot(dist_axis, c, '-o', 'Color', my_color, 'Parent', axis_handle, 'LineWidth', linewidth);
%     dist_axis(1) % for debugging
end