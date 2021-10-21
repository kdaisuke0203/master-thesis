
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

name = 'o02map';

chanMap = [1:Xml.nChannels]';
chanMap0ind = chanMap-1;

xcoords =   nan(size(chanMap));
ycoords =   nan(size(chanMap));
kcoords =   nan(size(chanMap));
connected = zeros(size(chanMap));

shanks_for_analysis = [1:16]; % AnatGrps で、解析に使いたいシャンク番号を指定。
                            
for ishank = 1:length(shanks_for_analysis)
    channels_in_the_shank = Xml.AnatGrps(shanks_for_analysis(ishank)).Channels + 1; % xmlではインデックスが0から始まる
    nchan_shank = length(channels_in_the_shank);
    for ichan = 1:nchan_shank
        mychan = channels_in_the_shank(ichan);
        
        % Buzsaki probe の配列
        xcoords(mychan,1) = rem(ichan,2) * (-15) ...     % 左右15μm間隔。
                            + 1000 * ishank;             % シャンク間隔。本来100μmだけど大きめにとる
        ycoords(mychan,1) = -1 * ichan * 30;             % 上限30μmごと。 
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
run('master_kilosort_o02.m')

%%
%
%  Phy2 で shank 情報を使う
%

%  Phy2 でシャンク情報を使いたい場合、について
%  rez.matと同じフォルダに、channelとshankの対応を示したchannel_shanks.npyがあれば
%  phy起動時に自動的に読み込まれる


load('o02map_kilosortChanMap', 'kcoords')
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
%
% DI loading for Intan Recording System

fileName = 'digitalin.dat';

bytesPerSamp = 2;               % int16の場合、2 bytes/sample
Nchan = 1;                      % Channel数
b = get_file_size(fileName);    % ファイルのサイズを取得。
nSamples = b/bytesPerSamp/Nchan;

mmf = memmapfile(fileName,'Format',{'int16',[Nchan nSamples],'x'});
% ファイルを直接ロードせずに、メモリ上のアドレスだけ取得。こうすると巨大ファイルを軽く扱える。
% mmf.Data.x(<channels>, <samplepoints>) で、データを普通の配列のように使える。
% bload(['digitalin.dat'],[1,inf], 0,'short',0); と同義。

DIs =  de2bi(mmf.Data.x);
% 16ビットｘ1列の情報を10進数ｘ16列に変換。

% plot(DIs(:,1))
%   DI Channel1（Light）をプロット

% シグナルのオンセット時間の検出 (0 --> 1 の点を検出　=　[0 1]の文字列を検出)
Sync    = strfind(DIs(:,1)',[0 1])' + 1; 
Reward  = strfind(DIs(:,2)',[0 1])' + 1; 


%%
%
% DeepLabCut データからの位置情報を合わせる

dlcdata = csvread('s62_20201001DLC_resnet50_s62Sep28shuffle1_200000.csv',3,0);

length(Sync)==length(dlcdata)

th_jump = 50;
th_conf = 0.5;
x_border = 360;
%%% Rat1
% Head側：飛び値を除外して、内挿する
dist1 = sqrt(diff(dlcdata(:,2)).^2 + diff(dlcdata(:,3)).^2);
dist1 = [0;dist1];
  %figure, histogram(dist1), set(gca,'ylim',[0,5])
dlc1 = dlcdata(:,1:3);
dlc1(dist1>th_jump | dlcdata(:,2)<x_border ,:) = [];
 %dlc1(dist1>th_jump | dlcdata(:,4)<th_conf ,:) = [];
dlc1interp = interp1(dlc1(:,1),dlc1(:,2:3),dlcdata(:,1));

% Tail側：飛び値を除外して、内挿する
dist2 = sqrt(diff(dlcdata(:,5)).^2 + diff(dlcdata(:,6)).^2);
dist2 = [0;dist2];
  %figure, histogram(dist1), set(gca,'ylim',[0,5])
dlc2 = dlcdata(:,[1,5,6]);
dlc2(dist2>th_jump | dlcdata(:,5)<x_border ,:) = [];
 %dlc2(dist2>th_jump | dlcdata(:,7)<th_conf ,:) = [];
dlc2interp = interp1(dlc2(:,1),dlc2(:,2:3),dlcdata(:,1));

%%% Rat2
% Head側：飛び値を除外して、内挿する
dist3 = sqrt(diff(dlcdata(:,8)).^2 + diff(dlcdata(:,9)).^2);
dist3 = [0;dist3];
  %figure, histogram(dist1), set(gca,'ylim',[0,5])
dlc3 = dlcdata(:,[1,8,9]);
dlc3(dist3>th_jump  | dlcdata(:,8)>x_border,:) = [];
 %dlc3(dist3>th_jump | dlcdata(:,10)<th_conf ,:) = [];
dlc3interp = interp1(dlc3(:,1),dlc3(:,2:3),dlcdata(:,1));

% Tail側：飛び値を除外して、内挿する
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
            (sqrt(hdv1(:,1).^2 + hdv1(:,2).^2).* sqrt(hdv2(:,1).^2 + hdv2(:,2).^2)); % 内積
sinetheta = (hdv1(:,1).* hdv2(:,2) - hdv1(:,2).* hdv2(:,1))./ ...
            (sqrt(hdv1(:,1).^2 + hdv1(:,2).^2).* sqrt(hdv2(:,1).^2 + hdv2(:,2).^2)); % 外積 
        
%hd_angle = acos(costheta);

% distance between 2 rats
dist12 = sqrt((whl(:,1) - whl(:,5)).^2 + (whl(:,2) - whl(:,6)).^2);

% とりあえず簡易版。
whl_sr = [dist12.*costheta, dist12.*sinetheta]; % spatial relationships between two heads

figure
for ii = 1:length(cells)
    PlaceField(spiket(spikeind==cells(ii)) , [whl_sr(:,1)+500,whl_sr(:,2)+500], 1000, 10, 1000);
    [cells(ii), cells_shank(ii)]
    input('')
end




