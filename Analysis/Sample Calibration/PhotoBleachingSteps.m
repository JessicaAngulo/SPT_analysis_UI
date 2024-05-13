function [num_steps_v] = PhotoBleachingSteps(app,v)
%PHOTOBLEACHINGSTEPS Finds intensity decays and checks weather it
%corresponds to photobleaching steps. 
%   28.06.2021 Roger Pons & Jessica Angulo
h = unique(app.Loaded_files.video_file{1,1}.TRACK_ID(:));
% num_steps_v = [];
derv_all = [];
filtered_all = [];
for j = 1:height(h)
    t = h(j,1);
    Trj_j = app.Loaded_files.video_file{1,1}(...
        app.save_session.(v).video_file{1,1}.TRACK_ID(:) == t,:);
    Trj_j = Trj_j(2:end,:); %exclude first frame
%     figure
%     subplot(2, 3, 1);
%     plot(0:height(Trj_j)-1,Trj_j.MEAN_INTENSITY);
%     xlabel('Frame')
%     ylabel('Mean Intensity [a.u.]')
%     title (sprintf('TRACK #%'),t)
    % Fourier Transform
    FTFrame = fft(Trj_j.MEAN_INTENSITY);
    dim = height(Trj_j);
    dx = 1;
    df = 1/(dim*dx); %step in frequency domain
    x = ((1:dim)-dim/2-1)*dx; %coordinates
    f = ((1:dim)-dim/2-1)*df; %frequencies
%     subplot(2, 3, 2);
%     plot(f,real(FTFrame))
%     title ('FT')
    % Gausian modulation (exponential decay filtering)
    dim = length(f);
    dx = 1;
    x0 = -dim/2;
    w = dim/20;
    df = 1/(dim*dx); %step in frequency domain
    x = ((1:dim)-dim/2-1)*dx; %coordinates
    f = ( (1:dim) - dim/2-1 )*df; %frequencies
    G1 = exp(-((x-x0).^2)/w^2);
%     subplot(2, 3, 3);
%     plot(f,G1)
%     title ('Gaussian modulation')
    G1 = G1.';
    % Convolution of the Intensity trace and the Gaussian decay
    FilteredFTFrame=G1.*FTFrame;
%     subplot(2, 3, 4);
%     plot(f,real(FilteredFTFrame))
%     title ('Convolution')
    % Inverse Fourier Transform
    FilteredFrame=ifft(FilteredFTFrame);
%     subplot(2, 3, 5);
%     plot(1:height(Trj_j),real(FilteredFrame))
%     title ('Cleaned TRACK ID')
    % First derivative
    x=1:height(Trj_j);
    dFilteredFrame = -gradient(FilteredFrame(:)) ./ gradient(x(:));
%     subplot(2, 3, 6);
%     plot(1:height(Trj_j),real(dFilteredFrame))
%     ylim([-30 30])
%     title ('Derivative cleaned')
    derv_all = [derv_all;dFilteredFrame(2:end-1,1)];
    filtered_all = [filtered_all;FilteredFrame(2:end-1,1)];
    % Filtering by the derivate peak size
%     [max,locs] = findpeaks(real(dFilteredFrame));
%     logical = max > 200;
%     steps = [max,locs];
%     steps = steps(logical);
%     num_steps_v = [num_steps_v;length(steps)];
end
keyboard
figure
leftbin = floor(min(real(derv_all)));
rightbin = ceil(max(real(derv_all)));
range = round(-leftbin+rightbin);
[N,edges] = histcounts(real(derv_all),round(range/2),'BinLimits',[leftbin rightbin]);
binwidth = edges(1,2)-edges(1,1);
centers = (edges + binwidth/2);
centers = centers(1,1:end-1);
histogram(real(derv_all),round(range/4),'Normalization','probability')
hold on
pd = fitdist(real(derv_all),'Normal');
P = pdf(pd,centers);
plot(centers,P)
left95 = pd.mu - 2*pd.sigma;
right95 = pd.mu + 2*pd.sigma;
unlikely = derv_all<=left95 | derv_all>=right95;
% Plot selected decays
% figure
% hold on
% Frame = real(FilteredFrame(2:height(Trj_j)-1));
% plot(1:height(Trj_j),real(FilteredFrame))
% time = (2:height(Trj_j)-1)';
% d = real(dFilteredFrame(2:height(Trj_j)-1));
% unlikely2 = d<=left95 | d>=right95;
% scatter(time(unlikely2,1),Frame(unlikely2,1))
