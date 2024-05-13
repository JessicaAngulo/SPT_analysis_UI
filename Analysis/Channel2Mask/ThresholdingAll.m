function ThresholdingAll(app,R_filtering)
%THRESHOLDING creates a binary image of the whole stack and 
%   11.01.2022 Jessica Angulo
%% Selection
v = app.videoname.Value;
th = (app.th_l.Position(:,1))';
number = app.IntensityThrSpinner.Value;
%% Binary image
image_G = app.Analysis.Channel2Mask.By_video.(v).Ch2Image_Gaus; %gaussian filter applied
binary = image_G >= th(1,1) & image_G <= th(1,2); 
image1 = app.Loaded_files.Ch2Image; %contrast adjusted, 8 bit
image1(binary == 0) = 0;
[h,w,f] = size(image1);
if R_filtering == 1
    if isfield(app.save_session.(v),'ROI') == 1
        vertices = cell(1,1);
        vertices{1,1} = app.save_session.(v).ROI;
        binary_roi = poly2label(vertices,1,[h,w]);
        binary_roi = repmat(binary_roi,1,1,f);
        binary_roi = logical(binary_roi);
        image1(binary_roi==0) = 0;
    end
end
%% Region extraction
% Common parameters
boundaries = struct;
se = strel('disk',3);
% Analysis itself
if app.save_session.(v).Channel2Type == 1 %one single mask image
    boundaries = cell(0,0);
    image1 = image1(:,:,1);
    Ie = imerode(image1(:,:),se);
    Iobr = imreconstruct(Ie,image1(:,:));
    for j = 1:number
        Iobr = imgaussfilt(Iobr,1);
        fgm = imextendedmax(Iobr,50); %mask of the regions of higher intensity
        boundary = bwboundaries(fgm,'noholes');
        if ~isempty(boundary) == 1
            for k = 1:length(boundary)
                if length(boundary{k,1})>3
                    boundaries = [boundaries;boundary{k,1}];
                end
            end
        else
            continue
        end
        Iobr(fgm == 1) = 0;
    end
    n_roi = size(boundaries,1);
    L = poly2label(boundaries(:,:),[1:n_roi],[w,h]);
    I2 = labeloverlay(image1(:,:),L','Colormap','hsv');
else %for time-lapsed 2nd channel acquisition
    %loading bar because it takes some time
    app.fig = uifigure;
    app.preview_bar = uiprogressdlg(app.fig,'Title','Processing the video','Cancelable','off');
    drawnow
    ch2_rate = app.save_session.(v).Frequency;
    list = 1:(ch2_rate+1):f; 
    if list(1,end)+(ch2_rate+1) > f
        n = length(list)-1;
    else 
        n = length(list);
    end
    for i = list(1,1:n)
        boundaries.("f"+i) = cell(0,0);
        Ie = imerode(image1(:,:,i),se);
        Iobr = imreconstruct(Ie,image1(:,:,i));
        for j = 1:number
            Iobr = imgaussfilt(Iobr,1);
            fgm = imextendedmax(Iobr,50); %mask of the regions of higher intensity
            boundary = bwboundaries(fgm,'noholes');
            if ~isempty(boundary) == 1
                for k = 1:length(boundary)
                    if length(boundary{k,1})>3
                        boundaries.("f"+i) = [boundaries.("f"+i);boundary{k,1}];
                    end
                end
            else
                continue
            end
            Iobr(fgm == 1) = 0;
        end
        n_roi = size(boundaries.("f"+i),1);
        L_i = poly2label(boundaries.("f"+i)(:,:),[1:n_roi],[w,h]);
        I2_i = labeloverlay(image1(:,:,i),L_i','Colormap','hsv');
        if i == list(1,1)
            L = L_i;
            I2 = I2_i;
        else
            L = cat(3,L,L_i);
            I2 = cat(4,I2,I2_i);
        end
        app.preview_bar.Value = i/f;
    end
    app.preview_bar.Value = 1;
    close(app.fig);
end
%% Save Data
app.Analysis.Channel2Mask.By_video.(v).Threshold = th;
app.Analysis.Channel2Mask.By_video.(v).Label_matrix = L;
app.Analysis.Channel2Mask.By_video.(v).Overlay = I2;
app.Analysis.Channel2Mask.By_video.(v).Boundaries = boundaries;
%
% group_i = group(:,1:165);
% group_i = group_i(~isnan(group_i(:)));
% [G1,G2,~] = groupcounts(group_i(:));
% G = [G2,G1];
% for i = 1:length(G)
%     r = G(i,1); %region i
%     if r == 0
%         continue
%     end
%     x = (boundaries.f1{r,1}(:,2))*app.save_session.(v).px_size_x;
%     y = (boundaries.f1{r,1}(:,1))*app.save_session.(v).px_size_y;
%     G3 = polyarea(x,y);
%     G(i,3) = G3;
%     G(i,4) = G(i,2)./G(i,3);
% end
%histogram('Categories',string(G(:,1)),'BinCounts',G(:,2))
%bar(G(:,1),G(:,3))
% region = G(:,1);
% counts = G(:,2);
% area = G(:,3);
% density = G(:,4);
% region_analysis = table(region,counts,area,density);
% app.Analysis.Channel2Mask.By_video.(v).Region_Analysis = region_analysis;
end