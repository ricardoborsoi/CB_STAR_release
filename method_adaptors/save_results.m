
function save_results( filename, X )
  fid = fopen(filename, 'w');
  for i=1:size(X,1)
    fprintf(fid, '%s', X{i,1});
    fprintf(fid, '\t%d', X{i,2:end});
    fprintf(fid, '\n');
  end
  fclose(fid);
end