%%
%
%  �N���X�^�����O�ς݃t�@�C���̓ǂݍ���
%

cluster_group = tdfread('cluster_group.tsv');
cells = cluster_group.cluster_id(cluster_group.group(:,1)=='g') + 1 % Phy�ł̓C���f�b�N�X��0����n�܂�

cluster_info =  tdfread('cluster_info.tsv');
cells_shank  =  cluster_info.sh(cluster_group.group(:,1)=='g');

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
Sync14 = strfind(DIs(:,1)',[0 1])' + 1; 
%Sensor1 = strfind(DIs(:,2)',[0 1])' + 1; 
%Sensor2 = strfind(DIs(:,3)',[0 1])' + 1; 


%%
%
% DeepLabCut �f�[�^����̈ʒu�������킹��

csvlist = dir('*.csv');

dlcdata = csvread(csvlist(1).name,3,0); % CSV�t�@�C����1�����Ȃ��ꍇ

%�@���邢�͂��̂܂܃t�@�C���������Ă��悢
%  dlcdata = csvread('o09_20210315_121122_cam1DLC_resnet50_omergel_2Mar18shuffle1_400000.csv',3,0);

% �����������`�F�b�N
[length(Sync1), length(dlcdata)]

whlt = [0:512:(length(DIs)-1)];

figure
[whl1] = make_whl_two_rats(dlcdata, whlt, Sync1);

%%
%
% whl �̍쐬
%
% �Ƃ肠�����ȈՔŁB�����֐����B
% dlcdata�́A�Q�_�擾�̏ꍇ�A�V��i[frame stamp, x1, y1, conf1, x2, y2, conf2])

% Head���F�ǂ��_��I��
In   = ClusterPoints([dlcdata(:,2), dlcdata(:,3)],1);
%
dlc1 = dlcdata(:,2:3);
dlc1(In==0 | dlcdata(:,4)<0.5, :) = NaN;

% Tail���F�ǂ��_��I��
In   = ClusterPoints([dlcdata(:,5), dlcdata(:,6)],1);
% ��ђl�����O���āA���}����
dlc2 = dlcdata(:,[5,6]);
dlc2(In==0 | dlcdata(:,7)<0.5, :) = NaN;

% figure
% plot(dlc1(:,1),dlc1(:,2), '.');hold on
% plot(dlc3(:,1),dlc3(:,2), '.');hold off

dlc = [dlc1, dlc2, dlc3, dlc4];

whl = interp1(Sync, dlc, whlt);

plot(whl(:,1),whl(:,2),'.',whl(:,3),whl(:,4),'.')


%%
%
% Place fields

for ii = 1:length(cells)

    PlaceField(spiket(spikeind==cells(ii)) , whl, 720, 10, 720);
    
    [cells(ii), cells_shank(ii)]
    input('')
end












