% A = 1.82 * 10^(-4)
clear all
maxCarNumber = 86;
minCarNumber = 10;
numberPace = 4;
roadLength = 2100;
effectiveRange = 300;
totalSecond = 1;
Threshold = 10^(-10);
maxBackoffTime = 100; % ����˱�ʱ��
PhyRate = 2*10^6 ;           %����������� bit/s
SlotTime = 20*10^(-6);       %ʱ϶��� s
TotalTime = totalSecond/SlotTime;    %�۲���ʱ϶����
SIFS = 0.5;        %SIFS�൱��0.5��ʱ϶
DIFS = 2.5;        %DIFS�൱��2.5��ʱ϶ 
ACK = 14*8/(PhyRate*SlotTime); %ACK ת����ʱ϶����
AverageArrivalTime = 110;    %ƽ������ʱ�� slottime
% AveragePacketLength = 100;    %ƽ��֡��
PacketLength = 1024; % �̶�֡�� slottime 1024*8bit֡�� = 204.8 slottime ֡��
Buffer_Threshold = 8*10^6/(PhyRate*SlotTime);%��������
sResult = zeros(1,((maxCarNumber-minCarNumber)/numberPace+1)); %��¼�����
maxInsNode = zeros(1,((maxCarNumber-minCarNumber)/numberPace+1));

for M = minCarNumber:numberPace:maxCarNumber %M����վ��Ŀ

ChannelBusy = 0;   %�ŵ�æ�б�־��ʼ��
Throughput = 0;%��������ʼ��
maxSimulNode = 0; %ͬʱ�������ڵ���
NormDis = 0; %������ �м���
% Start = 0; %�������ݿ�ʼ���ͱ�־
Collision = zeros(1,M); %���޳�ͻ��־
DeferenceTime = zeros(1,M); %������
ArrivalTime = zeros(1,M );  %����ʱ��
%PacketLength = zeros(1,M) ; %֡��
HasPacket = zeros(1,M);%���޻����־
CW = zeros(1,M); %���ô���
BackoffTimer = zeros(1,M); %����ʱ��
PacketBuff = zeros(M,1501);  %������
% CollisionStations = zeros(1,M+1);    %��ͻվ��¼
CurBufferSize = zeros(1,M);  %��ǰ������֡��
activeArray = zeros(M,1); % �Ѽ�����ڵ����
activeArraytemp = zeros(M,1);
%quarterHead = 1+M/4;
%quarterEnd = 3*M/4;

while 1
    carDistanceArray = carDistri(roadLength,M); % ����ģ�����ɳ����ֲ�
    if carDistanceArray(M+1) < roadLength
            break;
    end
    
    for kh = 2:M+1
        if (carDistanceArray(kh)-carDistanceArray(1)) > (roadLength/4)
            quarterHead = kh;
            break;
        end
    end
    for ke = M+1:-1:2
        if (carDistanceArray(ke)-carDistanceArray(1)) < (roadLength*3/4)
            quarterEnd = ke;
            break;
        end
    end
end
carInfmatrix = carInfmatrixGen(carDistanceArray,effectiveRange); % ��������ż�¼����

for i = 1:M
    ArrivalTime(i) = ProPoisson(AverageArrivalTime); %��ʼ������ʱ��  
    % PacketLength(i) =ProPoisson(AveragePacketLength);%��ʼ�����鳤��
    CW(i) = 32; %��ʼ����������
    BackoffTimer(i) = maxBackoffTime; %��ʼ���˱�ʱ�� 1000 
end

