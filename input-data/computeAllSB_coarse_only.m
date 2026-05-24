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
        fprintf('  -> Esecuzione script inputPreparation...\n');
        [baseNormal, baseOrigin] = inputPreparationSBv3_autobase(caseName);
        fprintf('estimated baseNormal= %s , estimated baseOrigin= %s\n', baseNormal, baseOrigin);

        %createClassesClippedMesh(caseName);
        
        fprintf('  -> Esecuzione script computeCobiveco...\n');
        computeCobivecoSB(caseName);

        fprintf('  -> Esecuzione script computeProjectiveCoordinates...\n');
        computeProjectiveCoordinates(caseName);

        fprintf('  -> Esecuzione script computeFibers...\n');
        computeFibersSB(caseName);

        fprintf('  -> ESECUZIONE COMPLETATA caso %s \n\n', caseName);
    catch ME
        % Logga l'errore e continua con il caso successivo
        fprintf('  -> ERRORE su %s: %s\n\n', caseName, ME.message);
    end
end
