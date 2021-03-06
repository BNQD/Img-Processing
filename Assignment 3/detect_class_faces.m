%run('../vlfeat-0.9.20/toolbox/vl_setup')
clear variables
close all
clc


load ('my_svm.mat');
imageDir = 'test_images';
imageList = dir(sprintf('%s/*.jpg',imageDir));
nImages = length(imageList);

bboxes = zeros(0,4);
confidences = zeros(0,1);
image_names = cell(0,1);
box_conf = [];

cellSize = 6;
dim = 36;

feature_vector = [];

%for imgNum=1:10floor(nImages/2)
imgNum = 12;
    % load and show the image
    %orig_im = im2single(imread(sprintf('%s/%s',imageDir,imageList(imgNum).name)));
    orig_im = im2single(imread('class.jpg'));
    imshow(orig_im);
    hold on;
    % generate a grid of features across the entire image. you may want to 
    % try generating features more densely (i.e., not in a grid)
    scales = 0.90:-0.05:0.15;
    
    for s = scales
        disp(s)
        im = imresize(orig_im, s);
        feats = vl_hog(im,cellSize);

        % concatenate the features into 6x6 bins, and classify them (as if they
        % represent 36x36-pixel faces)
        [rows,cols,~] = size(feats);    
        confs = zeros(rows,cols, length(scales));
        for r=1:rows-5
            for c=1:cols-5
                temp_feat = feats(r:r+5, c:c+5, :);
                confs(r, c) = temp_feat(:)'* w + b;
                % create feature vector for the current window and classify it using the SVM model, 
                % take dot product between feature vector and w and add b,
                % store the result in the matrix of confidence scores confs(r,c)

            end
        end

        % get the most confident predictions 
        [~,inds] = sort(confs(:),'descend');
        inds = inds(1:length(confs(:))); % (use a bigger number for better recall)
        offset = 0;
        for n=1:10
            overlap_flag = true;

            while overlap_flag == true
                ovmax = 0;
                if n+offset > length(inds)
                    break;
                end
                [row,col,conf] = ind2sub([size(feats,1) size(feats,2)],inds(n + offset));
                bbox = [ col*cellSize/s ...
                         row*cellSize/s ...
                        (col+cellSize-1)*cellSize/s ...
                        (row+cellSize-1)*cellSize/s];

                if (isempty(bboxes))
                    overlap_flag = false;
                else
                    for box_num = 1:size(bboxes, 1)
                        %Taken from "evaluate_detections_on_test.m"
                        bb = bbox;
                        bbgt=bboxes(box_num,:);
                        bi=[max(bb(1),bbgt(1)) ; max(bb(2),bbgt(2)) ; min(bb(3),bbgt(3)) ; min(bb(4),bbgt(4))];
                        iw=bi(3)-bi(1)+1;
                        ih=bi(4)-bi(2)+1;
                        if iw>0 && ih>0       
                            % compute overlap as area of intersection / area of union
                            ua=(bb(3)-bb(1)+1)*(bb(4)-bb(2)+1)+...
                               (bbgt(3)-bbgt(1)+1)*(bbgt(4)-bbgt(2)+1)-...
                               iw*ih;
                            ov=iw*ih/ua;
                            %disp(ov);
                            if ov>ovmax %higher overlap than the previous best?
                                ovmax=ov;
                                jmax=box_num;
                            end
                        end
                    end
                    if ovmax < 0.6
                        overlap_flag = false;
                    else
                        offset = offset + 1;
                    end 
                end
            end

            conf = confs(row,col);
            image_name = {imageList(imgNum).name};
            % plot
            
            

            % save       
            
            bboxes = [bboxes; bbox];
            confidences = [confidences; conf];
            box_conf = [box_conf;[bboxes, confidences]];
            image_names = [image_names; image_name];
        end
    end
    
    
    box_conf = sortrows(unique(box_conf, 'rows'), 5, 'descend');
    box_conf = box_conf(box_conf(:, 5) ~= 1, :);
    
    final_boxes = [];
    final_conf = [];
    final_img_names = [];
    
    for i = 1:size(box_conf, 1)
        bbox = box_conf(i, :);
        ovmax = 0;
        %Check for overlap
        overlap_flag = true;
        for box_num = 1:i-1
            %Taken from "evaluate_detections_on_test.m"
            bb = bbox;
            bbgt=box_conf(box_num,:);
            bi=[max(bb(1),bbgt(1)) ; max(bb(2),bbgt(2)) ; min(bb(3),bbgt(3)) ; min(bb(4),bbgt(4))];
            iw=bi(3)-bi(1)+1;
            ih=bi(4)-bi(2)+1;
            if iw>0 && ih>0       
                % compute overlap as area of intersection / area of union
                ua=(bb(3)-bb(1)+1)*(bb(4)-bb(2)+1)+...
                   (bbgt(3)-bbgt(1)+1)*(bbgt(4)-bbgt(2)+1)-...
                   iw*ih;
                ov=iw*ih/ua;
                %disp(ov);
                if ov>ovmax %higher overlap than the previous best?
                    ovmax=ov;
                    jmax=box_num;
                end
            end
        end
        %disp(ovmax);
        if ovmax < 0.01
            overlap_flag = false;
        end 
        if (box_conf(i, 5) > 1.8 && overlap_flag == false)
            plot_rectangle = [bbox(1), bbox(2); ...
            bbox(1), bbox(4); ...
            bbox(3), bbox(4); ...
            bbox(3), bbox(2); ...
            bbox(1), bbox(2)];
            plot(plot_rectangle(:,1), plot_rectangle(:,2), 'g-');
            final_boxes = [final_boxes;bbox];
            final_conf = [final_conf;bbox(5)];
            final_img_names = [final_img_names;image_name];
            
        end
    end
    %pause;
    fprintf('got preds for image %d/%d\n', imgNum,nImages);
%end

%evaluate
bboxes = final_boxes;
confidences = final_conf;
N = length(bboxes);
