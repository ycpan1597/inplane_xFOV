% Finds the percentage of pixels that is greater than a threshold intensity
% (default = 5)
function percentage = find_percent_of_useful_pixels(image, thresh)
    if nargin == 1
        thresh = 10;
    end
    [h, w] = size(image);
    percentage = 100 * sum(sum(image > thresh)) / (h * w);
end

