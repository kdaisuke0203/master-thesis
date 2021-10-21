%% you need to change most of the paths in this block

%addpath(genpath('D:\GitHub\KiloSort2')) % path to kilosort folder
%addpath('D:\GitHub\npy-matlab') % for converting to Phy
rootZ = 'E:\shimbo3\s62_DBC\s62_201001_154316'; % the raw data binary file is in this folder                               %%% <======== MODIFY ========
rootH = 'E:\shimbo3\s62_DBC\s62_201001_154316'; % path to temporary binary file (same size as data, should be on fast SSD) %%% <======== MODIFY ========
pathToYourConfigFile = 'E:\shimbo3\s62_DBC\s62_201001_154316';                                                             %%% <======== MODIFY ========
% take from Github folder and put it somewhere else (together with the master_file)
chanMapFile = 's62map_kilosortChanMap.mat';                                                      %%% <======== MODIFY ========


ops.trange = [0 Inf]; % time range to sort
ops.NchanTOT    = 256; % total number of channels in your recording                              %%% <======== MODIFY ========

run(fullfile(pathToYourConfigFile, 'configFile_s62.m'))                                      %%% <======== MODIFY ========
ops.fproc       = fullfile(rootH, 'temp_wh.dat'); % proc file on a fast SSD
ops.chanMap = fullfile(pathToYourConfigFile, chanMapFile);

%% this block runs all the steps of the algorithm
fprintf('Looking for data inside %s \n', rootZ)

% is there a channel map file in this folder?
fs = dir(fullfile(rootZ, 'chan*.mat'));
if ~isempty(fs)
    ops.chanMap = fullfile(rootZ, fs(1).name);
end

% find the binary file
fs          = [dir(fullfile(rootZ, '*.bin')) dir(fullfile(rootZ, '*.dat'))];
ops.fbinary = fullfile(rootZ, fs(1).name);

% preprocess data to create temp_wh.dat
rez = preprocessDataSub(ops);

% time-reordering as a function of drift
rez = clusterSingleBatches(rez);

% saving here is a good idea, because the rest can be resumed after loading rez
save(fullfile(rootZ, 'rez.mat'), 'rez', '-v7.3');

% main tracking and template matching algorithm
rez = learnAndSolve8b(rez);

% final merges
rez = find_merges(rez, 1);

% final splits by SVD
rez = splitAllClusters(rez, 1);

% final splits by amplitudes
rez = splitAllClusters(rez, 0);

% decide on cutoff
rez = set_cutoff(rez);

fprintf('found %d good units \n', sum(rez.good>0))

% write to Phy
fprintf('Saving results to Phy  \n')
rezToPhy(rez, rootZ);

%% if you want to save the results to a Matlab file...

% discard features in final rez file (too slow to save)
rez.cProj = [];
rez.cProjPC = [];

% save final results as rez2
fprintf('Saving final results in rez2  \n')
fname = fullfile(rootZ, 'rez2.mat');
save(fname, 'rez', '-v7.3');
