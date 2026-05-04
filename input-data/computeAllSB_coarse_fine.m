clear all;

configFile = './config.txt';

addpath(genpath('../dependencies'));
addpath('../utilities');
addpath('../utilities/inputPreparation');
addpath('../functions');
addpath('../LDRB_Fibers/functions');
addpath('..');


%Legge file configurazione con elenco casi
fid = fopen(configFile, 'r');
if fid == -1
    error('File di configurazione non trovato: %s', configFile);
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

    try
        fprintf('PARTE 1: clipping e calcolo coordinate e fibre MESH COARSE...\n');
        caseNameCoarse = [caseName, '_1500mm'];
        fprintf('  -> Esecuzione script inputPreparation...\n');
        [baseNormal, baseOrigin] = inputPreparationSBv3_autobase(caseNameCoarse);
        fprintf('estimated baseNormal= [%s] , estimated baseOrigin= [%s]\n', num2str(baseNormal), num2str(baseOrigin));

        fprintf('  -> Esecuzione script computeCobiveco...\n');
        computeCobivecoSB(caseNameCoarse);

        fprintf('  -> Esecuzione script computeFibers...\n');
        computeFibersSB(caseNameCoarse);

        fprintf('  -> ESECUZIONE COMPLETATA MESH COARSE caso %s \n\n', caseNameCoarse);
    catch ME
        % Logga l'errore e continua con il caso successivo
        fprintf('  -> ERRORE su %s: %s\n\n', caseNameCoarse, ME.message);
    end

    try
        fprintf('PARTE 2: remeshing a risoluzione FINE e calcolo coordinate e fibre MESH FINE...\n');

        fprintf('Resampling della mesh a 0.5 mm con mmg...\n');
        caseNameCoarse = [caseName, '_1500mm'];
        caseNameFine = [caseName, '_500mm'];
        input_folder_coarse = [caseNameCoarse '/'];
        output_folder = [caseNameFine '_input' '/'];
    
        if ~exist(output_folder,'dir'), mkdir(output_folder); end
        vol = vtkRead([input_folder_coarse caseNameCoarse '.vtu']);
        meanEdgLen = mean(vtkEdgeLengths(vol));

        tmpMesh = [tempname '.mesh'];
        mmgWriteMesh(vol, tmpMesh); % 'vol'

        mpath = fileparts(mfilename('fullpath'));
        mmg_exe = sprintf('%s/../dependencies/mmg/build/bin/mmg3d_O3', mpath);

        % 3. Parametri per forzare l'edge length a 0.5 mm
        % -hsiz : dimensione media edge lenght
        % -hausd 0.05 : tolleranza per l'approssimazione geometrica sulla superficie
        mmg_args = '-hsiz 0.5 -hausd 0.05';

        cmd = sprintf('"%s" %s %s %s', mmg_exe, tmpMesh, tmpMesh, mmg_args);
        [mmgStatus, mmgOut] = system(cmd);

        %fprintf('mmg output:\n%s\n', mmgOut);

        % 5. Leggi il risultato
        if mmgStatus == 0
            vol = mmgReadMesh(tmpMesh);
            fprintf('Resampling a 0.5 mm completato con successo.\n');
            vtkWrite(vol, [output_folder caseNameFine '.vtk']);
        else
            warning('Resampling a 0.5 mm con mmg fallito (status %i)', mmgStatus);
        end

        % pulizia file temporanei mmg
        if exist(tmpMesh, 'file')
            delete(tmpMesh);
        end        

        createClassesClippedMesh(caseNameFine, baseOrigin, baseNormal);
        
        fprintf('  -> Esecuzione script computeCobiveco...\n');
        computeCobivecoSB(caseNameFine);

        fprintf('  -> Esecuzione script computeFibers...\n');
        computeFibersSB(caseNameFine);

        fprintf('  -> ESECUZIONE COMPLETATA caso %s \n\n', caseNameFine);
    catch ME
        % Logga l'errore e continua con il caso successivo
        fprintf('  -> ERRORE su %s: %s\n\n', caseName, ME.message);
    end    
end


