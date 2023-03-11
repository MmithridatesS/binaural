function [E] = CalcEDC(h,fSR)
E = zeros(size(h));
for iC = length(h)-1:-1:1
  E(iC) = E(iC+1) + h(iC)^2;
end
E = E/max(E);
figure
plot((0:length(h)-1)/fSR,10*log10(E))
ylim([-70,0])