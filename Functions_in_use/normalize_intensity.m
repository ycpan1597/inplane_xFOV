function x = normalize_intensity(x) % the exact same as rescale.. should have checked!
    if ndims(x) <= 2
        % 1D or 2D
        x = (x - min(x, [], 'all')) / (max(x, [], 'all') - min(x, [], 'all'));
    else
        msg = 'Input must be a 1D or 2D array';
        error(msg);
    end
end