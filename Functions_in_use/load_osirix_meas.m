function [lengths_in_cm, pts, profiles, summaries] = load_osirix_meas(directory, json_file)
    fname = fullfile(directory, json_file);
    ROI = jsondecode(fileread(fname));
    
    N = length(ROI); % number of lines
    pts = cell(N, 1);
    profiles = cell(N, 1);
    summaries = cell(N, 1);
    
    [pts{:}] = ROI.ROIPoints; % unpacks the points of each line into a cell array
    [profiles{:}] = ROI.DataValues;
    [summaries{:}] = ROI.DataSummary;
    lengths_in_cm = cellfun(@(x) x.LengthCM * 10, summaries); % convert to mm
end