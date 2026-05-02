function computeFibersSB(case_name)

%addpath('./LDRB_Fibers/functions');
input_folder = [case_name '_resCobiveco' '/'];
resCobivecoName = [case_name '_resCobiveco'];
output_folder = [case_name '_resFibers' '/'];
copyfile([case_name '/' case_name '.vtp'], input_folder);

if ~exist(output_folder,'dir'), mkdir(output_folder); end

%%
alphaEndo = 60;
alphaEpi  = -60;
betaEndo  = 0;
betaEpi   = 0;

clear cfg;
cfg.sourceDir = input_folder;
cfg.targetPrefix = [ output_folder case_name '_fibers'];
cfg.onlyOneVentricle = false;
cfg.volName = resCobivecoName;
cfg.surNames = {case_name};
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
lon_filename = [ output_folder case_name '_fibersOpencarp.lon'];
lon_file = fopen(lon_filename, 'w');
fprintf(lon_file, '2\n'); %header 2 modello fiber + sheet
data = [res.cellData.Fiber, res.cellData.Sheet];
fprintf(lon_file, '%f %f %f %f %f %f\n', data');
fclose(lon_file);

