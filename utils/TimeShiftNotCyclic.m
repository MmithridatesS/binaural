function [y] = TimeShiftNotCyclic(x,iDelay)

y = zeros(size(x));

if iDelay>0
  y(iDelay+1:end,:) = x(1:end-iDelay,:);
elseif iDelay<0
  y(1:end+iDelay,:) = x(1-iDelay:end,:);
else
  y = x;
end