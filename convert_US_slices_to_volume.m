% Wraps US slices with a CT dicom structure and saves slices to the
% "US_volume" folder to be uploaded onto Slicer
% (adpated from Oliver's "process_ex_vivo_pig_jaw_gui.m" file)
starting_dir = '/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/Recon_results';
[files, directory] = uigetfile(fullfile(starting_dir, '*.dcm'), 'MultiSelect', 'On');

if isa(files, 'char')
    files = {files};
end

[US_info, US_info_path] = uigetfile('*.dcm'); % select one of the origianl image stacks (in dcm) to get appropriate spacing
US_info = dicominfo(fullfile(US_info_path, US_info));

pathparts = strsplit(directory, '/');
exp_date = pathparts(end - 1);
exp_date = exp_date{1}; % text is wrapped in curly braces
fprintf('Experiment was done on %s; correct file path if incorrect\n', exp_date);
files = natsortfiles(files)

% Want to combine a distant slice
% Assume 0.2 mm spacing between slices (i.e. slice_thickness = 0.2 mm) - of
% the ultrasound slice, not CT! 
slice_thickness = 0.2;
% This means we should have 5 slices for 1 mm of distance

%%
save_to = fullfile('/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/2019-09-18 inplane xFOV/US_volumes', exp_date);
if ~exist(save_to, 'dir')
    mkdir(save_to);
else
    warning('Volume already exists; please rename or overwrite');
%     return;
end


% This step is really not ideal! Need to come up with a better way
abs_pos = input('Type in the absolute location of all selected slices in ascending order separated by space: \n', 's'); 
abs_pos = cellfun(@(c) str2double(c), strsplit(abs_pos, ' '));
idx_vec = pad_position_vector_with_zeros(abs_pos, slice_thickness); 
% pos_vec = process_absolute_position(abs_pos);

ref_filename = '/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/CT/5 R/369055_20160822174508_Z/SLZ000.dcm';
% ref_filename = '/Volumes/GoogleDrive/My Drive/2016-08-28 ex vivo pig no 1-2-3-4-5/CT/1 R Coronal/Coronal_volume/IMG0001.dcm';
ref_info = dicominfo(ref_filename); % load one reference CT dicom structure
ref_info.ImageOrientationPatient = [1; 0; 0; 0; 0; -1]; % forces the images to be in coronal orientation

% for this script to work properly, we must make sure that the sorting 
% function works

total_num_files = length(min(abs_pos): slice_thickness: max(abs_pos));
%%
for i = 1:total_num_files % total number of frames processed
    
    % The following modifications are made according to Oliver's script
    ref_info.Modality = 'US';
    ref_info.StationName='US_DICOM';
    ref_info.AcquisitionGroupLength = total_num_files;
    ref_info.ImagesInAcquisition = total_num_files;
    
%     current_position = -(i - 1); %  This value is the most important one; modify this appropriately! Using the - to reverse the way images are positioned
    current_position = -(i - 1);
    
    if idx_vec(i) == 0 % the first file should definitely be in the range, so we will use that to define the size of the empty image
        data = zeros([h, w], 'int8'); 
    else
        full_filename = fullfile(directory, files{idx_vec(i)});
        cur_info = dicominfo(full_filename);
        data = dicomread(cur_info);
        [h, w] = size(data);
    end
    
 

    
    
    ref_info.Width  = size(data,2);
    ref_info.Height = size(data,1);
    ref_info.Rows    = size(data,2);
    ref_info.Columns = size(data,1);
    ref_info.PixelSpacing = [US_info.SequenceOfUltrasoundRegions.Item_1.PhysicalDeltaX * 10, US_info.SequenceOfUltrasoundRegions.Item_1.PhysicalDeltaY * 10]; % *10 to convert from cm to mm
    
    % For slices at particular locations
    
    % For fully sampled image sets
%     ref_info.ImagePositionPatient = [  -(double(ref_info.Width)  * ref_info.PixelSpacing(1))/2, ...
%                                        -(double(ref_info.Height) * ref_info.PixelSpacing(2))/2, ...
%                                        -(double(ref_info.ImagesInAcquisition) * ref_info.SliceThickness)/2 + i * ref_info.SliceThickness  ];
%     ref_info.ImagePositionPatient = [  -(double(ref_info.Width)  * ref_info.PixelSpacing(1))/2, ...
%                                        -(double(ref_info.Height) * ref_info.PixelSpacing(2))/2, ...
%                                        current_position * slice_thickness];
    ref_info.ImagePositionPatient = [  -(double(ref_info.Width)  * ref_info.PixelSpacing(1))/2, ...
                                       current_position * slice_thickness, ...
                                       -(double(ref_info.Height) * ref_info.PixelSpacing(2))/2];
                                   
    ref_info.SliceThickness = slice_thickness; % JUST A GUESS; NEED TO VERIFY
    ref_info.MediaStorageSOPClassUID = '1.2.840.10008.5.1.4.1.1.2'; % CT image storage -> so I am saving these US images as if they are CT?
    ref_info.TransferSyntaxUID = '1.2.840.10008.1.2.1'; % Explicit VR Little Endian -> Preston needs to read more about this
    ref_info.SOPClassUID = '1.2.840.10008.5.1.4.1.1.2'; % CT Image Storage

    ref_info.BitsAllocated = 8;
    ref_info.BitsStored = 8;
    ref_info.BitDepth = 8;
    ref_info.HighBit = 7;
    ref_info.WindowCenter = 128;
    ref_info.WindowWidth = 256;
    ref_info.UltrasoundColorDataPresent = 1;
    ref_info.Manufacturer = 'ZONARE';
    ref_info.InstitutionName = 'University of Michigan';
    ref_info.InstitutionalDepartmentName= 'Radiology';
    ref_info.KVP = 0;
    ref_info.SeriesDescription = 'US in a CT storage format (for slicer)';

    filename = fullfile(save_to, sprintf('US%04d.dcm', i)); 
    dicomwrite(data, filename, ref_info, 'CreateMode', 'copy');
end
    