% please change to correct filepath
moving_file = '/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Scripts/moving.png';
fixed_file = '/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Scripts/fixed.png';

moving = double(imread(moving_file));
fixed = double(imread(fixed_file));
tformed = imregister(moving, fixed, 'rigid', registration.optimizer.RegularStepGradientDescent(), registration.metric.MeanSquares());
fprintf('Normalized error = %.2f\n', norm(tformed - fixed) / norm(fixed));

% Padding with just 1 zero greatly reduces error
padded_moving = padarray(moving, [1, 1], 0);
padded_fixed = padarray(fixed, [1, 1], 0);
padded_tformed = imregister(padded_moving, padded_fixed, 'rigid', registration.optimizer.RegularStepGradientDescent(), registration.metric.MeanSquares());
fprintf('Normalized error = %.2f\n', norm(padded_tformed - padded_fixed) / norm(padded_fixed));

