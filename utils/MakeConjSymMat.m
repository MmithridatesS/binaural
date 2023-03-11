function [Y] = MakeConjSymMat(X)

% noch nicht fertig

%X = X(:);
%Y = [X;conj(X(end-1:-1:2))];
vSize = size(X);
X2 = zeros();
X2 = X(end-1:-1:2,:);
Y = [X,X2];