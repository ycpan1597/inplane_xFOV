d = '/Volumes/GoogleDrive/My Drive/Umich Research/Sequential Registration/Data/Pig 5R/80 mm';
width = 500;
height = 400;
images = process_dcm_images_for_registration(d, width, height);
% [out, attr] = panoramic_reconstruct_v2(d, 'iters', 400);
% imshow(out, [0, 255]);1
%%
demean = false;
cur = images(:, :, 14);
next = images(:, :, 15);

% thresh = 100
% cur(cur > thresh) = 255;
% cur(cur < thresh) = 0;
% 
% next(next > thresh) = 255;
% next(next < thresh) = 0;

% Just an idea I got from looking at some other examples; doesn't actually
% work (sometimes this makes no difference at all!)
if demean
    cur = cur - mean(cur, 'all');
    next = next - mean(next, 'all');
end

metric = registration.metric.MeanSquares();
optimizer = registration.optimizer.RegularStepGradientDescent;
optimizer.MaximumIterations = 200;
transformed = imregister(next, cur, 'rigid', optimizer, metric);

subplot(1, 2, 1);
imshowpair(cur, next);
title(sprintf('MSE = %.3f', sum((next - cur).^2, 'all')/numel(cur)));
subplot(1, 2, 2);
imshowpair(cur, transformed);
title(sprintf('MSE = %.3f', sum((transformed - cur).^2, 'all')/numel(cur)));

imwrite(cur/255, 'cur.png');
imwrite(next/255, 'next.png');
