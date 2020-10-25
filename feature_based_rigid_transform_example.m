load('/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Cropped_image_stacks/Sep_17_20/96mm_504x369.mat');
% i = randi([1, 600], 1);
i = 600;

cur = mydata_bw(:, :, i);
next = mydata_bw(:, :, i+1);

cur = rescale(cur, 0, 1, 'InputMin', min(cur, [], 'all'), 'InputMax', max(cur, [], 'all'));
next = rescale(next, 0, 1, 'InputMin', min(next, [], 'all'), 'InputMax', max(next, [], 'all'));

% Detect SURF features
curPoints = detectSURFFeatures(cur,'MetricThreshold',750.000000,'NumOctaves',3,'NumScaleLevels',5);
nextPoints = detectSURFFeatures(next,'MetricThreshold',750.000000,'NumOctaves',3,'NumScaleLevels',5);

% Extract features
[curFeatures,curValidPoints] = extractFeatures(cur,curPoints,'Upright',false);
[nextFeatures,nextValidPoints] = extractFeatures(next,nextPoints,'Upright',false);

% Match features
indexPairs = matchFeatures(curFeatures,nextFeatures,'MatchThreshold',80.000000,'MaxRatio',0.200000);
curMatchedPoints = curValidPoints(indexPairs(:,1));
nextMatchedPoints = nextValidPoints(indexPairs(:,2));
% MOVINGREG.FixedMatchedFeatures = curMatchedPoints;
% MOVINGREG.MovingMatchedFeatures = nextMatchedPoints;
size(curMatchedPoints.Location, 1)

plot(curMatchedPoints.Metric); hold on
plot(nextMatchedPoints.Metric); hold off
%%
% Apply transformation - Results may not be identical between runs because of the randomized nature of the algorithm
tformReg = estimateGeometricTransform(nextMatchedPoints,curMatchedPoints,'affine');
% tformReg = find_rigid_transform(nextMatched, curMatched);

% Let's write our own - find rigid transform

nextMatched = nextMatchedPoints.Location';
curMatched = curMatchedPoints.Location';


[tformed_x, tformed_y] = transformPointsForward(tformReg, nextMatched(1, :), nextMatched(2, :));
% 
% tformed_points = tformReg * [nextMatched; ones(1, size(nextMatched, 2))];

subplot(2, 1, 1)
scatter(curMatched(1, :), curMatched(2, :)); hold on
scatter(nextMatched(1, :), nextMatched(2, :)); hold off

subplot(2, 1, 2)
scatter(curMatched(1, :), curMatched(2, :)); hold on
scatter(tformed_x, tformed_y); hold off

norm(tformed_x - curMatched(1, :)) / norm(curMatched(1, :))
norm(tformed_y - curMatched(2, :)) / norm(curMatched(2, :))
%%
imshowpair(cur, imwarp(next, tformReg, 'OutputView', imref2d(size(cur))))
