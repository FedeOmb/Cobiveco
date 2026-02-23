addpath('..');
clear all;

% Create a cobiveco object, providing a config struct with input and output path prefixes
c = cobiveco(struct('inPrefix','patient502kagglefinecoord/patient502kagglefinecoord', 'outPrefix','result_patient502kagglefine/'));

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