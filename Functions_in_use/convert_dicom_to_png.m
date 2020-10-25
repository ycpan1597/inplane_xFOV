% This function converts all dcm files in a directory into png files with
% the same filename
function convert_dicom_to_png()
   d = uigetdir();
   cd(d)
   files = dir(d);
   idx = 1;
   for i = 1:length(files)
       if endsWith(lower(files(i).name), '.dcm')
%            img = select_and_read_dcm(files(i).name);
           img = dicomread(files(i).name); 
%            fn = erase(files(i).name, {'dcm', 'DCM'}); % simply using the
%            dcm filename as the png filename
           parts = strsplit(d, '/');
           fn = sprintf('%s_%03d', parts{end}, idx);
           imwrite(uint8(img), strcat(fn, '.png'));
           idx = idx + 1;
       end
   end
end