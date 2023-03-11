function vSpec = FillNegFreq(vSpecHalf)
%ergänzt die rechte Hälfte eines Spektrums (in Kombination mit DeleteNegFreq verwenden)

%fürs Verständnis:
%len=size(posSpek,1);
%negSpek=conj(posSpek(2:len-1,:));
%negSpek=negSpek(end:-1:1,:);
%spektrum=[posSpek;negSpek];

%Kurzform:
vSpec = [vSpecHalf;conj(vSpecHalf(end-1:-1:2,:))];
end