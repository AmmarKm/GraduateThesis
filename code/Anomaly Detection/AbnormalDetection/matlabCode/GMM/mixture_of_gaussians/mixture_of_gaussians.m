
clear all

%source = aviread('Crowd-Activity-All.AVI'); %����ԭʼ��Ƶ
source = VideoReader('viptraffic.avi'); %����ԭʼ��Ƶ

% -----------------------��ȡ��Ƶ����С-----------------------
%fr = source(1).cdata;           %��ȡ��һ֡
fr = read( source, 1);           %��ȡ��һ֡
fr_bw = rgb2gray(fr);           %ת��Ϊ�Ҷ�ͼ
fr_size = size(fr);             %��ȡ��Ƶ��С
height = fr_size(1);
width = fr_size(2);
fg = zeros(height, width);      %ǰ��
bg_bw = zeros(height, width);   %����

% -----------------------�趨��˹ģ�Ͳ���----------------------

C = 3;                                  % ��ϸ�˹ģ�͸���
M = 0;                                  % ������˹ģ�͸���
D = 2.5;                                % ���Ų���
alpha = 0.01;                           % ѧϰ�ʣ�0-1֮�䣩
thresh = 0.85;                          % Ȩֵ��ֵ
sd_init = 6;                            % ��ʼ��׼��
w = zeros(height,width,C);              % Ȩֵ����
mean = zeros(height,width,C);           % ��ֵ����
sd = zeros(height,width,C);             % ��׼�����
u_diff = zeros(height,width,C);         % ��ֵ����
p = alpha/(1/C);                        % �ο�ѧϰ��(alpha/w)
rank = zeros(1,C);                      % ���ȼ�(w/sd)
B = 0;                                  %Ȩֵ�ۼ�ֵ


% ----------------------��ʼ����˹ģ�Ͳ���---------------------

pixel_depth = 8;                        % 8-bit resolution
pixel_range = 2^pixel_depth -1;         % pixel range (# of possible values)

for i=1:height
    for j=1:width
        for k=1:C
            
            mean(i,j,k) = rand*pixel_range;     % ��ʼ����ֵΪ255���ڵ����ֵ
            w(i,j,k) = 1/C;                     % ��ʼ��ȨֵΪ1/C��Ȩֵ��ͬ��
            sd(i,j,k) = sd_init;                % ��ʼ����׼��Ϊsd_init
            
        end
    end
end

%---------------------ģ��ƥ���Լ���������---------------------

%for n = 1:length(source)
for n = 1:source.NumberOfFrames
    %fr = source(n).cdata;       % ��ȡ֡
    fr = read(source , n);       % ��ȡ֡
    fr_bw = rgb2gray(fr);       % ת��Ϊ�Ҷ�ͼ
    
    %�������ȼ�������
    rank = w(i,j,:)./sd(i,j,:); % ���ȼ�(w/sd) 
    temp = rank;                % �м����
    rank_ind = zeros(1,C);      % ���ȼ�˳�����
    %�������
    for k = 1:C
        [max_rank,max_rank_index] = max(temp);
        rank_ind(max_rank_index) = k;
        temp(max_rank_index) = 0;
    end
    
    % �����ֵ���󣬵�ǰֵ���ֵ֮�diff=abs(I(x,y)-u)
    for m=1:C
        u_diff(:,:,m) = abs(double(fr_bw) - double(mean(:,:,m)));
    end
    
    % ���¸�˹ģ�Ͳ���
    for i=1:height
        for j=1:width
            
            weight = w(i,j,:);     %��¼��ʼȨֵ��������ȡǰ��Ŀ��ʱ��Ȩֵ�ۼ�
            match = 0;             %����ƥ���־
            match_index = 0;       %����ƥ��ģ�͵�λ��
            for k=1:C                       
                if (abs(u_diff(i,j,k)) <= D*sd(i,j,k))   % ����ƥ��
                    
                    match = 1;                           % ����ƥ��
                    match_index = rank_ind(k);           % ƥ��ģ�͵�λ��
                    
                    % ����ƥ���˹ģ�͵Ĳ�����w,p,u,sd)
                    w(i,j,k) = (1-alpha)*w(i,j,k) + alpha;
                    p = alpha/w(i,j,k);                  
                    mean(i,j,k) = (1-p)*mean(i,j,k) + p*double(fr_bw(i,j));
                    sd(i,j,k) =   sqrt((1-p)*(sd(i,j,k)^2) + p*((double(fr_bw(i,j)) - mean(i,j,k)))^2);
                    
                else                                    % δƥ��ĸ�˹ģ��
                    w(i,j,k) = (1-alpha)*w(i,j,k);      % ������Ȩֵ(w��С)   
                end
            end
            
            % û�з���ƥ��ĸ�˹ģ�ͣ��򴴽�һ���µĸ�˹ģ�ʹ���Ȩֵ��С�ĸ�˹ģ��
            if (match == 0)
                [min_w, min_w_index] = min(w(i,j,:));        %ȡȨֵ��С�ĸ�˹ģ�� 
                mean(i,j,min_w_index) = double(fr_bw(i,j));  %�¸�˹ģ�͵ľ�ֵȡ��ǰֵ
                sd(i,j,min_w_index) = sd_init;               
            end
 
            %����Ȩֵ�ۼ�ֵ��ƥ��Ȩֵ��ֵthresh�������±���
            B = 0;            %Ȩֵ�ۼ�ֵ
            M = 0;           
            bg_bw(i,j)=0;     %����
            temp = rank_ind;  %�����м����temp
            while  B<=thresh 
                    [max_rank_ind,max_rank_ind_index] = min(temp); %ȡ������ȼ���������С��
                    B = B+weight(max_rank_ind_index);              %�ۼ�Ȩֵ
                    bg_bw(i,j) = bg_bw(i,j)+ mean(i,j,max_rank_ind_index)*w(i,j,max_rank_ind_index); %���±���
                    temp(max_rank_ind_index) = C+1;
            end
            M = max_rank_ind;
          
            
            
%------------------------��ȡǰ��Ŀ��-----------------------
            %��ȡǰ��
            k = 1;
            fg(i,j) = 0;
            while ((match == 0)&&(k<=M))                %��M��������˹ģ�ͽ���ƥ��
                   index = 1;
                   while (rank_ind(index) ~= k)&&(index < C)
                       index = index+1;
                   end

                   if (abs(u_diff(i,j,index)) <= D*sd(i,j,index))
                       fg(i,j) = 0;    %ƥ�䣬��õ�Ϊ������
                   else
                       fg(i,j) = 255;  %��ƥ�䣬�õ�Ϊǰ����   
                   end
         
                k = k+1;
            end
             
        end
    end
    

%     imshow(fg);
    figure(1)
    subplot(1,2,1),imshow(fr)
%     subplot(1,3,2),imshow(uint8(bg_bw)) 
    subplot(1,2,2),imshow(uint8(fg))     
    drawnow
    
    
 
    
%     Mov1(n)  = im2frame(uint8(fg),gray);           % put frames into movie
%     Mov2(n)  = im2frame(uint8(bg_bw),gray);           % put frames into movie
    
end
 
% movie2avi(Mov1,'mixture_of_gaussians_output','fps',30);           % save movie as avi 
% movie2avi(Mov2,'mixture_of_gaussians_background','fps',30);           % save movie as avi 
            

clear source;
 