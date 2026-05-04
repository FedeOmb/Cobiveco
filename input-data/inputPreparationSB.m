function inputPreparationSB(case_name)

input_folder = [case_name '_input' '/'];
output_folder = [case_name '/'];

if ~exist(output_folder,'dir'), mkdir(output_folder); end

%% Read original mesh
vol = vtkRead([input_folder case_name '.vtk']);
disp(fieldnames(vol))
%% Estimate the normal vector and the origin of a basal plane
fprintf('Stima Base Normal sulla mesh...');
sur = vtkDataSetSurfaceFilter(vol);

[baseNormal,baseOrigin,debug] = cobiveco_estimateBaseNormalAndOrigin(sur);
vtkWrite(debug, [input_folder 'debug1.vtk']);

%% Adjust baseNormal and baseOrigin, if needed

baseShift = -7;
%baseShift = -15;
baseOrigin = baseOrigin + baseShift*baseNormal;

%% Clip mesh at the basal plane
fprintf('Clipping mesh alla base...');
[vol,mmgOutput] = cobiveco_clipBase(vol, baseNormal, baseOrigin);
fprintf('%s/n', mmgOutput);
vtkWrite(vol,  [input_folder 'debug2.vtk']);

%% Create surface classes
fprintf('Creazione classi superfici...');
sur = vtkDataSetSurfaceFilter(vol);
%sur.tv = ones(size(sur.points,1), 1, 'uint8');

maxAngle = 40; % max angle of face normals wrt baseNormal for defining the base class
numSubdiv = 1; % can help for coarse meshes (interpolation of face normals)
[sur,debug] = cobiveco_createClasses(sur, baseNormal, maxAngle, numSubdiv);
vtkWrite(debug,  [input_folder 'debug3.vtk']);

%% Remove bridges
%keyboard
[vol,debug,mmgOutput] = cobiveco_removeBridges(vol, sur, baseNormal, 'both', true, 0.1, 0);
vtkWrite(debug, [input_folder 'debug4.vtk']);

%% Recreate surface classes
%keyboard
sur = vtkDataSetSurfaceFilter(vol);

%[sur,debug] = cobiveco_createClasses(sur, baseNormal, maxAngle, numSubdiv);
%vtkWrite(debug, 'patient502kagglefine/debug5.vtk');
fprintf('Salvataggio risultati in corso...');
%% Write result
vtkWrite(sur,  [input_folder case_name 'clipped_sur.vtk']);
vtkWrite(sur,  [output_folder case_name '.vtp']);
vtkWrite(vol,  [input_folder case_name 'clipped_vol.vtk']);
vtkWrite(vol,  [output_folder case_name '.vtu']);

%% export surfaces
% outName = case_name;
% lv = vtkThreshold(sur, 'points', 'class', [3 3]);
% lv = vtkDataSetSurfaceFilter(lv);
% vtkWrite(lv, [output_folder outName '_endo_lv.ply']);
% rv = vtkThreshold(sur, 'points', 'class', [4 4]);
% rv = vtkDataSetSurfaceFilter(rv);
% vtkWrite(rv, [output_folder outName '_endo_rv.ply']);
% epi = vtkThreshold(sur, 'points', 'class', [2 2]);
% epi = vtkDataSetSurfaceFilter(epi);
% vtkWrite(epi, [output_folder outName '_epi.ply']);
% base = vtkThreshold(sur, 'points', 'class', [1 1]);
% base = vtkDataSetSurfaceFilter(base);
% vtkWrite(base, [output_folder outName '_base.ply']);
