%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%����ʱ��MRF����������Evidence��Potential%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load FeaturesPattern.mat;%load data

%%parameter%%
spaceLen=10;
tau=0.7;
%%%%%end%%%%%

[height,width] = size(FeaturesPattern);
%c--number of mixtuer components samplenum-- number of samples
[c,samplenum] = size(FeaturesPattern{1,1});

nodeNum = height*width*spaceLen;
factorNum = (width-1) * height * spaceLen + ...
            width * (height-1) * spaceLen + ...
            width * height * (spaceLen-1);
nodesNumInPlane = height*width;  %һ֡(ƽ�棩�еĽڵ��� 
factorsNumInPlane = (width - 1) * height + ...
		                  width * ( height - 1) + ...
						  width * height; %һ֡(ƽ�棩�е������� 
nodeEvidence = cell(nodeNum,1);     %�ڵ����Ŷ�
nodePosterior = cell(nodeNum,1);    %�ڵ�ĺ������
factorPotential = cell(factorNum,1);%��������
[linkage] = createLinkage(width, height, spaceLen);%factorNum*2 ά
freHist = cell(nodeNum,1);%the frequency histogram H=sum(pi) 
coHist = cell(factorNum,1);% the co-occurence histogram for neiboring node i and j H=sum(pi*pj)  
mahalHist = cell(nodeNum,1);%the Mahalanobis histogram
descriptors = cell(nodeNum,1);

for i=1:nodeNum
    freHist{i} = zeros(1,c);
end
for i=1:nodeNum
    mahalHist{i} = zeros(1,c);
end
for i=1:factorNum
    coHist{i} = zeros(c,c);
end

%����1.�ڳ�ʼ��10֡�����µ�֡����ʱԭʱ��MRF�ڵ�ı仯��μ���  �������������и���
%����2.��μ���ɶ�����
%����3.��μ������Ͼ���
for z=1:spaceLen
        for y=1:height
            for x=1:width
                MoFA = MoFAs{y,x};
                descriptor = Descriptors{y,x}(z,:);%activity descriptor
                nodeIndex = (z-1)*nodesNumInPlane + (y-1)*width + (x-1);%how to compute
                descriptors{nodeIndex+1} = descriptor;
                nodePosterior{nodeIndex+1} = FeaturesPattern{y,x}(:,z);
                sumf = 0; sums = 0;
                COVARANCE = cov(Descriptors{y,x});
                for k=1:c
                    poterior = FeaturesPattern{y,x}(k,z);
                    freHist{nodeIndex+1}(1,k) = freHist{nodeIndex+1}(1,k) + poterior;%accumulator                    
                    mahalHist{nodeIndex+1}(1,k) = mahalHist{nodeIndex+1}(1,k) + ((descriptor'-MoFA.M(:,k))'/COVARANCE)*(descriptor'-MoFA.M(:,k));%����ti�����c�����Ͼ���
                end
                %normalization
                freHistNorm = norm(freHist{nodeIndex+1}(1,:));
                mahalHistNorm = norm(mahalHist{nodeIndex+1}(1,:));
                for k=1:c
                    poterior = FeaturesPattern{y,x}(k,z);
                    sumf = sumf + (freHist{nodeIndex+1}(1,k)/freHistNorm)*poterior;
                    sums = sums + (mahalHist{nodeIndex+1}(1,k)/mahalHistNorm)*poterior;
                end
                nf1 = TransitionK(sumf);
                nf0 = 1 - nf1;
                ns0 = TransitionK(sums);
                ns1 = 1 - ns0;
                if ns0 > 0.5
                    ne0 = (1-tau)*nf0 + tau*ns0;
                    ne1 = (1-tau)*nf1 + tau*ns1;
                else
                    ne0 = tau*nf0 + (1-tau)*ns0;
                    ne1 = tau*nf1 + (1-tau)*ns1;
                end            
                nodeEvidence{nodeIndex+1} = [ne0,ne1];
            end
        end
end

%�����ʼ��������
for k=1:factorNum
    nodeIndex1 = linkage(k,1);
    nodeIndex2 = linkage(k,2);
    
    sum = 0;
    for i=1:c
        for j=1:c
            %���׼��
            coHist{k}(i,j) = coHist{k}(i,j) + ...
                nodePosterior{nodeIndex1+1}(i,1)*nodePosterior{nodeIndex2+1}(j,1);%����ֱ��ͼcoHist
            sum = sum + ...
                coHist{k}(i,j)*nodePosterior{nodeIndex1+1}(i,1)*nodePosterior{nodeIndex2+1}(j,1);
        end
    end
    pf11 = TransitionK(sum);
    pfother = 1 - pf11;
    t1 = descriptors{nodeIndex1+1};
    t2 = descriptors{nodeIndex1+2};
    ps00 = dot(t1,t2)/norm(t1)/norm(t2); ps11 = ps00; %xi=xj
    ps01 = 0; ps10 = 0;%xi!=xj
    alpha = 0.5;
    p00 = pfother + alpha*ps00;
    p11 = pf11 + alpha*ps11;
    p01 = pfother + alpha*ps01;
    p10 = p01;
    factorPotential{k} = [p00,p01;p10,p11];
end


save testdata.mat nodeEvidence factorPotential;

