function createClassesClippedMesh(case_name, baseOrigin, baseNormal)

input_folder = [case_name '_input' '/'];
output_folder = [case_name '/'];

if ~exist(output_folder,'dir'), mkdir(output_folder); end

%% Read original mesh
vol = vtkRead([input_folder case_name '.vtk']);
disp(fieldnames(vol))
%% Estimate the normal vector and the origin of a basal plane
fprintf('utilizzo baseNormal e baseOrigin già stimati...');
%sur = vtkDataSetSurfaceFilter(vol);

%[baseNormal,baseOrigin,debug] = cobiveco_estimateBaseNormalAndOrigin(sur);
%vtkWrite(debug, [input_folder 'debug1.vtk']);

%% Adjust baseNormal and baseOrigin, if needed

%baseShift = -7;
%baseShift = -15;
%baseOrigin = baseOrigin + baseShift*baseNormal;
baseNormal = [0.58 -0.37 -0.71]
baseOrigin = [32.13 -62.16 -36.20]
%% Clip mesh at the basal plane
%fprintf('Clipping mesh alla base...');
%vol = cobiveco_clipBase(vol, baseNormal, baseOrigin);
%vtkWrite(vol,  [input_folder 'debug2_clipped.vtk']);

fprintf('Pulizia mesh da eventuali frammenti...');
%% pulizia mesh
vol = vtkDeleteDataArrays(vol);
vol = vtkConnectivityFilter(vol);
if isfield(vol.pointData, 'RegionId')
    mainRegionId = mode(double(vol.pointData.RegionId))
    vol = vtkThreshold(vol, 'points', 'RegionId', [mainRegionId mainRegionId]);
elseif isfield(vol.cellData, 'RegionId')
    mainRegionId = mode(double(vol.cellData.RegionId))
    vol = vtkThreshold(vol, 'cells', 'RegionId', [mainRegionId mainRegionId]);
else
    error('var RegionId non trovata');
end
%% Recreate surface classes
%keyboard
fprintf('Creazione classi superfici...');
sur = vtkDataSetSurfaceFilter(vol);

maxAngle = 40; % max angle of face normals wrt baseNormal for defining the base class
numSubdiv = 0;
[sur,debug] = cobiveco_createClasses(sur, baseNormal, baseOrigin, maxAngle, numSubdiv);
vtkWrite(debug,  [input_folder 'debug5_defclasses.vtk']);

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
