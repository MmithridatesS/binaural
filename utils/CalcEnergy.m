function [y] = CalcEnergy(x)
y = sum(abs(x(:)).^2);