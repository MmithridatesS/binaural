function [y] = CalcPower(x)
y = 1/numel(x)*sum(abs(x(:)).^2);