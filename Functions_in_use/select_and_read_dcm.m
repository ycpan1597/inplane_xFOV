function [img, info, fn] = select_and_read_dcm(varargin)
    defaultDirectory = pwd;

    p = inputParser;
    
    p.addOptional('directory', defaultDirectory, @(d) (exist(d, 'dir') == 7 || exist(d, 'file') == 2));
    p.addParameter('show', false)
    parse(p, varargin{:});
    opt = p.Results;
    directory = opt.directory;
    show = opt.show;
    
    if ~contains(lower(directory), '.dcm')
        [file, path] = uigetfile(fullfile(directory, '*.dcm'));
        info = dicominfo(fullfile(path, file));
    else
        file = split(directory, '/');
        file = file(end);
        file = file{:};
        info = dicominfo(directory);
    end
    
    img = dicomread(info);
    
    if ndims(img) == 3
        img = mean(img, 3);
    end
    
    fn = erase(file, {'.dcm', '.DCM'});
    
    dx = 0;
    dy = 0;
    if isfield(info, 'PixelSpacing') % for a CT file
        dx = info.PixelSpacing(1);
        dy = info.PixelSpacing(2);
    elseif isfield(info, 'SequenceOfUltrasoundRegions') % for a US file
        dx = info.SequenceOfUltrasoundRegions.Item_1.PhysicalDeltaX * 10; % convert from cm into mm
        dy = info.SequenceOfUltrasoundRegions.Item_1.PhysicalDeltaY * 10;
    else
        error('cannot determine the spacing');
    end
    RA = imref2d(size(img), dx, dy);
    
    if show
        figure();
%         imshow(img, RA, [])
        imshow(img, [])
%         xlabel('mm')
%         ylabel('mm')
%         axis on
        title(fn)
    end
    
%     fprintf('PixelSpacing = %.3f\n', info.DetectorElementSpacing); % only
%     applicable to x-ray
    
end