for t = 1:TotalTime
    for i = 1:M
        if t == ArrivalTime(i)
            %Ŀǰ���ܷ��ͣ�push�����PackeBuff���޸��˱ܼ�����
            if CurBufferSize(i) < Buffer_Threshold - PacketLength
                PacketBuff = Push(PacketBuff,i,PacketLength);
                CurBufferSize(i) = CurBufferSize(i) + PacketLength;
                HasPacket(i) = 1;
                if BackoffTimer(i) == maxBackoffTime
                    BackoffTimer(i) = ReSet(CW(i));%�˱ܼ������ﵽ���1000ʱ�������˱ܼ�����
                end
            end
            %���µ���ʱ���֡��
            ArrivalTime(i) = ProPoisson(AverageArrivalTime) + PacketLength + t;
            % PacketLength(i) = ProPoisson(AveragePacketLength);
        end
    end

    for i = 1:M
        % ChannelBusy = channelStateJudge(carInfmatrix(i,:),activeArray,Threshold); % ����ǿ���о���CCA mode1
        if HasPacket(i) == 1 && channelStateJudge(carInfmatrix(i,:),activeArray,Threshold) == 0 %PackeBuff�������ݰ����Ͳ����ŵ�����
            if BackoffTimer(i) == 0 %�˱�ʱ��=0 -> ����
                %%% CollisionStations = Add(CollisionStations,i);%�����ͻվ��������
                % Start = 1;
                activeArraytemp(i) = 1;
                % disp('i');
            else
                BackoffTimer(i) = BackoffTimer(i) - 1;%�˱�ʱ��!=0 -> �˱�ʱ��-1
            end
        end
    end   
    activeArray = activeArraytemp; % ���´��ڼ���״̬�Ľڵ�
    
    if norm(activeArray,2) ~= 0 %�ŵ���Ϊæµ
        % ChannelBusy = 1;
        % n = CollisionStations(1);
        for i = 1:M
            if activeArray(i) == 1 && DeferenceTime(i) == 0
                collisionJudge = channelStateJudge(carInfmatrix(i,:),activeArray,Threshold); % �˴������ж���ײ�ڵ㣬��N������ڵ�ͬʱ�����ҵ����໥����Ŵ�������ʱ����Ϊ��ײ
                if collisionJudge == 0 % û�з�����ײ
                    DeferenceTime(i) = floor(t + SIFS + DIFS + ACK + PacketBuff(i,2));
                    %PacketBuff(CollitionStations(2),2)���ݳ���
                    %�ɹ�����ʱ��
                    Collision(i) = 0;%û����ײ
                    % disp('ii');
                else
                    % DeferenceTime(CollisionStations(i)) = floor(t + DIFS + MaxLength(PacketBuff,CollisionStations));
                    DeferenceTime(i) = floor(t + DIFS + PacketBuff(i,2)); % ���ٹ�ע�֡����ÿ��֡�ֱ������ܲ�����
                    Collision(i) = 1;%������ײ
                end
            end
        end
        % Start=0;
    end
    
    for i = 1:M
        % if t == DeferenceTime(i) && norm(activeArray,2) ~= 0 
        if t == DeferenceTime(i) % �ŵ�æ��ʱ��ﵽվ��ĵȴ�ʱ��
            % disp('ttt');
            if Collision(i) == 0
                % n = CollisionStations(2);
                CurBufferSize(i) = CurBufferSize(i) - PacketBuff(i,2);
                Throughput = Throughput + PacketBuff(i,2)* SlotTime * PhyRate;
                % disp('iii');
                PacketBuff = Pop(PacketBuff,i);
                CW(i) = 32;
                k = PacketBuff(i,1);
                if k ==0 %���û�����ݵȴ����ͣ���HasPacket��0��BackoffTimer��Max
                    HasPacket(i) = 0;
                    BackoffTimer(i) = maxBackoffTime;
                else%�������ݷַ��ͣ��޸���ײ������
                    BackoffTimer(i) = ReSet(CW(i));
                end    
            else
                %  n = CollisionStations(1);
                % for t = 1:n
                    % j = CollisionStations(t+1);
                CW(i) = Increase(CW,i);
                BackoffTimer(i) = ReSet(CW(i));
                % end    
            end
            % CollisionStations = zeros(1,M+1);
            DeferenceTime(i) = 0;
            activeArray(i) = 0;
            activeArraytemp(i) = 0;
            Collision(i) = 0;
        end
    end

    NormDis = norm(activeArray(quarterHead:quarterEnd),1) - norm(Collision(quarterHead:quarterEnd),1);
    if NormDis > maxSimulNode
        maxSimulNode = NormDis;
    end
    
end

% sResult(M-4) = Throughput/(TotalTime* SlotTime * PhyRate);%������
sResult((M-minCarNumber)/numberPace+1) = Throughput/(totalSecond * PhyRate);
maxInsNode((M-minCarNumber)/numberPace+1) = maxSimulNode;

end

xline = minCarNumber:numberPace:maxCarNumber;
%plot(xline,sResult,'b-o');%��������վ����Ŀ�Ĺ�ϵ
plot(xline,maxInsNode,'b-o')
hold on;
plot(xline,sResult,'r-o');
hold on;
xlabel('number of potential transmitters');
ylabel('Total Throughputs');
title('Relation between number of transmitters and throughput');
grid;
%save([num2str(floor(roadLength/1000)),'k',num2str(totalSecond),'s',num2str(maxCarNumber)],'sResult');