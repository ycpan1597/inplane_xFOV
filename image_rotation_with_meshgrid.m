spacing = 1;
[X, Y] = meshgrid(-20:spacing:20);
x0 = 3;
y0 = 5;
sig_x = 4; % gaussian std in the x direction
sig_y = 1; % gaussian std in the y direction
Z = exp(-((X - x0).^2 / (2*sig_x^2) + (Y - y0).^2/(2*sig_y^2)));
Z = Z + exp(-((X + 9).^2 / (2*3^2) + (Y + 2).^2/(2*7^2))); % just to make the shape more interesting
theta = 45;

subplot(3, 2, 1)
% contour(X, Y, Z);
imagesc(Z);
colorbar;
daspect([1 1 1])
title('Original image')

matlab_rotated = imrotate(Z, theta, 'crop');
subplot(3, 2, 2)
imagesc(matlab_rotated);
daspect([1 1 1])
title(sprintf('Rotated by %.2f using Matlab', theta))

% rotate the meshgrid (i.e. the coordinates)
R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];

XY = [X(:)'; Y(:)']; % row1 = x, row2 = y
rotXY = R*XY; % rotated coordinates

Xq = reshape(rotXY(1, :), size(X, 1), []);
Yq = reshape(rotXY(2, :), size(Y, 1), []);
Z_rotated_forward = griddata(X, Y, Z, Xq, Yq); % Rotation is simply the interpretation of our image function using a rotated coordinate system!

subplot(3, 2, 3)
imagesc(Z_rotated_forward);
daspect([1 1 1])
title(sprintf('Rotated by %.2f with\nforward transformation', theta))

% Here is the opposite approach
% - Start with the transformed lattice (T(x))
% - For each pixel in this transformed lattice, we want to look for the
%   corresponding value back in the original image
[X_transformed, Y_transformed] = meshgrid(-20:spacing:20);
XY_transformed = [X_transformed(:)'; Y_transformed(:)'];
original_XY = R\XY_transformed; % invert the transformed coordinates back to original
original_X = reshape(original_XY(1, :), size(X_transformed, 1), []);
original_Y = reshape(original_XY(2, :), size(Y_transformed, 1), []);
Z_rotated_backward = griddata(original_X, original_Y, Z, X_transformed, Y_transformed);

subplot(3, 2, 4)
imagesc(Z_rotated_backward);
daspect([1 1 1])
title(sprintf('Rotated by %.2f with\nbackward/inverse transformation', theta))

subplot(3, 2, 5)
imagesc(Z_rotated_forward - matlab_rotated)
title('Forward - matlab')
colorbar;
daspect([1 1 1])

subplot(3, 2, 6)
imagesc(Z_rotated_backward - matlab_rotated)
title('backward - matlab')
colorbar;
daspect([1 1 1])

set(findall(gcf,'-property','FontSize'),'FontSize',15)

% numpy
% scipy
% cv2
% matplotlib
% pytorch
% eta - how to do practical pipelining
% fiftyone


