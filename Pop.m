
function y = Pop(PacketBuff,n)
PacketBuff(n,:) = [PacketBuff(n,1),PacketBuff(n,3:1501),0];%���ݷ��ͳɹ����޸Ļ������е�ֵ
PacketBuff(n,1) = PacketBuff(n,1) - 1;
y = PacketBuff;
