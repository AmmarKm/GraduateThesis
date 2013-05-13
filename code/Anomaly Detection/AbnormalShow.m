%
%source = VideoReader('E:\Resources\vision_data\PETS\59800-66750.avi'); %����ԭʼ��Ƶ
source = VideoReader('E:\Resources\vision_data\UMN Dataset\Crowd-Activity-All.AVI'); %����ԭʼ��Ƶ

textColor    = [255, 0, 0]; % [red, green, blue]
textLocation = [50 50];       % [x y] coordinates
textInserter = vision.TextInserter('Warning!', ...
   'Color', textColor, 'FontSize', 24, 'Location', textLocation);
for i = 1000:1450
    fr = read(source , i);       % ��ȡ֡    
    %disp(['frame',num2str(i)]);
    if MAPInds(i-999,1) == 1
        J = step(textInserter, fr);
        imshow(J);
    else
        imshow(fr);
    end
    drawnow;
end
clear source;