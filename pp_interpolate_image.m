% I want to write my own rigid registration! This is based on Kroons.

% Rigid registration has 3 degrees of freedom (rotation, translation in x
% and translation in y). For simplicity, we will use the following
% parameters

% Difference metric: mean squares
% Interpolation method: bilinear

% General flow: 

% Take images FIXED and MOVING as inputs, and initial guess x0 (where x0 is a 3x1 vector)
% for i = 1:iterations
%     apply the current guess (x) to the moving image with interpolation
%     calculate the difference between the transformed/interpolated image and the FIXED image
%     use the difference to direct the search for better x in the next iteration


function Iout = pp_interpolate_image(Iin, Tx, Ty, varargin)
    
    p = inputParser;
    p.addOptional('author', 'p', @(s) ischar(s));
    parse(p, varargin{:});
    opts = p.Results;
    
    author = opts.author;
% interpolate_image  Interpolates an image using bilinear method
    % Tx and Ty here are already transformed, so they won't be integers. We
    % must find the corresponding integer pixels
    
    Xi = floor(Tx);
    Yi = floor(Ty);
    Xf = Xi + 1;
    Yf = Yi + 1;
    
    Dx = Tx - Xi;
    Dy = Ty - Yi;
    
    
    % Kroon's implementation:
    if author == 'k'
        Xi = min(max(Xi, 0), size(Iin, 1) - 1);
        Yi = min(max(Yi, 0), size(Iin, 2) - 1);
        Xf = min(max(Xf, 0), size(Iin, 1) - 1);
        Yf = min(max(Yf, 0), size(Iin, 2) - 1);

        intensity0 = Iin(1 + Xi + Yi * size(Iin, 1)); % upper left
        intensity1 = Iin(1 + Xi + Yf * size(Iin, 1)); % upper right
        intensity2 = Iin(1 + Xf + Yi * size(Iin, 1));% lower left
        intensity3 = Iin(1 + Xf + Yf * size(Iin, 1));% lower right

        perc0 = (1-Dx) .* (1-Dy); % lower right
        perc1 = Dy .* (1-Dx); % upper right
        perc2 = Dx .* (1-Dy); % lower left
        perc3 = Dx .* Dy; % upper left
        
        Iout = intensity0 .* perc0 + intensity1 .* perc1 + intensity2 .* perc2 + intensity3 .* perc3; 
    
    else 
    % My implementation: 
    
        % Limit the index to within the bounds of the image (D. Kroon's;
        % starting to make sense to me too)
        Xi = min(max(Xi, 0), size(Iin, 2) - 1);
        Yi = min(max(Yi, 0), size(Iin, 1) - 1);
        Xf = min(max(Xf, 0), size(Iin, 2) - 1);
        Yf = min(max(Yf, 0), size(Iin, 1) - 1);

        % weights
        perc0 = Dx .* Dy; % upper left
        perc1 = Dy .* (1-Dx); % upper right
        perc2 = Dx .* (1-Dy); % lower left
        perc3 = (1-Dx) .* (1-Dy); % lower right

    %     % Iin intensity -- I don't understand how these values are
    %     extracted...
        intensity0 = Iin(1 + Yi + Xi * size(Iin, 1)); % upper left
        intensity1 = Iin(1 + Yi + Xf * size(Iin, 1)); % upper right
        intensity2 = Iin(1 + Yf + Xi * size(Iin, 1));% lower left
        intensity3 = Iin(1 + Yf + Xf * size(Iin, 1));% lower right

    %     intensity0 = Iin(1 + Xi + Yi * size(Iin, 1)); % upper left
    %     intensity1 = Iin(1 + Xf + Yi * size(Iin, 1)); % upper right
    %     intensity2 = Iin(1 + Xi + Yf * size(Iin, 1));% lower left
    %     intensity3 = Iin(1 + Xf + Yf * size(Iin, 1));% lower right

        Iout = intensity0 .* perc3 + intensity1 .* perc2 + intensity2 .* perc1 + intensity3 .* perc0; 
        Iout = Iout';
    end
    
end
    