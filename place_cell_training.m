spikeid = 19;
 spiket100 = spiket(spikeind==spikeid);
 spiket100_whl_round = round(spiket100/512);
 spiket100_place = zeros(length(spiket100),2);
 for a=1:length(spiket100)
     for b=1:2
         spiket100_place(a,b)=whl(spiket100_whl_round(a),b);
     end
 end
 
%figure, plot(spiket100_place(:,1),spiket100_place(:,2),'ks')
 
%{
load carbig
X = [spiket100_place(:,1),spiket100_place(:,2)];
t = [whl(:,1) whl(:,2)];
hist3(X,'CdataMode','auto')
xlabel('x')
ylabel('y')
colorbar
view(2)
%}
%{
x =  whl(:,1);
y =  whl(:,2);
h = histogram2(x,y,'DisplayStyle','tile','ShowEmptyBins','on');
axis equal
colorbar
xlabel('x')
ylabel('y')
%}
bin = 20;
x_max = max(whl(:,1));
x_min = min(whl(:,1));
y_max = max(whl(:,2));
y_min = min(whl(:,2));
x_axis_min = 100;
x_axis_max = 700;
y_axis_min = 50;
y_axis_max = 500;

x_width = (x_axis_max - x_axis_min) / bin;
y_width = (y_axis_max - y_axis_min) / bin;
stay_time_m = zeros(bin+1,bin+1);
spike_num_m = zeros(bin+1,bin+1);
place_field_m = zeros(bin+1,bin+1);
for a=1:bin+1
    for b=1:bin+1
        for c=1:length(whl(:,1))
            if whl(c,1) >= x_width*(a-1) + x_axis_min && whl(c,1) < x_width*a + x_axis_min
                if whl(c,2) >= y_width*(b-1) + y_axis_min && whl(c,2) < y_width*b + y_axis_min
                    stay_time_m(bin - b+1 ,a) = stay_time_m(bin - b+1 ,a)+1;
                end
            end
        end
        for d=1:length(spiket100)
            if spiket100_place(d,1) >= x_width*(a-1) + x_axis_min && spiket100_place(d,1) < x_width*a + x_axis_min
                if spiket100_place(d,2) >= y_width*(b-1) + y_axis_min && spiket100_place(d,2) < y_width*b + y_axis_min
                    spike_num_m(bin - b+1 ,a) = spike_num_m(bin - b+1 ,a)+1;
                end
            end
        end
    end
end
for i=1:bin+1
    for j=1:bin+1
        if stay_time_m(i,j) ~= 0
            place_field_m(i,j) = spike_num_m(i,j) / stay_time_m(i,j);
        end
    end
end
stay_time_m
spike_num_m
place_field_m
[X,Y] = meshgrid(x_axis_min:x_width:x_axis_max,y_axis_max:-y_width:y_axis_min);
Z=place_field_m;
figure
surf(X,Y,Z)
xlabel('x')
ylabel('y')
title('place field','FontSize',12)
colorbar
view(2)