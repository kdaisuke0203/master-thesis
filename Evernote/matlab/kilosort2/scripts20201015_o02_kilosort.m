
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

name = 'o02map';

chanMap = [1:Xml.nChannels]';
chanMap0ind = chanMap-1;

xcoords =   nan(size(chanMap));
ycoords =   nan(size(chanMap));
kcoords =   nan(size(chanMap));
connected = zeros(size(chanMap));

shanks_for_analysis = [1:16]; % AnatGrps �ŁA��͂Ɏg�������V�����N�ԍ����w��B
                            
for ishank = 1:length(shanks_for_analysis)
    channels_in_the_shank = Xml.AnatGrps(shanks_for_analysis(ishank)).Channels + 1; % xml�ł̓C���f�b�N�X��0����n�܂�
    nchan_shank = length(channels_in_the_shank);
    for ichan = 1:nchan_shank
        mychan = channels_in_the_shank(ichan);
        
        % Buzsaki probe �̔z��
        xcoords(mychan,1) = rem(ichan,2) * (-15) ...     % ���E15��m�Ԋu�B
                            + 1000 * ishank;             % �V�����N�Ԋu�B�{��100��m�����Ǒ傫�߂ɂƂ�
        ycoords(mychan,1) = -1 * ichan * 30;             % ���30��m���ƁB 
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
run('master_kilosort_o02.m')

%%
%
%  Phy2 �� shank �����g��
%

%  Phy2 �ŃV�����N�����g�������ꍇ�A�ɂ���
%  rez.mat�Ɠ����t�H���_�ɁAchannel��shank�̑Ή���������channel_shanks.npy�������
%  phy�N�����Ɏ����I�ɓǂݍ��܂��


load('o02map_kilosortChanMap', 'kcoords')
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
%
% DI loading for Intan Recording System

fileName = 'digitalin.dat';

bytesPerSamp = 2;               % int16�̏ꍇ�A2 bytes/sample
Nchan = 1;                      % Channel��
b = get_file_size(fileName);    % �t�@�C���̃T�C�Y���擾�B
nSamples = b/bytesPerSamp/Nchan;

mmf = memmapfile(fileName,'Format',{'int16',[Nchan nSamples],'x'});
% �t�@�C���𒼐ڃ��[�h�����ɁA��������̃A�h���X�����擾�B��������Ƌ���t�@�C�����y��������B
% mmf.Data.x(<channels>, <samplepoints>) �ŁA�f�[�^�𕁒ʂ̔z��̂悤�Ɏg����B
% bload(['digitalin.dat'],[1,inf], 0,'short',0); �Ɠ��`�B

DIs =  de2bi(mmf.Data.x);
% 16�r�b�g��1��̏���10�i����16��ɕϊ��B

% plot(DIs(:,1))
%   DI Channel1�iLight�j���v���b�g

% �V�O�i���̃I���Z�b�g���Ԃ̌��o (0 --> 1 �̓_�����o�@=�@[0 1]�̕���������o)
Sync    = strfind(DIs(:,1)',[0 1])' + 1; 
Reward  = strfind(DIs(:,2)',[0 1])' + 1; 


%%
%
% DeepLabCut �f�[�^����̈ʒu�������킹��

dlcdata = csvread('s62_20201001DLC_resnet50_s62Sep28shuffle1_200000.csv',3,0);

length(Sync)==length(dlcdata)

th_jump = 50;
th_conf = 0.5;
x_border = 360;
%%% Rat1
% Head���F��ђl�����O���āA���}����
dist1 = sqrt(diff(dlcdata(:,2)).^2 + diff(dlcdata(:,3)).^2);
dist1 = [0;dist1];
  %figure, histogram(dist1), set(gca,'ylim',[0,5])
dlc1 = dlcdata(:,1:3);
dlc1(dist1>th_jump | dlcdata(:,2)<x_border ,:) = [];
 %dlc1(dist1>th_jump | dlcdata(:,4)<th_conf ,:) = [];
dlc1interp = interp1(dlc1(:,1),dlc1(:,2:3),dlcdata(:,1));

% Tail���F��ђl�����O���āA���}����
dist2 = sqrt(diff(dlcdata(:,5)).^2 + diff(dlcdata(:,6)).^2);
dist2 = [0;dist2];
  %figure, histogram(dist1), set(gca,'ylim',[0,5])
dlc2 = dlcdata(:,[1,5,6]);
dlc2(dist2>th_jump | dlcdata(:,5)<x_border ,:) = [];
 %dlc2(dist2>th_jump | dlcdata(:,7)<th_conf ,:) = [];
dlc2interp = interp1(dlc2(:,1),dlc2(:,2:3),dlcdata(:,1));

%%% Rat2
% Head���F��ђl�����O���āA���}����
dist3 = sqrt(diff(dlcdata(:,8)).^2 + diff(dlcdata(:,9)).^2);
dist3 = [0;dist3];
  %figure, histogram(dist1), set(gca,'ylim',[0,5])
dlc3 = dlcdata(:,[1,8,9]);
dlc3(dist3>th_jump  | dlcdata(:,8)>x_border,:) = [];
 %dlc3(dist3>th_jump | dlcdata(:,10)<th_conf ,:) = [];
dlc3interp = interp1(dlc3(:,1),dlc3(:,2:3),dlcdata(:,1));

% Tail���F��ђl�����O���āA���}����
dist4 = sqrt(diff(dlcdata(:,10)).^2 + diff(dlcdata(:,11)).^2);
dist4 = [0;dist4];
  %figure, histogram(dist1), set(gca,'ylim',[0,5])
dlc4 = dlcdata(:,[1,11,12]);
dlc4(dist4>th_jump  | dlcdata(:,10)>x_border,:) = [];
 %dlc4(dist4>th_jump | dlcdata(:,13)<th_conf ,:) = [];
dlc4interp = interp1(dlc4(:,1),dlc4(:,2:3),dlcdata(:,1));

figure
plot(dlc1interp(:,1),dlc1interp(:,2), '.');hold on
plot(dlc3interp(:,1),dlc3interp(:,2), '.');hold off

dlc = [dlc1interp, dlc2interp, dlc3interp, dlc4interp];

whlt = [0:512:(length(DIs)-1)];

whl = interp1(Sync, dlc, whlt);

figure, plot(whl(:,1),whl(:,2),whl(:,5),whl(:,6))



%%
%
% Place Fields

[PlaceMap, OccupancyMap] = PlaceField(Res, Whl, EnvSize, Smooth, nGrid, Dir, TopRate)

figure
for ii = 1:length(cells)
    PlaceField(spiket(spikeind==cells(ii)) , whl(:,1:2), 720, 10, 720);
    [cells(ii), cells_shank(ii)]
    input('')
end

%%
%
% Social Place Fields

% head direction vector
hdv1 = [whl(:,3)-whl(:,1), whl(:,4)-whl(:,2)]; % rat 1
hdv2 = [whl(:,7)-whl(:,5), whl(:,8)-whl(:,6)]; % rat 2

costheta = (hdv1(:,1).* hdv2(:,1) + hdv1(:,2).* hdv2(:,2))./ ...
            (sqrt(hdv1(:,1).^2 + hdv1(:,2).^2).* sqrt(hdv2(:,1).^2 + hdv2(:,2).^2)); % ����
sinetheta = (hdv1(:,1).* hdv2(:,2) - hdv1(:,2).* hdv2(:,1))./ ...
            (sqrt(hdv1(:,1).^2 + hdv1(:,2).^2).* sqrt(hdv2(:,1).^2 + hdv2(:,2).^2)); % �O�� 
        
%hd_angle = acos(costheta);

% distance between 2 rats
dist12 = sqrt((whl(:,1) - whl(:,5)).^2 + (whl(:,2) - whl(:,6)).^2);

% �Ƃ肠�����ȈՔŁB
whl_sr = [dist12.*costheta, dist12.*sinetheta]; % spatial relationships between two heads

figure
for ii = 1:length(cells)
    PlaceField(spiket(spikeind==cells(ii)) , [whl_sr(:,1)+500,whl_sr(:,2)+500], 1000, 10, 1000);
    [cells(ii), cells_shank(ii)]
    input('')
end




