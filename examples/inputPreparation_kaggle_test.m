addpath(genpath('../dependencies'));
addpath('../utilities');
addpath('../utilities/inputPreparation');
addpath('../functions');

%% Read original mesh

vol = vtkRead('patient502kaggle/patient502kaggle_sub2.vtk');

%% Estimate the normal vector and the origin of a basal plane

sur = vtkDataSetSurfaceFilter(vol);

% center = mean(sur.points);
% dirSep = null(baseNormal(:)');
% dirSep = dirSep(:,1)';
% proj = (sur.points - center) * dirSep';
% sur.tv = uint8(proj > 0);


[baseNormal,baseOrigin,debug] = cobiveco_estimateBaseNormalAndOrigin(sur);
vtkWrite(debug, 'patient502kaggle/debug1_sub2.vtk');

%% Adjust baseNormal and baseOrigin, if needed

%baseShift = -7;
%baseShift = -15;
%baseOrigin = baseOrigin + baseShift*baseNormal;

%% Clip mesh at the basal plane

vol = cobiveco_clipBase(vol, baseNormal, baseOrigin);
vtkWrite(vol, 'patient502kaggle/debug2_sub2.vtk');

%% Create surface classes

sur = vtkDataSetSurfaceFilter(vol);

%sur.tv = ones(size(sur.points,1), 1, 'uint8');

maxAngle = 40; % max angle of face normals wrt baseNormal for defining the base class
numSubdiv = 1; % can help for coarse meshes (interpolation of face normals)
[sur,debug] = cobiveco_createClasses(sur, baseNormal, maxAngle, numSubdiv);
vtkWrite(debug, 'patient502kaggle/debug3_sub2.vtk');

%% Remove bridges
%keyboard
%[vol,debug,mmgOutput] = cobiveco_removeBridges(vol, sur, baseNormal, 'rv', true);
%vtkWrite(debug, 'patient501kaggle/debug4.vtk');

%% Recreate surface classes
%keyboard
%sur = vtkDataSetSurfaceFilter(vol);

%sur.tv = ones(size(sur.points,1), 1);

%[sur,debug] = cobiveco_createClasses(sur, baseNormal, maxAngle, numSubdiv);
%vtkWrite(debug, 'patient501kaggle/debug5.vtk');

%% Write result
vtkWrite(sur, 'patient502kaggle/test_clipping_patient502_sur_sub2.vtk');
vtkWrite(vol, 'patient502kaggle/test_clipping_patient502_vol_sub2.vtk');
vtkWrite(vol, 'patient502kaggle/test_clipping_patient502_vol_sub2.vtu');

 outName = 'patient502kaggledef/patient502kaggledef';
 lv = vtkThreshold(sur, 'points', 'class', [3 3]);
 lv = vtkDataSetSurfaceFilter(lv);
 vtkWrite(lv, [outName '_endo_lv.ply']);
 rv = vtkThreshold(sur, 'points', 'class', [4 4]);
 rv = vtkDataSetSurfaceFilter(rv);
 vtkWrite(rv, [outName '_endo_rv.ply']);
 epi = vtkThreshold(sur, 'points', 'class', [2 2]);
 epi = vtkDataSetSurfaceFilter(epi);
 vtkWrite(epi, [outName '_epi.ply']);
 base = vtkThreshold(sur, 'points', 'class', [1 1]);
 base = vtkDataSetSurfaceFilter(base);
 vtkWrite(base, [outName '_base.ply']);
