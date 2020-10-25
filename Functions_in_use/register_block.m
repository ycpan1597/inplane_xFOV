function registered_block = register_block(block)
    registered_block = block(:, :, 1);  
    for i = 1:size(block, 3) - 1
        cur = block(:, :, i); 
        next = block(:, :, i + 1);
        tform = imregtform(next, cur, 'rigid', registration.optimizer.RegularStepGradientDescent, registration.metric.MeanSquares);
        
        if norm(imwarp(next, tform, 'OutputView', imref2d(size(cur))) - cur, 'fro') / norm(cur, 'fro') > 0.5
            tform = imregtform(next, cur, 'affine', registration.optimizer.RegularStepGradientDescent, registration.metric.MeanSquares);
            if norm(imwarp(next, tform, 'OutputView', imref2d(size(cur))) - cur, 'fro') / norm(cur, 'fro') > 0.5
                error('failed')
            end
        end
        
        if i == 1
            cum_tform = tform;
        else
            cum_tform = affine2d(tform.T * cum_tform.T);
        end
        registered_block = max(registered_block, imwarp(next, cum_tform, 'OutputView', imref2d(size(cur))));
    end
        
end

