%%
%
%  クラスタリング済みファイルの読み込み
%

cluster_group = tdfread('cluster_group.tsv');
cells = cluster_group.cluster_id(cluster_group.group(:,1)=='g') + 1 % Phyではインデックスは0から始まる

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
Sync14 = strfind(DIs(:,1)',[0 1])' + 1; 
%Sensor1 = strfind(DIs(:,2)',[0 1])' + 1; 
%Sensor2 = strfind(DIs(:,3)',[0 1])' + 1; 


%%
%
% DeepLabCut データからの位置情報を合わせる

csvlist = dir('*.csv');

dlcdata = csvread(csvlist(1).name,3,0); % CSVファイルが1つしかない場合

%　あるいはそのままファイル名を入れてもよい
%  dlcdata = csvread('o09_20210315_121122_cam1DLC_resnet50_omergel_2Mar18shuffle1_400000.csv',3,0);

% 同じ長さかチェック
[length(Sync1), length(dlcdata)]

whlt = [0:512:(length(DIs)-1)];

figure
[whl1] = make_whl_two_rats(dlcdata, whlt, Sync1);

%%
%
% whl の作成
%
% とりあえず簡易版。将来関数化。
% dlcdataは、２点取得の場合、７列（[frame stamp, x1, y1, conf1, x2, y2, conf2])

% Head側：良い点を選ぶ
In   = ClusterPoints([dlcdata(:,2), dlcdata(:,3)],1);
%
dlc1 = dlcdata(:,2:3);
dlc1(In==0 | dlcdata(:,4)<0.5, :) = NaN;

% Tail側：良い点を選ぶ
In   = ClusterPoints([dlcdata(:,5), dlcdata(:,6)],1);
% 飛び値を除外して、内挿する
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












