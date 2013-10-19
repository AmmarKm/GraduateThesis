function [energy, avgTime, abnormalframe, xps] = computeSRenergy0(Y, A, D, sc_algo, train_num, scene_start )
% ---------------------------------------------------
% Compute Sparse Representation Energy 
% Functionality: 
%       Find the approaximated sparse solution x of the linear system y=Ax
% Dimension: m  --- number of measurement
%            Nte--- number of testing samples
%            Ntr--- number of training samples
%
%                   Dimension          Description
% input:  Y          m x Nte       --- the testing sample
%         A          m x Ntr       --- the training sample
%         sc_algo                  --- the sparse coding algorithm
%                            e.g., l1magic, SparseLab, fast_sc, SL0, YALL1
% output: X          K x Nte       --- the sparse coefficient matrix of Y
%         avgTime                  --- average runtime for sparse coding
% 
% Reference: Jia-Bin Huang and Ming-Hsuan Yang, "Fast Sparse Representation with Prototypes.", the 23th IEEE Conference
%            on Computer Vision and Pattern Recognition (CVPR 10'), San Francisco, CA, USA, June 2010.
% Contact: For any questions, email me by jbhuang@ieee.org
% ---------------------------------------------------


Nte = size(Y, 2);
energy = zeros(Nte, 1);
abnormalframe = zeros(Nte, 2);
xps = zeros(400, Nte);
%%
source = VideoReader('E:\Resources\vision_data\UMN Dataset\Crowd-Activity-All.AVI'); %����ԭʼ��Ƶ
textColor    = [255, 0, 0]; % [red, green, blue]
textLocation = [90 70];       % [x y] coordinates
textInserter = vision.TextInserter('Warning!', ...
   'Color', textColor, 'FontSize', 30, 'Location', textLocation);


%% Compute the sparse representation X
Ainv = pinv(A);
w = 5;
if scene_start == 5600
    w = 3;
end
sumTime=0;
Threshold = 0;
abnormalscene_num = 0;
for i = 1: Nte
    % Inital guess
    y = Y(:,i);
    xInit = Ainv * y;
    
    % sparse coding: solve a reduced linear system
    %disp(['sparse coding ...',num2str(i)]);
    tic
    xp = sparse_coding_methods(xInit, A, y, sc_algo);
    t = toc;
    sumTime = sumTime+t;
    
    xps(:,i) = xp;
    %����ָ����ֵ���ʼ�²�ֵ��2��ʽ��ŷ����·��� ��ʾƫ���ƫ���
    %offset(i,:) = norm(xp-xInit);
    
    %����ϡ���ؽ�������ֵ�������������㹫ʽ�� Energy = 1/2*norm(y-D*xp)*norm(y-D*xp) + lamda*norm(xp,1)��
    energy(i,1) = 1/2*norm(y-D*xp)*norm(y-D*xp) + norm(xp,1);
    
    frame_num = scene_start + i - 1;
    disp(['frame', num2str(frame_num), '    energy:', num2str(energy(i,1))]);
    
    if i == train_num + 5
        Threshold = mean(energy(train_num + 1:i,1));
    end    
    %draw frame
    if i <= train_num + 5
        fr = read(source , frame_num);% ��ȡ֡
        imshow(fr);
        drawnow;
    end
    if i > train_num + 5
        fr = read(source , frame_num);% ��ȡ֡
        [energy] = smoothEnergy(energy);
        old = Threshold;
        Threshold = (Threshold*(i-1) + energy(i))/i;%���뵱ǰ֡������ֵ
        if energy(i) > w*Threshold
            abnormalscene_num = abnormalscene_num + 1;
            if abnormalscene_num > 3 %�豣֤����������֡�쳣ʱ�ű���
                J = step(textInserter, fr);
                imshow(J);
            else
                imshow(fr);
            end
            
            %����ж�Ϊ�쳣֡ ���ȥ��ǰ֡������ֵ ��ֵ����
            Threshold = old;
            abnormalframe(i,1) = i;
            abnormalframe(i,2) = energy(i);
        else
            imshow(fr);
            abnormalscene_num = 0;
        end
        drawnow;
    end;
    
    disp(['Threshold----', num2str(Threshold)]);
end
avgTime=sumTime/Nte;
clear source;
end