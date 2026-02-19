addpath('..');

% Create a cobiveco object, providing a config struct with input and output path prefixes
c = cobiveco(struct('inPrefix','patient501sb2/patient501sb2', 'outPrefix','result_patient501sb2/'));

V = vtkRead('patient501sb2/patient501sb2.vtu');
whos V
size(V.points)
size(V.cells)
class(V.cells)
if isfield(V,'cellTypes')
    disp('unique cellTypes:');
    disp(unique(V.cellTypes));
    disp('first 10 cellTypes:');
    disp(V.cellTypes(1:min(10,end)));
end
% Run computation of all coordinates
c.prepareMesh0;
if c.cfg.CobivecoX == true
    c.computeAllCobivecoX;
else 
    c.computeAllCobiveco;
end

% Optional: Retrieve the result and a config struct with all parameters
result = c.result;
config = c.cfg;