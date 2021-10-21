
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%                   kilosort2 chanMap について
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 必要なもの
% 
% xcoords     : ⅹ座標、全チャンネル数 x 1次元 
% ycoords     : ｙ座標、全チャンネル数 x 1次元
% kcoords     : シャンク、全チャンネル数 x 1次元 
% chanMap     : チャンネル番号、全チャンネル数 x 1次元（変数はlogical）
% chanMap0ind : チャンネル番号 -1、全チャンネル数 x 1次元 
% connected   : チャンネルを使うかどうか、全チャンネル数 x 1次元 
% name        : このファイルのための名前で、何でもよい。


Xml = LoadXml('amplifier.xml'); % ベースとなるxmlファイルを読み込む

name = 's57map';

chanMap = [1:Xml.nChannels]';
chanMap0ind = chanMap-1;

xcoords =   nan(size(chanMap));
ycoords =   nan(size(chanMap));
kcoords =   nan(size(chanMap));
connected = zeros(size(chanMap));

shanks_for_analysis = [1:6,8:13,15:22]; % AnatGrps で、解析に使いたいシャンク番号を指定。
                            
for ishank = 1:length(shanks_for_analysis)
    channels_in_the_shank = Xml.AnatGrps(shanks_for_analysis(ishank)).Channels + 1; % xmlではインデックスが0から始まる
    nchan_shank = length(channels_in_the_shank);
    for ichan = 1:nchan_shank
        mychan = channels_in_the_shank(ichan);
        
        % Buzsaki probe の配列
        xcoords(mychan,1) = (2*rem(ichan,2)-1) * 5 * (nchan_shank-ichan) ... % 5μmごと。奇数だと符号を反転。
                            + 1000 * ishank;                            % シャンク間隔。本来200μmだけど大きめにとる
        ycoords(mychan,1) = -1 * ichan * 20;                            % 20μmごと。 
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

% 以上を事前準備としてやっておき、"kilosort" で kilosort2 GUI を立ち上げる
% Select probe layout で "other" を選ぶと、ファイルが読み込める。

%%
%
%  GUI を使わないやり方
%

% GUI を使うと、パラメータ調整がやりにくい。

% (1) configFile.m を作成。（テンプレートはkilosort2のフォルダにある。）
% ＜重要なパラメータ＞
% ops.chanMap =' D:\s49_06\s49map_kilosortChanMap.mat';    % 上で作ったChnMapファイル
% ops.fs = 20000;                                           % サンプリングレート
% ops.minfr_goodchannels = 0; 　　　　　　　　　　　　　　　% チャンネルが勝手に除外されないため

% (2) master_kilosort.m を作成。（テンプレートはkilosort2のフォルダにある。）

% (3) master_kilosort.m を走らせる。
run('master_kilosort_s51.m')

%%
%
%  Phy2 で shank 情報を使う
%

%  Phy2 でシャンク情報を使いたい場合、について
%  rez.matと同じフォルダに、channelとshankの対応を示したchannel_shanks.npyがあれば
%  phy起動時に自動的に読み込まれる


load('s51map_kilosortChanMap', 'kcoords')
kcoords_for_phy2 = kcoords(find(kcoords>0));

currentFolder = pwd;
writeNPY(rez.ops.kcoords, fullfile(currentFolder, 'channel_shanks.npy'));

% anaconda上で以下を実行すれば自動的に読み込まれる
activate phy2
cd XXXXXXX
phy template-gui params.py

%%
%
%  クラスタリング済みファイルの読み込み
%

cluster_group = tdfread('cluster_group.tsv');
cells = cluster_group.cluster_id(cluster_group.group(:,1)=='g') + 1 % Phyではインデックスは0から始まる

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

bytesPerSamp = 2;               % int16の場合、2 bytes/sample
Nchan = 128;                      % Channel数
b = get_file_size(fileName);    % ファイルのサイズを取得。
nSamples = b/bytesPerSamp/Nchan;

mmf = memmapfile(fileName,'Format',{'int16',[Nchan nSamples],'x'});

% これで、mmf.Data.x(<channels>, <samplepoints>) で、データを普通の配列のように使える。

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
 

