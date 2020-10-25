% acosd goes from 0 to 180; asind goes from -90 to 0
function [dx, dy, theta] = convert_tform_to_vector(tform, scaling_factor)
    theta_from_cos = acosd(tform.T(1, 1));
    theta_from_sin = asind(tform.T(1, 2));
    
    % The following section guarantees that the arrows point in the right
    % direction, but gives the angle from -90 to 90
%     if theta_from_cos > 0 && theta_from_cos < 90 && theta_from_sin > 0 && theta_from_sin < 90
%         theta = theta_from_cos;
%     elseif theta_from_cos > 90 && theta_from_sin > 0 && theta_from_sin < 90
%         theta = theta_from_cos - 180;
%     elseif theta_from_sin < 0 && theta_from_cos > 90
%         theta = theta_from_cos - 90;
%     else
%         theta = theta_from_sin;
%     end
    theta = theta_from_cos;

    old_dx = 1;
    old_dy = tand(theta);
    
    dx = old_dx * scaling_factor/(sqrt(old_dx^2 + old_dy^2)); 
    dy = old_dy * scaling_factor/(sqrt(old_dx^2 + old_dy^2));
end