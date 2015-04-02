clear all
maxCarNumber = 20;
minCarNumber = 5;
sResult = zeros(1,maxCarNumber - minCarNumber + 1); %��¼�����

for M = minCarNumber:maxCarNumber %M����վ��Ŀ
ChannelBusy = 0;   %�ŵ�æ�б�־
Start = 0; %�������ݿ�ʼ���ͱ�־
Collision = 0;%���޳�ͻ��־
DeferenceTime = 0; %������
Throughput = 0;%������
ArrivalTime = zeros(1,M );  %����ʱ��
PacketLength = zeros(1,M) ; %֡��
HasPacket = zeros(1,M);%���޻����־
CW = zeros(1,M);%���ô���
BackoffTimer = zeros(1,M);%����ʱ��
PacketBuff = zeros(M,1501);  %������
CollisionStations = zeros(1,M+1);    %��ͻվ��¼
PhyRate = 2*10^6 ;           %�����������
SlotTime = 20*10^(-6);       %ʱ϶���
TotalTime = 2/SlotTime;    %�۲���ʱ϶����
SIFS = 0.5;        %SIFS�൱��0.5��ʱ϶
DIFS = 2.5;        %DIFS�൱��2.5��ʱ϶ 
ACK = 14*8/(PhyRate*SlotTime); %ACK ת����ʱ϶����
AverageArrivalTime = 110;    %ƽ������ʱ��
AveragePacketLength = 50;    %ƽ��֡��
CurBufferSize = zeros(1,M);  %��ǰ������֡��
Buffer_Threshold = 8*10^6/(PhyRate*SlotTime);%��������
%activeArray = zeros(1,M);

%carDistanceArray = cardistri(roadLength,M);
%arInfmatrix(carDistanceArray);

for i = 1:M
    ArrivalTime(i) = ProPoisson(AverageArrivalTime); %��ʼ������ʱ��  
    PacketLength(i) =ProPoisson(AveragePacketLength);%��ʼ�����鳤��
    CW(i) = 32; %��ʼ����������
    BackoffTimer(i) = 1000; %��ʼ���˱�ʱ�� 1000 
end

for t = 1:TotalTime
    for i = 1:M
        if t == ArrivalTime(i)
            %Ŀǰ���ܷ��ͣ�push�����PackeBuff���޸��˱ܼ�����
            if CurBufferSize(i) < Buffer_Threshold - PacketLength(i)
                PacketBuff = Push(PacketBuff,i,PacketLength(i));
                CurBufferSize(i) = CurBufferSize(i) + PacketLength(i);
                HasPacket(i) = 1;
                if BackoffTimer(i) == 1000
                    BackoffTimer(i) = ReSet(CW(i));%�˱ܼ������ﵽ���1000ʱ�������˱ܼ�����
                end
            end
            %���µ���ʱ���֡��
            ArrivalTime(i) = ProPoisson(AverageArrivalTime) + PacketLength(i) + t;
            PacketLength(i) = ProPoisson(AveragePacketLength);
        end
    end

    for i = 1:M
        if HasPacket(i) == 1 && ChannelBusy == 0 %PackeBuff�������ݰ����Ͳ����ŵ�����
            if BackoffTimer(i) == 0 %�˱�ʱ��=0 -> ����
                CollisionStations = Add(CollisionStations,i);%�����ͻվ��������
                Start = 1;
                %activeArray(i) = 1;
            else
                BackoffTimer(i) = BackoffTimer(i) - 1;%�˱�ʱ��!=0 -> �˱�ʱ��-1
            end
        end
    end
    
    if Start == 1%�ŵ���Ϊæµ
        ChannelBusy = 1;
        n = CollisionStations(1);
        
        if n == 1%�ŵ���ֻ��һ��վ�㷢��������Ϊ�����������
            DeferenceTime = floor(t + SIFS + DIFS + ACK + PacketBuff(CollisionStations(2),2));
            %PacketBuff(CollitionStations(2),2)���ݳ���
            %�ɹ�����ʱ��
            Collision=0;%û����ײ
        else
            DeferenceTime = floor(t + DIFS + MaxLength(PacketBuff,CollisionStations));
            Collision=1;%������ײ
        end
        Start=0;        
    end
    
    if t == DeferenceTime && ChannelBusy == 1%�ŵ�æ��ʱ��ﵽվ��ĵȴ�ʱ��
        if Collision == 0
            n = CollisionStations(2);
            CurBufferSize(n) = CurBufferSize(n) - PacketBuff(n,2);
            Throughput = Throughput + PacketBuff(n,2)* SlotTime * PhyRate;
            PacketBuff = Pop(PacketBuff,n);
            CW(n) = 32;
            k = PacketBuff(n,1);
            if k ==0%���û�����ݵȴ����ͣ���HasPacket��0��BackoffTimer��Max
                HasPacket(n) = 0;
                BackoffTimer(n) = 1000;
            else%�������ݷַ��ͣ��޸���ײ������
                BackoffTimer(n) = ReSet(CW(n));
            end    
        else
            n = CollisionStations(1);
            for i = 1:n
                j = CollisionStations(i+1);
                CW(j) = Increase(CW,j);
                BackoffTimer(j) = ReSet(CW(j));
            end    
        end
        CollisionStations = zeros(1,M+1);
        DeferenceTime = 0;
        ChannelBusy = 0;
        Collition = 0;
    end
end
sResult(M-4) = Throughput/(TotalTime* SlotTime * PhyRate);%������
end

xline = minCarNumber:1:maxCarNumber;
plot(xline,sResult,'b-o');%��������վ����Ŀ�Ĺ�ϵ
hold on;
xlabel('����վ��Ŀ(��)');
ylabel('������');
title('����վ��Ŀ�������ʵĹ�ϵ');
grid;