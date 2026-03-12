addpath('../../dependencies/gptoolbox/matrix');
addpath('../../dependencies/gptoolbox/mesh');
addpath('../../dependencies/gptoolbox/quat');
addpath('../../dependencies/vtkToolbox/MATLAB');
addpath('../functions');

%%
alphaEndo = 60;
alphaEpi  = -60;
betaEndo  = 0;
betaEpi   = 0;

caseName = '503kaggle500';
if ~exist([ 'result_' caseName], 'dir')
    mkdir([ 'result_' caseName]);
end

clear cfg;
cfg.sourceDir = [ 'input_' caseName];
cfg.targetPrefix = [ 'result_' caseName '/' caseName '_fibers'];
cfg.onlyOneVentricle = false;
cfg.volName = caseName;
cfg.surNames = {caseName};
cfg.alphaSeptLeft  = alphaEndo;
cfg.alphaSeptRight = alphaEndo;
cfg.alphaWallEndo  = alphaEndo;
cfg.alphaWallEpi   = alphaEpi;
cfg.betaSeptLeft   = betaEndo;
cfg.betaSeptRight  = betaEndo;
cfg.betaWallEndo   = betaEndo;
cfg.betaWallEpi    = betaEpi;
cfg.exportIntermediateResults = false;
cfg.exportFinalResult = true;
cfg.exportFiber = true;
cfg.exportSheet = true;
cfg.exportSheetnormal = true;
cfg.exportAngles = false;
cfg.outputAngleUnit = 'rad';
cfg.exportDebugAngle = true;
cfg.tol = 1e-12;
cfg.maxit = 1000;

% res = ldrb_main_original(cfg);
res = ldrb_main_adapted(cfg);

%export file .lon per opencarp
lon_filename = [ 'result_' caseName '/' caseName '_fibersOpencarp.lon'];
lon_file = fopen(lon_filename, 'w');
fprintf(lon_file, '2\n'); %header 2 modello fiber + sheet
data = [res.cellData.Fiber, res.cellData.Sheet];
fprintf(lon_file, '%f %f %f %f %f %f\n', data');
fclose(lon_file);

