function [MOVINGREG] = surfRegister(MOVING,FIXED)
    % Get linear indices to finite valued data
    finiteIdx = isfinite(FIXED(:));

    % Replace NaN values with 0
    FIXED(isnan(FIXED)) = 0;

    % Replace Inf values with 1
    FIXED(FIXED==Inf) = 1;

    % Replace -Inf values with 0
    FIXED(FIXED==-Inf) = 0;

    % Normalize input data to range in [0,1].
    FIXEDmin = min(FIXED(:));
    FIXEDmax = max(FIXED(:));
    if isequal(FIXEDmax,FIXEDmin)
        FIXED = 0*FIXED;
    else
        FIXED(finiteIdx) = (FIXED(finiteIdx) - FIXEDmin) ./ (FIXEDmax - FIXEDmin);
    end

    % Normalize MOVING image

    % Get linear indices to finite valued data
    finiteIdx = isfinite(MOVING(:));

    % Replace NaN values with 0
    MOVING(isnan(MOVING)) = 0;

    % Replace Inf values with 1
    MOVING(MOVING==Inf) = 1;

    % Replace -Inf values with 0
    MOVING(MOVING==-Inf) = 0;

    % Normalize input data to range in [0,1].
    MOVINGmin = min(MOVING(:));
    MOVINGmax = max(MOVING(:));
    if isequal(MOVINGmax,MOVINGmin)
        MOVING = 0*MOVING;
    else
        MOVING(finiteIdx) = (MOVING(finiteIdx) - MOVINGmin) ./ (MOVINGmax - MOVINGmin);
    end

    % Default spatial referencing objects
    fixedRefObj = imref2d(size(FIXED));
    movingRefObj = imref2d(size(MOVING));

    % Detect SURF features
    fixedPoints = detectSURFFeatures(FIXED,'MetricThreshold',750.000000,'NumOctaves',3,'NumScaleLevels',5);
    movingPoints = detectSURFFeatures(MOVING,'MetricThreshold',750.000000,'NumOctaves',3,'NumScaleLevels',5);

    % Extract features
    [fixedFeatures,fixedValidPoints] = extractFeatures(FIXED,fixedPoints,'Upright',false);
    [movingFeatures,movingValidPoints] = extractFeatures(MOVING,movingPoints,'Upright',false);

    % Match features
    indexPairs = matchFeatures(fixedFeatures,movingFeatures,'MatchThreshold',50.000000,'MaxRatio',0.500000);
    fixedMatchedPoints = fixedValidPoints(indexPairs(:,1));
    movingMatchedPoints = movingValidPoints(indexPairs(:,2));
    MOVINGREG.FixedMatchedFeatures = fixedMatchedPoints;
    MOVINGREG.MovingMatchedFeatures = movingMatchedPoints;

    % Apply transformation - Results may not be identical between runs because of the randomized nature of the algorithm
    tform = estimateGeometricTransform(movingMatchedPoints,fixedMatchedPoints,'affine');
    MOVINGREG.Transformation = tform;
    MOVINGREG.RegisteredImage = imwarp(MOVING, movingRefObj, tform, 'OutputView', fixedRefObj, 'SmoothEdges', true);


end

