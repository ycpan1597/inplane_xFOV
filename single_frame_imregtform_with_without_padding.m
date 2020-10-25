% Compare registration with and without padding - single frame

load('/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Cropped_image_stacks/Sep_17_20/95mm_504x369.mat');

%% without padding
cur = mydata_bw(:, :, 63);
next = mydata_bw(:, :, 73);

opt = registration.optimizer.RegularStepGradientDescent;
met = registration.metric.MeanSquares;

tform = imregtform(next, cur, 'rigid', opt, met);

imshowpair(cur, imwarp(next, tform, 'OutputView', imref2d(size(cur))))

%% with padding
pad_size = 15;

cur_padded = padarray(cur, [pad_size pad_size], 0);
next_padded = padarray(next, [pad_size pad_size], 0);
% imshow(cur_padded, [])
tform_padded = imregtform(next_padded, cur_padded, 'rigid', opt, met);

% imshowpair(cur_padded, imwarp(next_padded, tform_padded, 'OutputView', imref2d(size(cur_padded))));
imshowpair(cur_padded, imwarp(next_padded, tform_padded, 'OutputView', affineOutputView(size(next_padded), tform_padded, 'BoundsStyle', 'SameAsInput')))

fprintf('No padding: %.2f deg rotation\n', acosd(tform.T(1, 1)))
fprintf('With padding: %.2f deg rotation\n', acosd(tform_padded.T(1, 1)))

%%
next_next = mydata_bw(:, :, 83);
next_next_padded = padarray(next_next, [pad_size pad_size], 0);
next_tform_padded = imregtform(next_next_padded, next_padded, 'rigid', opt, met);

next_tform = imregtform(next_next, next, 'rigid', opt, met);

%%
result = register_block(padarray(mydata_bw(:, :, 63:2:83), [pad_size pad_size], 0));
imshow(result, [])

% imshowpair(next_padded, imwarp(next_next_padded, next_tform_padded, 'OutputView', affineOutputView(size(next_next_padded), next_tform_padded, 'BoundsStyle', 'SameAsInput')))
% 
% fprintf('No padding: %.2f deg rotation\n', acosd(next_tform.T(1, 1)))
% fprintf('With padding: %.2f deg rotation\n', acosd(next_tform_padded.T(1, 1)))
%%
% imshowpair(cur, imwarp(next_next, affine2d(next_tform.T * tform.T), 'OutputView', imref2d(size(cur))), 'diff')
imshowpair(cur_padded, imwarp(next_next_padded, affine2d(next_tform_padded.T * tform_padded.T), 'OutputView', imref2d(size(cur_padded))), 'diff')