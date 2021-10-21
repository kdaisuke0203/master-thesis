
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%                   kilosort2 chanMap �ɂ���
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% �K�v�Ȃ���
% 
% xcoords     : �I���W�A�S�`�����l���� x 1���� 
% ycoords     : �����W�A�S�`�����l���� x 1����
% kcoords     : �V�����N�A�S�`�����l���� x 1���� 
% chanMap     : �`�����l���ԍ��A�S�`�����l���� x 1�����i�ϐ���logical�j
% chanMap0ind : �`�����l���ԍ� -1�A�S�`�����l���� x 1���� 
% connected   : �`�����l�����g�����ǂ����A�S�`�����l���� x 1���� 
% name        : ���̃t�@�C���̂��߂̖��O�ŁA���ł��悢�B


Xml = LoadXml('amplifier.xml'); % �x�[�X�ƂȂ�xml�t�@�C����ǂݍ���

name = 's57map';

chanMap = [1:Xml.nChannels]';
chanMap0ind = chanMap-1;

xcoords =   nan(size(chanMap));
ycoords =   nan(size(chanMap));
kcoords =   nan(size(chanMap));
connected = zeros(size(chanMap));

shanks_for_analysis = [1:6,8:13,15:22]; % AnatGrps �ŁA��͂Ɏg�������V�����N�ԍ����w��B
                            
for ishank = 1:length(shanks_for_analysis)
    channels_in_the_shank = Xml.AnatGrps(shanks_for_analysis(ishank)).Channels + 1; % xml�ł̓C���f�b�N�X��0����n�܂�
    nchan_shank = length(channels_in_the_shank);
    for ichan = 1:nchan_shank
        mychan = channels_in_the_shank(ichan);
        
        % Buzsaki probe �̔z��
        xcoords(mychan,1) = (2*rem(ichan,2)-1) * 5 * (nchan_shank-ichan) ... % 5��m���ƁB����ƕ����𔽓]�B
                            + 1000 * ishank;                            % �V�����N�Ԋu�B�{��200��m�����Ǒ傫�߂ɂƂ�
        ycoords(mychan,1) = -1 * ichan * 20;                            % 20��m���ƁB 
        kcoords(mychan,1) = ishank;
        
        connected(mychan,1) = 1;
    end
    clear channels_in_the_shank nchan_shan ichan mychan 
end
clear ishank shanks_for_analysis

connected = logical(connected);

figure
plot(xcoords,ycoords,'linestyle','none','marker','o')

save([name,'_kilosortChanMap'],'chanMap', 'chanMap0ind', 'xcoords', 'ycoords', 'kcoords', 'connected', 'name')

% �ȏ�����O�����Ƃ��Ă���Ă����A"kilosort" �� kilosort2 GUI �𗧂��グ��
% Select probe layout �� "other" ��I�ԂƁA�t�@�C�����ǂݍ��߂�B

%%
%
%  GUI ���g��Ȃ�����
%

% GUI ���g���ƁA�p�����[�^���������ɂ����B

% (1) configFile.m ���쐬�B�i�e���v���[�g��kilosort2�̃t�H���_�ɂ���B�j
% ���d�v�ȃp�����[�^��
% ops.chanMap =' D:\s49_06\s49map_kilosortChanMap.mat';    % ��ō����ChnMap�t�@�C��
% ops.fs = 20000;                                           % �T���v�����O���[�g
% ops.minfr_goodchannels = 0; �@�@�@�@�@�@�@�@�@�@�@�@�@�@�@% �`�����l��������ɏ��O����Ȃ�����

