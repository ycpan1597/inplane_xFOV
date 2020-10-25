% The script is written to create empty slices to replace ones that are
% intentionally deleted in the "Coronal_volume_corrupted" dataset.
% Currently, the Coronal_volume_corrupted dataset has no info (empty
% slices) from 101 to 200, and from 301 to 400. 

close all; clear all; clc
empty = zeros([251, 512], 'int16');

missing_start = 301;
missing_end = 400;

name = missing_start:missing_end;
directory = '/Volumes/GoogleDrive/My Drive/US_research_cloud/Current Research/Coronal_volume_corrupted/'; 
file = fullfile(directory, sprintf('IMG%04d.dcm', missing_start - 1));
info = dicominfo(file);
start_location = info.ImagePositionPatient(2);
ref_info = dicominfo('/Volumes/GoogleDrive/My Drive/US_research_cloud/Current Research/Coronal_volume_corrupted/IMG0001.dcm');

for i = 1:length(name)
    ref_info.ImagePositionPatient = [-51.2; start_location + 0.2 * i; 25.002];
    dicomwrite(empty, sprintf('IMG%04d.dcm', name(i)), ref_info, 'CreateMode', 'copy')
    disp(name(i));
end