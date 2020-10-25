[US_file, dir] = uigetfile('*.csv');
US_profile = readmatrix(fullfile(dir, US_file));

[CT_file, dir] = uigetfile('*.csv');
CT_profile = readmatrix(fullfile(dir, CT_file));

dist = US_profile(:, 1); % mm
US_intensity = normalize_intensity(US_profile(:, 2));
CT_intensity = normalize_intensity(CT_profile(:, 2));

plot(dist, US_intensity, dist, CT_intensity)
legend('US', 'CT', 'fontsize', 15);
