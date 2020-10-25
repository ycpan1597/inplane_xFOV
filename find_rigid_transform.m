function tform = find_rigid_transform(moving_points, fixed_points)
    % expects moving_points to be 2 x N, where N = number of matched points
    moving_centroid = mean(moving_points, 2);
    fixed_centroid = mean(fixed_points, 2);
    
    H = (moving_points - moving_centroid) * (fixed_points - fixed_centroid)';
    [U, S, V] = svd(H);
    R = V*U';
    
    t = fixed_centroid - R * moving_centroid;
    
    tform = [[R t]; [0 0 1]];
    
    % convert to Matlab affine2d
    tform = affine2d(tform');
end
    
    