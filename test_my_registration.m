M_func = @(theta, tx, ty) [cosd(theta), -sind(theta), tx; sind(theta), cosd(theta), ty; 0, 0, 1];

[X, Y] = meshgrid(0:0.1:30, 0:0.1:60);
x0 = 15;
y0 = 30;
sig_x = 4; % gaussian std in the x direction
sig_y = 1; % gaussian std in the y direction
Z = exp(-((X - x0).^2 / (2*sig_x^2) + (Y - y0).^2/(2*sig_y^2)));

x0 = [0 0 0];
options = optimoptions(@lsqnonlin, 'Algorithm', 'levenberg-marquardt');

M = M_func(0, 10, 10);
moving = pp_affine_transform(Z, M, 'k');
fixed = Z;

x_out = lsqnonlin(@(x) pp_affine_registration(x, moving, fixed), x0, [], [], options);
M_out = M_func(x_out(1), x_out(2), x_out(3)); 
tformed_moving = pp_affine_transform(moving, M_out);
imshowpair(fixed, tformed_moving)

%%
scale = [1 1 1];
x_out = lsqnonlin(@(x) affine_registration_image(x, scale, moving, fixed, 'sd'), x0, [], [], options);
M_out = M_func(x_out(3) * 180/pi, x_out(1), x_out(2))
%%
imshowpair(Z, affine_transform_2d_double(Z, M_func(110, 0, 130), 0));