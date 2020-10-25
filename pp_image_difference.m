function error = pp_image_difference(moving_tformed, fixed)
    moving_tformed(isnan(moving_tformed)) = 0;
    fixed(isnan(fixed)) = 0;
    error = sum((moving_tformed(:) - fixed(:)).^2) / numel(fixed);
end