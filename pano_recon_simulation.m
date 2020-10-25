%% Registration simulation
m = 200; n = 200;
h = 80; w = 80;
img = zeros(m, n);

x_offset = 50;
y_offset = -50;
img(int64(m/2) + y_offset - int64(h/2) : int64(m/2) + y_offset + int64(h/2) - 1,...
int64(n/2) + x_offset - int64(w/2) : int64(n/2) + x_offset + int64(w/2) - 1)  = 1;

N = 20;
img_stack = zeros([size(img), N]);
ang_array = linspace(0, 45, N);
TX = rand(N, 1) * 5;
TY = rand(N, 1) * 5;
for i = 1:N
    cur_tform = affine2d([ ...
        cosd(ang_array(i)) sind(ang_array(i)) 0;...
        -sind(ang_array(i)) cosd(ang_array(i)) 0; ...
        TX(i) TY(i) 1]);
%     img_stack(:, :, i) = imwarp(img, cur_tform, 'OutputView', imref2d(size(img))) .* rand(size(img)); % sampling from a gaussian distribution
    img_stack(:, :, i) = imwarp(img, cur_tform, 'OutputView', imref2d(size(img))) .* raylrnd(0.5, size(img, 1), size(img, 2));
end
imshow(img)
%%
pad_sizes = 1;
error_with_pad_size = zeros(size(pad_sizes));
for j = 1:length(pad_sizes)
    img_stack_padded = padarray(img_stack, [pad_sizes(j), pad_sizes(j), 0], 0);
    ref = padarray(img, [pad_sizes(j), pad_sizes(j)], 0);
    combined_img = zeros([size(img_stack_padded, 1), size(img_stack_padded, 2)]);
    combined_errors = zeros(N-1);

    opt = registration.optimizer.RegularStepGradientDescent();
    met = registration.metric.MeanSquares();
    opt.MaximumIterations = 200;

    ref_tform = imregtform(img_stack_padded(:, :, 1), ref, 'rigid', opt, met);
    for i = 1:N-1    
        cur = img_stack_padded(:, :, i);
        next = img_stack_padded(:, :, i+1);
        cur_tform = imregtform(next, cur, 'rigid', opt, met);

        cur_tformed = imwarp(next, cur_tform, 'OutputView', imref2d(size(cur)));
        error = norm(cur - cur_tformed, 'fro') / norm(cur, 'fro')

%         if error > 0.5
%             fprintf('Correcting with affine tform instead of rigid:\n')
%             cur_tform = imregtform(next, cur, 'affine', opt, met);
%             cur_tformed = imwarp(next, cur_tform, 'OutputView', imref2d(size(cur)));
%             norm(cur - cur_tformed, 'fro') / norm(cur, 'fro');
%         end

        subplot(1, 2, 1)
    %     imshowpair(cur, cur_tformed);
        imshow(max(img_stack, [], 3));
        title(sprintf('%d frames in the stack', N));

        if i == 1
            combined_tform = affine2d(cur_tform.T * ref_tform.T);
        else
            combined_tform = affine2d(cur_tform.T * combined_tform.T);
        end

        combined_img = max(combined_img, imwarp(next, combined_tform, 'OutputView', imref2d(size(cur))));

        combined_errors(i) = norm(combined_img - ref, 'fro') / norm(ref, 'fro');
        subplot(1, 2, 2)
        imshow(combined_img);
%         axis([80 230 60 210])
        pause();
    end
    error_with_pad_size(j) = norm(ref - combined_img, 'fro') / norm(ref, 'fro');

    imshowpair(ref, combined_img)
    title(sprintf('Normalized error = %.2f', norm(ref - combined_img, 'fro') / norm(ref, 'fro')))
end

% plot(1:N-1, combined_errors)

%% Maybe we can make the simulation a little more realistic by adding speckle noise