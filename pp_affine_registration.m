function I_diff = pp_affine_registration(x, moving, fixed)
    theta = x(1); tx = x(2); ty = x(3);
    
    M = [cosd(theta), -sind(theta), tx;
        sind(theta), cosd(theta), ty;
        0 0 1];
    
    moving_tform = pp_affine_transform(moving, M, 'k');
    I_diff = pp_image_difference(moving_tform, fixed);
end