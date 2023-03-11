function [y] = MinPhaseResponse(x)

y = x;

y(iN/2+1) = x(iN/2);
y(iN/2+2:iN)  = conj(x(iN/2:-1:2));

y  = abs(y).*exp(-1i*imag(hilbert(log(abs(y)))));