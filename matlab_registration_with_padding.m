load('/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Cropped_image_stacks/Sep_17_20/98mm_504x369.mat');
%% No padding (failed registration)
opt = registration.optimizer.RegularStepGradientDescent();
met = registration.metric.MeanSquares();

cur = mydata_bw(:, :, 126);
next = mydata_bw(:, :, 127);
tformed = imregister(next, cur, 'rigid', opt, met);
fprintf('Normalized error = %.3f\n', norm(tformed - cur) / norm(cur));

imshowpair(tformed, cur)
%% With padding
pad_size = 100;
padded_cur = padarray(cur, [pad_size + 100, pad_size], 0);
padded_next = padarray(next, [pad_size + 100, pad_size], 0);
padded_tform = imregtform(padded_next, padded_cur, 'rigid', opt, met);

warpped = imwarp(padded_next, padded_tform, 'OutputView', imref2d(size(padded_cur)));
subplot(1, 2, 1)
imshowpair(warpped, padded_cur);
title(sprintf('Normalized error = %.3f\n', norm(warpped - padded_cur) / norm(padded_cur)));

warpped = imwarp(next, padded_tform, 'OutputView', imref2d(size(cur)));
subplot(1, 2, 2)
imshowpair(warpped, cur)
title(sprintf('Normalized error = %.3f\n', norm(warpped - cur) / norm(cur)));