% (2) master_kilosort.m ���쐬�B�i�e���v���[�g��kilosort2�̃t�H���_�ɂ���B�j

% (3) master_kilosort.m �𑖂点��B
run('master_kilosort_s51.m')

%%
%
%  Phy2 �� shank �����g��
%

%  Phy2 �ŃV�����N�����g�������ꍇ�A�ɂ���
%  rez.mat�Ɠ����t�H���_�ɁAchannel��shank�̑Ή���������channel_shanks.npy�������
%  phy�N�����Ɏ����I�ɓǂݍ��܂��


load('s51map_kilosortChanMap', 'kcoords')
kcoords_for_phy2 = kcoords(find(kcoords>0));

currentFolder = pwd;
writeNPY(rez.ops.kcoords, fullfile(currentFolder, 'channel_shanks.npy'));

% anaconda��ňȉ������s����Ύ����I�ɓǂݍ��܂��
activate phy2
cd XXXXXXX
phy template-gui params.py

%%
%
%  �N���X�^�����O�ς݃t�@�C���̓ǂݍ���
%

cluster_group = tdfread('cluster_group.tsv');
cells = cluster_group.cluster_id(cluster_group.group(:,1)=='g') + 1 % Phy�ł̓C���f�b�N�X��0����n�܂�

cluster_info =  tdfread('cluster_info.tsv');
cells_shank  =  cluster_info.shank(cluster_group.group(:,1)=='g');

spiket = rez.st3(:,1);
spikeind = rez.st3(:,2);

[~,myidx] = sort(cells_shank,'ascend');
cells       = cells(myidx)
cells_shank = cells_shank(myidx)

%%

% [PlaceMap, OccupancyMap] = PlaceField(Res, Whl, EnvSize, Smooth, nGrid, Dir, TopRate)

figure

for ii = 1:length(cells)
    PlaceField(spiket(spikeind==cells(ii)) , whl, 720, 10, 720);
    [cells(ii), cells_shank(ii)]
    input('')
end

[spiketA,spikeindA] = SpikeSection (spiket,spikeind,direct12);
[spiketB,spikeindB] = SpikeSection (spiket,spikeind,direct21);

whlA = WhlSection (whlt,whl,direct12);
whlB = WhlSection (whlt,whl,direct21);

for ii = 1:length(cells)
    subplot(1,3,1)
    PlaceField(spiket(spikeind==cells(ii)) , whl, 720, 10, 720);
    subplot(1,3,2)
    PlaceField(spiketA(spikeindA==cells(ii)) , whlA, 720, 10, 720);
    subplot(1,3,3)
    PlaceField(spiketB(spikeindB==cells(ii)) , whlB, 720, 10, 720);
    
    [cells(ii), cells_shank(ii)]
    input('')
end


whldA = WhlSection1d (whlt,whl,direct12);
whldB = WhlSection1d (whlt,whl,direct21);
spikedA = interp1(whlt,whldA(:,5),spiketA);
spikedB = interp1(whlt,whldB(:,5),spiketB);
%%
%
%  Theta 
%

fileName = 'amplifier.dat';

bytesPerSamp = 2;               % int16�̏ꍇ�A2 bytes/sample
Nchan = 128;                      % Channel��
b = get_file_size(fileName);    % �t�@�C���̃T�C�Y���擾�B
nSamples = b/bytesPerSamp/Nchan;

mmf = memmapfile(fileName,'Format',{'int16',[Nchan nSamples],'x'});

% ����ŁAmmf.Data.x(<channels>, <samplepoints>) �ŁA�f�[�^�𕁒ʂ̔z��̂悤�Ɏg����B

myCh = 61;

Eeg = downsample(mmf.Data.x(myCh,:), 16);
Eeg = cast(Eeg,'double');

[thetaPhase,thetaAmp,totPhase,filtEeg] = ThetaPhase(Eeg, [4,10]);

%%%
eegt = 16*[1:length(Eeg)]; 

spikephaseA = interp1(eegt, totPhase, spiketA);
spikephaseA = rem(spikephaseA, 2*pi);
spikephaseB = interp1(eegt, totPhase, spiketB);
spikephaseB = rem(spikephaseB, 2*pi);
%%%

figure
for ii = 1:length(cells)
 
    subplot(2,2,3)
    myfind = find(spikeindA==cells(ii));
    plot(spikedA(myfind),spikephaseA(myfind),'linestyle','none','marker','.','markersize',4)
    subplot(2,2,4)
    myfind = find(spikeindB==cells(ii));
    plot(-1*spikedB(myfind),spikephaseB(myfind),'linestyle','none','marker','.','markersize',4)
    
    subplot(2,2,1)
    PlaceField(spiketA(spikeindA==cells(ii)) , whlA, 720, 10, 720);
    subplot(2,2,2)
    PlaceField(spiketB(spikeindB==cells(ii)) , whlB, 720, 10, 720);
    
    [cells(ii), cells_shank(ii)]
    input('')
end


[spike_atime, spike_trial, spike_type] = SpikeStampsConfigral(spiket, b1, b2);

mycell = 43;

myfind1 = find(spikeind == mycell & spike_atime >=0 & spike_atime <=8 & spike_type == 1);
myfind2 = find(spikeind == mycell & spike_atime >=0 & spike_atime <=8 & spike_type == 2);


spikePhase2 = interp1(eegt, totPhase, spiket(myfind2));
spikePhase2 = rem(spikePhase2, 2*pi);

figure
plot(spike_atime(myfind1), spikePhase1,'linestyle','none','marker','.','markersize',4, 'color','r');hold on
plot(spike_atime(myfind2), spikePhase2,'linestyle','none','marker','.','markersize',4, 'color','b');
 

