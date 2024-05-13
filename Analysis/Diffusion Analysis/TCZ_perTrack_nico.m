function [Final_TCZ] = TCZ_perTrack_nico(track,framerate,...
    L_threshold,segment_maximum,minimumSegmentLength,confinementRadius,...
    DiniFixed,Dif)
%TCZ_PERTRACK_NICO is adapted from Nico's function (f_tcz_analysis_perTrack_nico)
% in order to accept my input data. The original function is based on the 
% (largly undocumented) code of Juan. 
%   Input:
%       track: trajectory information. Column 1 correspods to the x
%       coordinates, column 2 contains y coordinates, and column 3 contains
%       the frame number
%       framerate: frame rate in [s]
%       L_threshold:
%       segment_maximum: maximum segment length
%       minimumSegmentLength: minimum segment length
%       confinementRadius: {'fixedSize' 'diffusionCoefficientDependent'}
%       DiniFixed: estimated dif. coef. within a region of radius r = pi*r^2/t
%   Output:
%       % Final_TCZ has the values of the coordinates of the stall
%       rows 1:2=xpos ypos 3=amount of confined segments 
%       4=frame number 5= confinement diameter

%   08.06.2022 Jessica Angulo Capel

num_traj = 1;
ryz=1;
% run the every segment length
for segment_length=4:segment_maximum
    wxz=segment_length-1;
    xyzk=1;
    si_traj = size(track);
    % Simu_track is a simulated track with the same number of points that the 
    % real track contains. It is for knowing which segment belongs to which point.
    simu_track=1:si_traj(1);
    simu_track=[simu_track',simu_track'];
    zzz=1;
    for ii=1:segment_length
        aa=si_traj(1)-(ii-1);
        bb=floor(aa/segment_length);
        for zz=ii:segment_length:((ii+(bb*segment_length))-1)
             segments_simu(:,zzz)=simu_track(zz:zz+wxz,1);
             zzz=zzz+1;
        end
    end
    si_seg_si=size(segments_simu);
    si_simutrack=size(simu_track);
    for kkii=1:si_simutrack(1)
        inter_value=simu_track(kkii,1);
        jz=1;
        for kkjj=1:si_seg_si(2)
            recog_value=find(segments_simu(:,kkjj)==inter_value);
            bb=numel(recog_value);
            if bb>0
                occurrences(jz,kkii)=kkjj; %occurences gives which segments belong to each point of the track
                jz=jz+1;
            end
        end
    end
    % coordinates are splitted into a matrix with each row a segment of
    %segment_lenght, no overlap in coordinates
    % Segmentation of the real tracks
    zzz=1;
    for ii=1:segment_length
        aa=si_traj(1)-(ii-1);
        bb=floor(aa/segment_length);
        for zz=ii:segment_length:((ii+(bb*segment_length))-1)
             segments_x(:,zzz) = track(zz:zz+wxz,1);
             segments_y(:,zzz) = track(zz:zz+wxz,2);
             zzz=zzz+1;
        end
    end
    si_x=size(segments_x); 
    si_y=size(segments_y);
    jj=1;
    % Finding the corresponding Radius of the segment by looking for 
    % the biggest displacement from the starting point of that particular 
    % segment 
    for jjj=1:si_x(2)
        iii=1;
        for xx=2:si_x(1) % They don't find the biggest, 
            % just between 1 and 2, 1:3, 1:4...
            dx(iii,jjj)=segments_x(xx,jjj)-segments_x(1,jjj);
            dy(iii,jjj)=segments_y(xx,jjj)-segments_y(1,jjj);
            iii=iii+1;
        end
    end
    distance = sqrt((dx).^2+(dy).^2);
    Radius_microns = max(distance);%.*pixel_size;  %%pixel_size im um
    % the time the particle has to move (5 points, 4 steps)
    time=(segment_length-1)*framerate;
    switch confinementRadius
        case 'fixedSize'
            % A fixed value of D gives a fixed radius to determine the
            % stall. Basically it looks for parts of the tracks that
            % have a diffusion coefficient below 0.06 um/s2
            Dini=DiniFixed;
            TCZ_segment=0.2048-(2.5117*(Dini*time./(Radius_microns.^2))); 
            % In the Kusumi paper of Super-long SPT they used a fixed
            % detection circle as the threshold for stall/not stall
            % It is set to r=0.2um at dt=0.67s (20 frames). 
            % This results in Dini=0.06 to pass the threshold of
            % log(0.1) (see calculating probability level)
            
            %TCZ_segmentFixed=0.2048-(2.5117*(0.06*0.67./(0.2.^2)))=-2.3=log(0.1)
            %DiniF=(-log(0.1)+0.2048)*(0.2.^2)/(2.5117*0.67)=0.06;

        case 'diffusionCoefficientDependent'
            % TCZ calculation for every segment
            Dini = Dif;
            TCZ_segment=0.2048-(2.5117*(Dini*time./(Radius_microns.^2))); 
            % TCZ_segment=0.2048-(2.5117*(Dini*time./(Radius_microns(1,1).^2))); % old radius shape
    end
    % Differences in TCZ values reflect the segments (high value = static/immobile
    si_TCZ=size(TCZ_segment);
    % Calculating the probability level L for each segment. See the paper!
    for i=1:si_TCZ(2) 
        if TCZ_segment(1,i)<=log(0.1) %% ln (0.1), see the paper!
            TCZ_inter(1,i)=-(TCZ_segment(1,i))-1; 
        else
            TCZ_inter(1,i)=0;
        end
    end
    wxyz=1;
    % Assigning every segment to its corresponding point and averaging.
    for llm=1:si_traj(1) 
        inter_pos=find(occurrences(:,llm)>0);
        vector_inter=occurrences(inter_pos,llm);
        TCZ_def(llm,xyzk)=mean(TCZ_inter(1,vector_inter));
    end
    clear segments_simu dx dy occurrences segments_x segments_y TCZ_inter
    xyzk = xyzk+1;
    TCZ_def_d(:,ryz:(ryz+(num_traj-1))) = TCZ_def;
    ryz = ryz+num_traj;
    clear segments_simu occurrences segments_x segments_y dx dy TCZ_inter TCZ_def
end
% The TCZ_def_d matrix has in every column the TCZ values for a track and the row
% represent different parameters, first the tracks and then different
% segment size with again all the tracks
clear TRtotal_def TRtotal_new segments_simu segments_x segments_y distance dx dy
si_TC_d=size(TCZ_def_d);
cuki=1;
for coke=1:num_traj  %build average over all segments
    arr=1;
    for jtp=coke:num_traj:si_TC_d(2)
        interm_va(:,arr)=TCZ_def_d(:,jtp);
        arr=arr+1;
    end

    TCZ_def(:,cuki)=mean(interm_va,2);
    cuki=cuki+1;
end
% This is the point where the segment type is detemined, on or over
% threshold
inter_lab = TCZ_def>L_threshold;
si_inter_l = size(inter_lab);
j = 1;
wwz = 1;
aaaa = 1;

% Make a Final_TCZ matrix that looks fits the MSS_DC analysis
Final_TCZ=[];
for jj=1:si_inter_l(2)
    [bb,cc]=bwlabeln(inter_lab(:,jj)); % this counts the amount of seperated confinement segments
    rrr=1; % counter to fill the TCZ_DC matrix
    for rr=1:cc
        ll=find(bb==rr);
        r=numel(ll);
        length_TCZ(:,j)=r;
        j=j+1;
        if (r > minimumSegmentLength)%minimum duration
            Final_TCZ(aaaa:(aaaa+r-1),1) = track(ll,1); %x coordinate
            Final_TCZ(aaaa:(aaaa+r-1),2) = track(ll,2); %y coordinate
            Final_TCZ(aaaa:(aaaa+r-1),3) = cc;
            Final_TCZ(aaaa:(aaaa+r-1),4) = track(ll,3); %frame number
            abcde=1;
            % Confinement diameter
            xx = mean(Final_TCZ(aaaa:(aaaa+r-1),1));
            yy = mean(Final_TCZ(aaaa:(aaaa+r-1),2));
            x_min = Final_TCZ(aaaa:(aaaa+r-1),1)-xx;
            y_min = Final_TCZ(aaaa:(aaaa+r-1),2)-yy;
            distance = sqrt(x_min.^2+y_min.^2);
            diameter = mean(distance)*2;
            Final_TCZ(aaaa:(aaaa+r-1),5) = diameter;
            aaaa = aaaa+r;
        end
    end
  wwz=wwz+1;
end
end