
function y = Add(CollisionStations,index)
CollisionStations(1) = CollisionStations(1) + 1;%CollisionStations(1)ָʾ����վ��ĸ���
i = CollisionStations(1);
CollisionStations(i+1) = index;
y = CollisionStations;
