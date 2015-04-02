% ����ģ���У��������X���϶�����̬�ֲ�

function carDistanceCumulate = carDistri(roadlength,carnumber)
averageCarDistance = floor(roadlength/carnumber); %ƽ������
Miu = log(averageCarDistance) - 0.5; % ƽ������ E = exp(Miu + sigma^2/2) so....
carDistanceArrayTemp = lognrnd(Miu,1,1,carnumber);
carDistanceCumulate = zeros(1,carnumber + 1);

for i = 1:carnumber
    carDistanceCumulate(i+1) = carDistanceCumulate(i) + carDistanceArrayTemp(i);
end

end

    


