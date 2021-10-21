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

%  1: Sync
%  2: Sensor 1
%  3: Sensor 2

% シグナルのオンセット時間の検出 (0 --> 1 の点を検出　=　[0 1]の文字列を検出)
Sync    = strfind(DIs(:,1)',[0 1])' + 1; 
Sensor1 = strfind(DIs(:,2)',[0 1])' + 1; 
Sensor2 = strfind(DIs(:,3)',[0 1])' + 1; 

%%
%
% DeepLabCut データからの位置情報を合わせる

dlcdata = csvread('s62_20201001DLC_resnet50_s62Sep28shuffle1_200000.csv',3,0);

length(Sync)==length(dlcdata)

% Head側：飛び値を除外して、内挿する
dist1 = sqrt(diff(dlcdata(:,2)).^2 + diff(dlcdata(:,3)).^2);
dist1 = [0;dist1];
  %figure, histogram(dist1), set(gca,'ylim',[0,5])
dlc1 = dlcdata(:,1:3);
dlc1(dist1>50,:) = [];
dlc1interp = interp1(dlc1(:,1),dlc1(:,2:3),dlcdata(:,1));

% Tail側：飛び値を除外して、内挿する
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

% DIと同様に、生データファイルも読み込める。

fileName = 'amplifier.dat';

bytesPerSamp = 2;               % int16の場合、2 bytes/sample
Nchan = 128;                    % Channel数。s49の場合。
b = get_file_size(fileName);    % ファイルのサイズを取得。
nSamples = b/bytesPerSamp/Nchan;

mmf = memmapfile(fileName,'Format',{'int16',[Nchan nSamples],'x'});
% これで、mmf.Data.x(<channels>, <samplepoints>) で、データを普通の配列のように使える。
% この時点では、20KHz 128ch の全データ

myCh = 14; % 自分が見たいチェンネルを選ぶ。（Neuroscopeチェンネル＋１）

Eeg = downsample(mmf.Data.x(myCh,:), 16);
Eeg = cast(Eeg,'double');
% これで選択したチャンネルの1250HzのEEG波形が取り出せた。


