clc
US_file = '/Volumes/GoogleDrive/My Drive/US_research_cloud/Current Research/US_volume/Mar_13_20_complete';
US = squeeze(dicomreadVolume(US_file));
US_spacing = 0.033; %mm
R_US = imref3d(size(US), US_spacing, US_spacing, US_spacing); % isotropic voxel

CT_file = '/Volumes/GoogleDrive/My Drive/US_research_cloud/Current Research/Coronal_volume';
CT = squeeze(dicomreadVolume(CT_file));
CT_spacing = 0.2; %mm
R_CT = imref3d(size(CT), CT_spacing, CT_spacing, CT_spacing); % isotropic voxel
%%
tform_3d = affine3d([0.47 0.88 0 0.64; 0 0 -1 -3; -0.88 0.47 0 4.55; 0 0 0 1]'); % got this transform from slicer
tformed_US = imwarp(US, tform_3d);

idx = 33;
imshow(squeeze(tformed_US(idx, :, :)), [])