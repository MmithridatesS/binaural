function [] = WriteDBL(sFileName,x);
fid = fopen(sFileName, 'w');
fwrite(fid,x,'double');
fclose(fid);