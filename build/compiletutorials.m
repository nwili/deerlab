
clc

files = dir('../tutorials/**/*.m');
sourcenames = {files.name};
pdfnames = cellfun(@(S)[S(1:end-1) 'pdf'],sourcenames,'UniformOutput',false);
htmlnames = cellfun(@(S)[S(1:end-1) 'html'],sourcenames,'UniformOutput',false);
mlxnames = cellfun(@(S)[S(1:end-1) 'mlx'],sourcenames,'UniformOutput',false);

paths = {files.folder};
sourcefiles = cellfun(@(x,y)fullfile(x,y),paths,sourcenames,'UniformOutput',false);
pdffiles = cellfun(@(x,y)fullfile(x,y),paths,pdfnames,'UniformOutput',false);
htmlfiles = cellfun(@(x,y)fullfile(x,y),paths,htmlnames,'UniformOutput',false);
mlxfiles = cellfun(@(x,y)fullfile(x,y),paths,mlxnames,'UniformOutput',false);

%Convert M-files to live scripts
for i=1:numel(mlxnames)
    fprintf('Conversion: m -> mlx (file %i of %i)...',i,numel(sourcefiles))
    matlab.internal.liveeditor.openAndSave(sourcefiles{i},mlxfiles{i});
    fprintf(' complete \n')
end

%Convert live script into other formats
for i=1:numel(pdfnames)
    fprintf('Conversion: mlx -> pdf (file %i of %i)...',i,numel(mlxfiles))
    matlab.internal.liveeditor.openAndConvert(mlxfiles{i},pdffiles{i});
    fprintf(' complete \n')
end

for i=1:numel(htmlnames)
    fprintf('Conversion: mlx -> html (file %i of %i)...',i,numel(mlxfiles))
    matlab.internal.liveeditor.openAndConvert(mlxfiles{i},htmlfiles{i});
    fprintf(' complete \n')
end

if ispc
    
    %Synchronize the AWS bucket
    system('python synchS3.py --keyfile %USERPROFILE%\.ssh\aws_access_keys.txt --directory "../tutorials" --bucket deertutorials');
    
    %Delete files
    for i=1:numel(pdfnames)
        fprintf('Deleting: pdf (file %i of %i)...',i,numel(sourcefiles))
        delete(pdffiles{i});
        fprintf(' complete \n')
    end
    
    for i=1:numel(mlxnames)
        fprintf('Deleting: mlx (file %i of %i)...',i,numel(sourcefiles))
        delete(mlxfiles{i});
        fprintf(' complete \n')
    end
    
end
