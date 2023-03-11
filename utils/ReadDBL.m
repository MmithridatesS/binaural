function [y] = ReadDBL(sFileName);
fid = fopen(sFileName, 'r');
y = fread(fid, inf, 'double');