%
%source = VideoReader('E:\Resources\vision_data\PETS\59800-66750.avi'); %����ԭʼ��Ƶ
source = VideoReader('E:\Resources\vision_data\UMN Dataset\Crowd-Activity-All.AVI'); %����ԭʼ��Ƶ

textColor    = [255, 0, 0]; % [red, green, blue]
textLocation = [50 50];       % [x y] coordinates
textInserter = vision.TextInserter('Warning!', ...
   'Color', textColor, 'FontSize', 24, 'Location', textLocation);
for i = 1:1440
    fr = read(source , i);       % ��ȡ֡    
    %disp(['frame',num2str(i)]);

%     if MAPInds(i,1) == 1
%         J = step(textInserter, fr);
%         imshow(J);
    k = i;
    if k>5 && length(find(MAPInds(k-5:k,1)>0)) >=3
        J = step(textInserter, fr);
        imshow(J);
    else
        imshow(fr);
    end
    drawnow;
end
clear source;