%�ȴ����͵�֡���뻺������
function y = Push(PacketBuff,index,PacketLength)
i = PacketBuff(index,1);
if i < 1500    
    PacketBuff(index,i+2) = PacketLength;
    PacketBuff(index,1) = PacketBuff(index,1) + 1;
end
y = PacketBuff;
