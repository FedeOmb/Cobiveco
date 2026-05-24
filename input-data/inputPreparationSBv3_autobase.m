function[baseNormal, baseOrigin] = inputPreparationSBv2_givenbase(case_name)

input_folder = [case_name '_input' '/'];
output_folder = [case_name '/'];

if ~exist(output_folder,'dir'), mkdir(output_folder); end

%% Read original mesh
vol = vtkRead([input_folder case_name '.vtk']);
%disp(fieldnames(vol))
%% Estimate the normal vector and the origin of a basal plane
fprintf('Stima Base Normal sulla mesh...');
sur = vtkDataSetSurfaceFilter(vol);

[baseNormal,baseOrigin,debug] = cobiveco_estimateBaseNormalAndOrigin(sur);
vtkWrite(debug, [input_folder 'debug1.vtk']);

meanEdgLen = mean(vtkEdgeLengths(vol));
%fprintf('Pre-processing mesh con mmg -optim...\n');

% Scrivi solo il mesh file (niente sol)
%tmpMesh = [tempname '.mesh'];
%mmgWriteMesh(vol, tmpMesh);

% Percorso eseguibile mmg (stesso usato dal wrapper)
%mpath = fileparts(mfilename('fullpath'));
%mmg_exe = sprintf('%s/../dependencies/mmg/build/bin/mmg3d_O3', mpath);

% Chiama mmg con -optim e vincoli di dimensione per preservare la risoluzione originale
% Aggiunto -hsiz pari a meanEdgLen per mantenere la dimensione media originale
% Aggiunto -hausd 0.2 per evitare iper-raffinamenti dovuti a curvature superficiali
%[mmgStatus, mmgOut] = system(sprintf('"%s" %s %s -optim -hsiz %1.5e -hausd 0.2', ...
%     mmg_exe, tmpMesh, tmpMesh, meanEdgLen));

%fprintf('mmg output:\n%s\n', mmgOut);

%if mmgStatus == 0
%    vol = mmgReadMesh(tmpMesh);
%    fprintf('Pre-processing con -optim completato.\n');
%else
%    warning('mmg -optim fallito (status %i). Proseguo con mesh originale.', mmgStatus);
%end

%% Adjust baseNormal and baseOrigin, if needed

%baseShift = -7;
%baseShift = -15;
%baseOrigin = baseOrigin + baseShift*baseNormal;
%baseNormal = [0.58 -0.37 -0.71];
%baseOrigin = [32.13 -62.16 -36.20];
%% Clip mesh at the basal plane
fprintf('Clipping mesh alla base...');
vol = cobiveco_clipBase(vol, baseNormal, baseOrigin);
vtkWrite(vol,  [input_folder 'debug2_clipped.vtk']);

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
vol = vtkDeleteDataArrays(vol);
vtkWrite(vol, [input_folder 'debug2_clipped_clean.vtk']);
%% Create surface classes
fprintf('Creazione classi superfici (provvisorie)...');
sur = vtkDataSetSurfaceFilter(vol);
%sur.tv = ones(size(sur.points,1), 1, 'uint8');

maxAngle = 50; % max angle of face normals wrt baseNormal for defining the base class
numSubdiv = 1; % can help for coarse meshes (interpolation of face normals)
[sur,debug] = cobiveco_createClasses(sur, baseNormal, baseOrigin, maxAngle, numSubdiv);
vtkWrite(debug,  [input_folder 'debug3_tempclasses.vtk']);

%% Remove bridges
%keyboard
%fprintf('Rimozione bridges...');
%[vol,debug,mmgOutput] = cobiveco_removeBridges(vol, sur, baseNormal, 'both', true, 0.1, 0);
%vtkWrite(debug, [input_folder 'debug4_delbridges.vtk']);

%% Recreate surface classes
%keyboard
fprintf('Creazione classi superfici (definitive)...');
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
