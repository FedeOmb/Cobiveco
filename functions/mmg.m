function [mesh,status,cmdout] = mmg(mesh, sol, paramString)

% [mesh,status,cmdout] = mmg(mesh, sol, paramString)
% 
% Uses mmg meshing Software 
% (for more infos, see https://www.mmgtools.org/)


[tmpdir,name] = fileparts(tempname);
meshfile = sprintf('%s/%s.mesh', tmpdir, name);
solfile = sprintf('%s/%s.sol', tmpdir, name);

mmgWriteMesh(mesh, meshfile);
mmgWriteSol(sol, solfile);
%type(meshfile)
%type(solfile)
mpath = fileparts(mfilename('fullpath'));
mmg_executable_path = sprintf('%s/../dependencies/mmg/build/bin/mmg3d_O3', mpath);
cmd = sprintf('"%s" %s %s -sol %s %s', mmg_executable_path, meshfile, meshfile, solfile, paramString);
fprintf("Running mmg with command: %s \n", cmd);
[status,cmdout] = system(cmd);
fprintf("mmg output: %s\n", cmdout);
fprintf("mmg status: %d\n", status);
mesh = struct();
if status==0
    mesh = mmgReadMesh(meshfile);
elseif status == 126 || status == 127
    message = sprintf('failed to run mmg3d (file at "%s")', mmg_executable_path);
    error(message);
    error(cmdout);
else
    message = sprintf('mmg failed with status "%i"', status);
    error(message);
    error(cmdout);
end

end
