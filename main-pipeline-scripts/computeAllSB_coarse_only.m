clear all;

% Legge il file JSON di configurazione
pipelineConfigFile = './pipeline_config.json';
if exist(pipelineConfigFile, 'file')
    pipelineConfig = jsondecode(fileread(pipelineConfigFile));
else
    error('File di configurazione non trovato: %s', pipelineConfigFile);
end

casesList= pipelineConfig.casesListFile;
inputBaseDir = pipelineConfig.cobivecoCasesFolder;
bivmeOutputFolder = pipelineConfig.bivmOutputFolder;
coarseRes = pipelineConfig.coarseResolutionMm;
fineRes = pipelineConfig.fineResolutionMm;

repoDir = '/home/matlab/cobiveco';
depsDir = getenv('COBIVECO_DEPS_DIR');
if isempty(depsDir)
    depsDir = '../dependencies';
end
if isfolder(depsDir)
    addpath(genpath(depsDir));
else
    error('Directory dipendenze non trovata: %s', depsDir);
end

addpath(fullfile(repoDir, 'utilities'));
addpath(fullfile(repoDir, 'utilities', 'inputPreparation'));
addpath(fullfile(repoDir, 'functions'));
addpath(fullfile(repoDir, 'LDRB_Fibers', 'functions'));
addpath(fullfile(repoDir));


%Legge file configurazione con elenco casi
fid = fopen(casesList, 'r');
if fid == -1
    error('File lista casi non trovato: %s', casesList);
end
raw = textscan(fid, '%s', 'CommentStyle', '#', 'Delimiter', '\n');
fclose(fid);

cases = raw{1};
cases = cases(~cellfun(@isempty, strtrim(cases)));
fprintf('Trovati %d casi da processare.\n\n', numel(cases));

% Loop sui casi
for i = 1:numel(cases)
    caseName = strtrim(cases{i});

    fprintf('========== [%d/%d] %s ==========\n', i, numel(cases), caseName);
        caseNameCoarse = sprintf('%s_%.0fmm', caseName, coarseRes * 1000);
    try
        fprintf('  -> Recupero mesh da bivmeOutputFolder...\n');
        bivmeCaseFolder = fullfile(bivmeOutputFolder, caseName);
        sourceVtk = fullfile(bivmeOutputFolder, "volumetric", [caseNameCoarse '.vtk']);
        destFolder = fullfile(inputBaseDir, [caseNameCoarse '_input']);
        destVtk = fullfile(destFolder, [caseNameCoarse '.vtk']);
        
        if ~exist(destFolder, 'dir')
            mkdir(destFolder);
        end
        if exist(sourceVtk, 'file')
            copyfile(sourceVtk, destVtk);
        else
            error('File VTK originale non trovato per il caso %s nella cartella di bivme indicata %s', caseName, bivmeOutputFolder);
        end

        fprintf('  -> Esecuzione script inputPreparation...\n');
        [baseNormal, baseOrigin] = inputPreparationSBv3_autobase(inputBaseDir,caseNameCoarse);
        fprintf('estimated baseNormal= [%s] , estimated baseOrigin= [%s]\n', num2str(baseNormal'), num2str(baseOrigin'));
        
        fprintf('  -> Esecuzione script computeCobiveco...\n');
        computeCobivecoSB(inputBaseDir,caseNameCoarse);

        fprintf('  -> Esecuzione script computeProjectiveCoordinates...\n');
        computeProjectiveCoordinates(inputBaseDir,caseNameCoarse);

        fprintf('  -> Esecuzione script computeFibers...\n');
        computeFibersSB(inputBaseDir,caseNameCoarse);

        fprintf('  -> ESECUZIONE COMPLETATA caso %s \n\n', caseName);
    catch ME
        % Logga l'errore e continua con il caso successivo
        fprintf('  -> ERRORE su %s: %s\n\n', caseName, ME.message);
    end
end
