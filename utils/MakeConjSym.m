function [Y] = MakeConjSym(X)
X = X(:);
Y = [X;conj(X(end-1:-1:2))];