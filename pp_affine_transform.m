function Iout = pp_affine_transform(Iin, M, varargin)
    
    p = inputParser;
    p.addOptional('author', 'p', @(s) ischar(s));
    parse(p, varargin{:});
    opts = p.Results;
    
    author = opts.author;
    
    [h, w] = size(Iin);
    
    if author == 'k'
        [X, Y] = meshgrid(0:h-1, 0:w-1);
        image_center = [h, w]/2;
    else % my implementation
        [X, Y] = meshgrid(0:w-1, 0:h-1);
        image_center = [w, h]/2;
    end
    
    X_demeaned = X - image_center(1);
    Y_demeaned = Y - image_center(2);
    
    % Once we demean, we're rotating relative to the center of the image
    
    Tx = image_center(1) + M(1, 1) * X_demeaned + M(1, 2) * Y_demeaned + M(1, 3) * 1;
    Ty = image_center(2) + M(2, 1) * X_demeaned + M(2, 2) * Y_demeaned + M(2, 3) * 1;
    
    if author == 'k'
        Iout = pp_interpolate_image(Iin, Tx, Ty, author); % This is still incorrect!
    else
        Iout = interp2(X, Y, Iin, Tx, Ty);
    end
end