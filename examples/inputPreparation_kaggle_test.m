addpath(genpath('../dependencies'));
addpath('../utilities');
addpath('../utilities/inputPreparation');
addpath('../functions');

clear all;

input_folder = ['503kaggle1500_input' '/'];
output_folder = input_folder;

%% Read original mesh
vol = vtkRead([input_folder '503kaggle1500cm.vtk']);

%% Estimate the normal vector and the origin of a basal plane
sur = vtkDataSetSurfaceFilter(vol);

% center = mean(sur.points);
% dirSep = null(baseNormal(:)');
% dirSep = dirSep(:,1)';
% proj = (sur.points - center) * dirSep';
% sur.tv = uint8(proj > 0);

[baseNormal,baseOrigin,debug] = cobiveco_estimateBaseNormalAndOrigin(sur);
vtkWrite(debug, [output_folder 'debug1.vtk']);

%% Adjust baseNormal and baseOrigin, if needed

%baseShift = -7;
%baseShift = -15;
%baseOrigin = baseOrigin + baseShift*baseNormal;

%% Clip mesh at the basal plane

vol = cobiveco_clipBase(vol, baseNormal, baseOrigin);
vtkWrite(vol,  [output_folder 'debug2.vtk']);

%% Create surface classes

sur = vtkDataSetSurfaceFilter(vol);
%sur.tv = ones(size(sur.points,1), 1, 'uint8');

maxAngle = 40; % max angle of face normals wrt baseNormal for defining the base class
numSubdiv = 1; % can help for coarse meshes (interpolation of face normals)
[sur,debug] = cobiveco_createClasses(sur, baseNormal, maxAngle, numSubdiv);
vtkWrite(debug,  [output_folder 'debug3.vtk']);

%% Remove bridges
%keyboard
%[vol,debug,mmgOutput] = cobiveco_removeBridges(vol, sur, baseNormal, 'rv', true, 0.1, 0);
%vtkWrite(debug, 'patient502kagglefine/debug4.vtk');

%% Recreate surface classes
%keyboard
%sur = vtkDataSetSurfaceFilter(vol);

%[sur,debug] = cobiveco_createClasses(sur, baseNormal, maxAngle, numSubdiv);
%vtkWrite(debug, 'patient502kagglefine/debug5.vtk');

%% Write result
vtkWrite(sur,  [output_folder '503kaggleclipped_sur.vtk']);
vtkWrite(sur,  [output_folder '503kaggleclipped_sur.vtp']);
vtkWrite(vol,  [output_folder '503kaggleclipped_vol.vtk']);
vtkWrite(vol,  [output_folder '503kaggleclipped_vol.vtu']);

%% export surfaces
outName = '503kaggle1500';
lv = vtkThreshold(sur, 'points', 'class', [3 3]);
lv = vtkDataSetSurfaceFilter(lv);
vtkWrite(lv, [output_folder outName '_endo_lv.ply']);
rv = vtkThreshold(sur, 'points', 'class', [4 4]);
rv = vtkDataSetSurfaceFilter(rv);
vtkWrite(rv, [output_folder outName '_endo_rv.ply']);
epi = vtkThreshold(sur, 'points', 'class', [2 2]);
epi = vtkDataSetSurfaceFilter(epi);
vtkWrite(epi, [output_folder outName '_epi.ply']);
base = vtkThreshold(sur, 'points', 'class', [1 1]);
base = vtkDataSetSurfaceFilter(base);
vtkWrite(base, [output_folder outName '_base.ply']);
