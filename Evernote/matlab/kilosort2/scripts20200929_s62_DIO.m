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

%  1: Sync
%  2: Sensor 1
%  3: Sensor 2

% �V�O�i���̃I���Z�b�g���Ԃ̌��o (0 --> 1 �̓_�����o�@=�@[0 1]�̕���������o)
Sync    = strfind(DIs(:,1)',[0 1])' + 1; 
Sensor1 = strfind(DIs(:,2)',[0 1])' + 1; 
Sensor2 = strfind(DIs(:,3)',[0 1])' + 1; 

%%
%
% DeepLabCut �f�[�^����̈ʒu�������킹��

dlcdata = csvread('s62_20201001DLC_resnet50_s62Sep28shuffle1_200000.csv',3,0);

length(Sync)==length(dlcdata)

% Head���F��ђl�����O���āA���}����
dist1 = sqrt(diff(dlcdata(:,2)).^2 + diff(dlcdata(:,3)).^2);
dist1 = [0;dist1];
  %figure, histogram(dist1), set(gca,'ylim',[0,5])
dlc1 = dlcdata(:,1:3);
dlc1(dist1>50,:) = [];
dlc1interp = interp1(dlc1(:,1),dlc1(:,2:3),dlcdata(:,1));

% Tail���F��ђl�����O���āA���}����
dist2 = sqrt(diff(dlcdata(:,5)).^2 + diff(dlcdata(:,6)).^2);
dist2 = [0;dist2];
  %figure, histogram(dist1), set(gca,'ylim',[0,5])
dlc2 = dlcdata(:,[1,5,6]);
dlc2(dist2>50,:) = [];
dlc2interp = interp1(dlc2(:,1),dlc2(:,2:3),dlcdata(:,1));

dlc = [dlc1interp, dlc2interp];

whlt = [0:512:(length(DIs)-1)];

whl = interp1(Sync, dlc, whlt);

figure, plot(whl(:,1),whl(:,2),whl(:,3),whl(:,4))

%%

Sensor12 = [Sensor1, 1*ones(size(Sensor1)); Sensor2, 2*ones(size(Sensor2))];
[~,index12]  = sort(Sensor12(:,1),'ascend');
Sensor12 = Sensor12(index12,:);

jj = 0; kk = 0;
clear direct12 direct21
for ii=1:length(Sensor12)-1
    if Sensor12(ii,2) == 1 && Sensor12(ii+1,2) == 2
        jj=jj+1;
        direct12(jj,:) = [Sensor12(ii,1), Sensor12(ii+1,1)];
    elseif Sensor12(ii,2) == 2 && Sensor12(ii+1,2) == 1
        kk=kk+1;
        direct21(kk,:) = [Sensor12(ii,1), Sensor12(ii+1,1)];
    end
end


%%
%
% Law data loading for Intan Recording System

% DI�Ɠ��l�ɁA���f�[�^�t�@�C�����ǂݍ��߂�B

fileName = 'amplifier.dat';

bytesPerSamp = 2;               % int16�̏ꍇ�A2 bytes/sample
Nchan = 128;                    % Channel���Bs49�̏ꍇ�B
b = get_file_size(fileName);    % �t�@�C���̃T�C�Y���擾�B
nSamples = b/bytesPerSamp/Nchan;

mmf = memmapfile(fileName,'Format',{'int16',[Nchan nSamples],'x'});
% ����ŁAmmf.Data.x(<channels>, <samplepoints>) �ŁA�f�[�^�𕁒ʂ̔z��̂悤�Ɏg����B
% ���̎��_�ł́A20KHz 128ch �̑S�f�[�^

myCh = 14; % �������������`�F���l����I�ԁB�iNeuroscope�`�F���l���{�P�j

Eeg = downsample(mmf.Data.x(myCh,:), 16);
Eeg = cast(Eeg,'double');
% ����őI�������`�����l����1250Hz��EEG�g�`�����o�����B


