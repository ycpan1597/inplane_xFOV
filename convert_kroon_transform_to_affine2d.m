next = double(imread('/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Scripts/moving.png')); 
cur = double(imread('/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Scripts/fixed.png'));

x0 = [0 0 0];
scale = [1 1 1];
[x] = lsqnonlin(@(x)affine_registration_image(x,scale, next, cur,type), x0);
M=make_transformation_matrix(x(1:2),x(3));

kroon_transformed = affine_transform(next, M, 3);
matlab_transformed = imwarp(next, affine2d(inv(M)'), 'OutputView', imref2d(size(cur)));

fprintf('Error before registration: %.3f\n', norm(cur - next) / norm(cur));
fprintf('Error after kroon: %.3f\n', norm(cur - affine_transform(cur, M, 3)) / norm(cur));
subplot(2, 1, 1)
imshowpair(cur, kroon_transformed)
subplot(2, 1, 2)
imshowpair(cur, matlab_transformed)
