load('/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Cropped_image_stacks/Sep_17_20/100mm_504x369.mat');

start = 250;
block_size = 50; 
block1 = mydata_bw(:, :, start : start+block_size);
block2 = mydata_bw(:, :, start+block_size+1 : start+2*block_size+1);

reg_block1 = register_block(block1); 

reg_block2 = register_block(block2);
imshowpair(reg_block1, reg_block2, 'montage')
%%
opt = registration.optimizer.RegularStepGradientDescent;
opt.MaximumIterations = 500;
% imshowpair(reg_block1, imregister(reg_block2, reg_block1, 'rigid', opt, registration.metric.MeanSquares));

[MOVING_REG] = surfRegister(reg_block2, reg_block1);
imshowpair(reg_block1, MOVING_REG.RegisteredImage)