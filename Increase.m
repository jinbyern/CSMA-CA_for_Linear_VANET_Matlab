%������ָ����ײ��������
function y = Increase(CW,n)
i = log2(CW(n));
%�ﵽCWmax�󱣳�ֱ��������
if  i < 8
    i = i + 1;
end
y = 2^i;