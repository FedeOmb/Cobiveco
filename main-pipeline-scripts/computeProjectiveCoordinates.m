function computeProjectiveCoordinates(inputBaseDir, case_name)
% Calcola e aggiunge le coordinate rvlv e aprt alla mesh, a partire dagli assi salvati in file .mat.

    output_folder = [inputBaseDir '/' case_name '_resCobiveco/'];
    mesh_file = fullfile(output_folder, [case_name '_resCobiveco.vtu']);

    % Verifica l'esistenza della mesh
    if ~exist(mesh_file, 'file')
        error('File mesh non trovato per il caso: %s', case_name);
    end
    
    % Carica la mesh
    mesh = vtkRead(mesh_file);

    % File degli assi esportati da Cobiveco
    lr_file = fullfile(output_folder, 'leftRightAx.mat');
    ap_file = fullfile(output_folder, 'antPostAx.mat');

    if ~exist(lr_file, 'file') || ~exist(ap_file, 'file')
        error('File degli assi non trovati in %s. Assicurati di avere impostato exportLevel = 3 in cobiveco.', output_folder);
    end

    % Carica le variabili salvate
    load(lr_file, 'leftRightAx');
    load(ap_file, 'antPostAx');

    % Estrai i punti della mesh
    points = double(mesh.points);

    % Calcola e normalizza lvrv (da sinistra 0 a destra 1)
    proj_rl = points * (leftRightAx)';
    mesh.pointData.lvrv = single((proj_rl - min(proj_rl)) / (max(proj_rl) - min(proj_rl)));

    % Calcola e normalizza aprt (da posteriore 0 ad anteriore 1)
    proj_ap = points * (-antPostAx)';
    mesh.pointData.aprt = single((proj_ap - min(proj_ap)) / (max(proj_ap) - min(proj_ap)));

    % Sovrascrivi il file mesh aggiungendo i nuovi pointData
    vtkWrite(mesh, mesh_file);
    fprintf('  -> Coordinate proiettive (lvrv, aprt) salvate con successo nella mesh\n');
end
