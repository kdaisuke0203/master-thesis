% function make_Xml_from_Excel(fileBase, sampling_rate, multi_colors)
%
%  This function will generate fileBase.xml file for Neuroscope.
%    Prepare fileBase.xlsx file for the channel map (channel# should start from 1, not 0).
%    Each row should contain channels in each shank.
%    It works even if the numbers of the channels are different across shanks.
%    (Just make cells empity in the shanks of smaller numbers of channels.)
%
%  fileBase      : the base name of the files (for .xml and .xlsx).
%  sampling_rate : sampling rate (default = 20000)
%  multi_colors  : if 1, use different colors across shanks (default = 1). 
%
%  by Shigeyoshi Fujisawa, 2020/02/26
%

function make_Xml_from_Excel(fileBase, sampling_rate, multi_colors)

if nargin < 2
    sampling_rate = 20000;
end

if nargin < 3
    multi_colors = 1;
end

    %% Read channel data from Excel file

    ChannelTable  = readtable([fileBase,'.xlsx'],'ReadVariableNames',false);
    ChannelMatrix = ChannelTable.Variables;
    nGroups       = size(ChannelMatrix,1);
    totalChannels = max(ChannelMatrix(~isnan(ChannelMatrix)));  

    colorSamples{1} = ['#0000ff']; % blue
    colorSamples{2} = ['#00bfff']; % deepskyblue
    colorSamples{3} = ['#00ff7f']; % springgreen
    colorSamples{4} = ['#f0e68c']; % khaki
    colorSamples{5} = ['#ffa500']; % orange
    colorSamples{6} = ['#ff4500']; % orangered
    colorSamples{7} = ['#ff00ff']; % magenta
    colorSamples{8} = ['#8a2be2']; % blueviolet
    

    %% Contents of Xml file (Parameters)
    % see, https://jp.mathworks.com/help/matlab/ref/xmlwrite.html
    
    docNode    = com.mathworks.xml.XMLUtils.createDocument('parameters');

    parameters = docNode.getDocumentElement;
    parameters.setAttribute('version','1.0');

      %%% generalInfo
      generalInfo = docNode.createElement('generalInfo');
      parameters.appendChild(generalInfo);

        dateinfo = docNode.createElement('date');
        date_num = clock; % today's date
        date_str = [num2str(date_num(1)), '-', num2str(date_num(2)), '-', num2str(date_num(3))];
        dateinfo.appendChild(docNode.createTextNode(date_str)); 
        generalInfo.appendChild(dateinfo);

        experimentalists = docNode.createElement('experimentalists');
        experimentalists.appendChild(docNode.createTextNode(''));
        generalInfo.appendChild(experimentalists);

        description = docNode.createElement('description');
        description.appendChild(docNode.createTextNode(''));
        generalInfo.appendChild(description);

        notes = docNode.createElement('notes');
        notes.appendChild(docNode.createTextNode(''));
        generalInfo.appendChild(notes);

      %%% acquisitionSystem
      acquisitionSystem = docNode.createElement('acquisitionSystem');
      parameters.appendChild(acquisitionSystem);

        nBits = docNode.createElement('nBits');
        nBits.appendChild(docNode.createTextNode('16'));  %%%  Bits
        acquisitionSystem.appendChild(nBits);

        nChannels = docNode.createElement('nChannels');
        nChannels.appendChild(docNode.createTextNode(num2str(totalChannels)));  %%%  nChannels
        acquisitionSystem.appendChild(nChannels);

        samplingRate = docNode.createElement('samplingRate');
        samplingRate.appendChild(docNode.createTextNode(num2str(sampling_rate)));  %%%  samplingRate
        acquisitionSystem.appendChild(samplingRate);

        voltageRange = docNode.createElement('voltageRange');
        voltageRange.appendChild(docNode.createTextNode('20'));  %%%  voltageRange
        acquisitionSystem.appendChild(voltageRange);

        amplification = docNode.createElement('amplification');
        amplification.appendChild(docNode.createTextNode('1000'));  %%%  amplification
        acquisitionSystem.appendChild(amplification);

        offset = docNode.createElement('offset');
        offset.appendChild(docNode.createTextNode('0'));  %%%  offset
        acquisitionSystem.appendChild(offset);

      %%% fieldPotentials
      fieldPotentials = docNode.createElement('fieldPotentials');
      parameters.appendChild(fieldPotentials);

        lfpSamplingRate = docNode.createElement('lfpSamplingRate');
        lfpSamplingRate.appendChild(docNode.createTextNode('1250'));  %%%  lfpSamplingRate
        fieldPotentials.appendChild(lfpSamplingRate);

      %%% anatomicalDescription
      anatomicalDescription = docNode.createElement('anatomicalDescription');
      parameters.appendChild(anatomicalDescription);

        channelGroups = docNode.createElement('channelGroups');
        anatomicalDescription.appendChild(channelGroups);

          for igroup = 1:nGroups          
              mygroup = docNode.createElement('group');
              channelGroups.appendChild(mygroup);

              % Shank data
              channelVector = ChannelMatrix(igroup,:);
              channelVector = channelVector(~isnan(channelVector));

              for ichannel = 1:numel(channelVector)              
                    mychannel = docNode.createElement('channel');
                    mychannel.setAttribute('skip','0');
                    mychannel.appendChild(docNode.createTextNode(num2str(channelVector(ichannel)-1))); 
                    mygroup.appendChild(mychannel); 
              end
          end

      %%% spikeDetection
      spikeDetection = docNode.createElement('spikeDetection');
      parameters.appendChild(spikeDetection);

        channelGroups = docNode.createElement('channelGroups');
        spikeDetection.appendChild(channelGroups);

          for igroup = 1:nGroups          
              mygroup = docNode.createElement('group');
              channelGroups.appendChild(mygroup);

              % Shank data
              channelVector = ChannelMatrix(igroup,:);
              channelVector = channelVector(~isnan(channelVector));

              channels = docNode.createElement('channels');
              mygroup.appendChild(channels);

              for ichannel = 1:numel(channelVector)              
                    mychannel = docNode.createElement('channel');
                    mychannel.appendChild(docNode.createTextNode(num2str(channelVector(ichannel)-1))); 
                    channels.appendChild(mychannel);  
              end

              nSamples = docNode.createElement('nSamples');
              nSamples.appendChild(docNode.createTextNode(num2str(32))); 
              mygroup.appendChild(nSamples);                 

              peakSampleIndex = docNode.createElement('peakSampleIndex');
              peakSampleIndex.appendChild(docNode.createTextNode(num2str(16))); 
              mygroup.appendChild(peakSampleIndex);   

              nFeatures = docNode.createElement('nFeatures');
              nFeatures.appendChild(docNode.createTextNode(num2str(3))); 
              mygroup.appendChild(nFeatures);  

          end

     %% Contents of Xml file (for Neuroscope)
     % Only the color information of each channel is added.
     
     %%%%%%%%-------- if you'd like to change the colors... --------%%%%%%%%     
    if multi_colors == 1
      
        %%% neuroscope
        neuroscope = docNode.createElement('neuroscope');
        neuroscope.setAttribute('version','2.0.0');
        parameters.appendChild(neuroscope);

          %%% miscellaneous
          miscellaneous = docNode.createElement('miscellaneous');
          neuroscope.appendChild(miscellaneous);

            screenGain = docNode.createElement('screenGain');
            screenGain.appendChild(docNode.createTextNode('0.2'));  
            miscellaneous.appendChild(screenGain);

          %%% spikes
          spikes = docNode.createElement('spikes');
          neuroscope.appendChild(spikes);

            nSamples = docNode.createElement('nSamples');
            nSamples.appendChild(docNode.createTextNode('32'));  
            spikes.appendChild(nSamples);

            peakSampleIndex = docNode.createElement('peakSampleIndex');
            peakSampleIndex.appendChild(docNode.createTextNode('16'));  
            spikes.appendChild(peakSampleIndex);

          %%% channels
          channels = docNode.createElement('channels');
          neuroscope.appendChild(channels);

          for igroup = 1:nGroups               
              % Shank data
              channelVector = ChannelMatrix(igroup,:);
              channelVector = channelVector(~isnan(channelVector));

              for ichannel = 1:numel(channelVector)              
                    channelColors = docNode.createElement('channelColors');
                    channels.appendChild(channelColors); 

                    mych = channelVector(ichannel)-1;
                      mychannel = docNode.createElement('channel');
                      mychannel.appendChild(docNode.createTextNode(num2str(mych))); 
                      channelColors.appendChild(mychannel);

                      mycolor = docNode.createElement('color');
                      mycolor.appendChild(docNode.createTextNode(colorSamples{mod(igroup-1,8)+1})); 
                      channelColors.appendChild(mycolor);

                      myAcolor = docNode.createElement('anatomyColor');
                      myAcolor.appendChild(docNode.createTextNode(colorSamples{mod(igroup-1,8)+1})); 
                      channelColors.appendChild(myAcolor);

                      myScolor = docNode.createElement('spikeColor');
                      myScolor.appendChild(docNode.createTextNode(colorSamples{mod(igroup-1,8)+1})); 
                      channelColors.appendChild(myScolor);

              end

          end
    end
    
    %% Create Xml file
    
    xmlwrite([fileBase,'.xml'], docNode);
    
    



