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
bivmeOutputFolder = pipelineConfig.bivmeOutputFolder;
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
        fprintf('PARTE 1: clipping e calcolo coordinate e fibre MESH COARSE...\n');

        fprintf('  -> Esecuzione script inputPreparation...\n');
        [baseNormal, baseOrigin] = inputPreparationSBv3_autobase(inputBaseDir,caseNameCoarse);
        fprintf('estimated baseNormal= [%s] , estimated baseOrigin= [%s]\n', num2str(baseNormal), num2str(baseOrigin));

        fprintf('  -> Esecuzione script computeCobiveco...\n');
        computeCobivecoSB(inputBaseDir,caseNameCoarse);

        fprintf('  -> Esecuzione script computeProjectiveCoordinates...\n');
        computeProjectiveCoordinates(inputBaseDir,caseNameCoarse);

        fprintf('  -> Esecuzione script computeFibers...\n');
        computeFibersSB(inputBaseDir,caseNameCoarse);

        fprintf('  -> ESECUZIONE COMPLETATA MESH COARSE caso %s \n\n', caseNameCoarse);
    catch ME
        % Logga l'errore e continua con il caso successivo
        fprintf('  -> ERRORE su %s: %s\n\n', caseNameCoarse, ME.message);
    end

    try
        fprintf('PARTE 2: remeshing a risoluzione FINE e calcolo coordinate e fibre MESH FINE...\n');

        fprintf('Resampling della mesh a %g mm con mmg...\n', fineRes);
        caseNameCoarse = sprintf('%s_%.0fmm', caseName, coarseRes * 1000);
        caseNameFine = sprintf('%s_%.0fmm', caseName, fineRes * 1000);
        input_folder_coarse = [inputBaseDir '/' + caseNameCoarse '/'];
        output_folder = [inputBaseDir '/' caseNameFine '_input' '/'];
    
        if ~exist(output_folder,'dir'), mkdir(output_folder); end
        vol = vtkRead([input_folder_coarse caseNameCoarse '.vtu']);
        meanEdgLen = mean(vtkEdgeLengths(vol));

        tmpMesh = [tempname '.mesh'];
        mmgWriteMesh(vol, tmpMesh); % 'vol'

        mpath = fileparts(mfilename('fullpath'));
        mmg_exe = sprintf('%s/mmg/build/bin/mmg3d_O3', depsDir);

        % 3. Parametri per forzare l'edge length alla risoluzione indicata nel JSON
        % -hsiz : dimensione media edge lenght
        % -hausd 0.05 : tolleranza per l'approssimazione geometrica sulla superficie
        mmg_args = sprintf('-hsiz %g -hausd 0.05', fineRes);

        cmd = sprintf('"%s" %s %s %s', mmg_exe, tmpMesh, tmpMesh, mmg_args);
        [mmgStatus, mmgOut] = system(cmd);

        %fprintf('mmg output:\n%s\n', mmgOut);

        % 5. Leggi il risultato
        if mmgStatus == 0
            vol = mmgReadMesh(tmpMesh);
            fprintf('Resampling a %g mm completato con successo.\n', fineRes);
            vtkWrite(vol, [output_folder caseNameFine '.vtk']);
        else
            warning('Resampling a %g mm con mmg fallito (status %i)', fineRes, mmgStatus);
        end

        % pulizia file temporanei mmg
        if exist(tmpMesh, 'file')
            delete(tmpMesh);
        end        

        createClassesClippedMesh(inputBaseDir,caseNameFine, baseOrigin, baseNormal);
        
        fprintf('  -> Esecuzione script computeCobiveco...\n');
        computeCobivecoSB(inputBaseDir,caseNameFine);

        fprintf('  -> Esecuzione script computeProjectiveCoordinates...\n');
        computeProjectiveCoordinates(inputBaseDir,caseNameFine);

        fprintf('  -> Esecuzione script computeFibers...\n');
        computeFibersSB(inputBaseDir,caseNameFine);

        fprintf('  -> ESECUZIONE COMPLETATA caso %s \n\n', caseNameFine);
    catch ME
        % Logga l'errore e continua con il caso successivo
        fprintf('  -> ERRORE su %s: %s\n\n', caseName, ME.message);
    end    
end
