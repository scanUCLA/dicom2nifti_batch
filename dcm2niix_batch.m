%% dcm2niix batch tool - Kevin Tan
% Converts DICOM files in subject folders into NIFTIs
% Must have latest AFNI installed/loaded

%% User-editable parameters

% Folder to save logs in
logDir = '/u/project/sanscn/data/gratitude_mprage/dicom2nifti';

% Filename of log & status struct to be saved
logName = 'dcm2niix_BOLD_gratitude';

% Wildcard string to find all the DICOM directories you want to convert (not the dicom files themselves!)
dicomDirs = dir('/u/project/sanscn/data/gratitude/*/dicom/*/*/*/*/BOLD_*');

% Root folder to put converted NIFTIs
outDir = '/u/project/sanscn/data/gratitude_mprage/gratitude_raw';

% Subject subdirectories under run directory
subDir = '/raw';

% Actually call dcm2niix or just look at outputs?
dryRun = 1;

%%

% Prep
nScans = length(dicomDirs);
status = struct;

% Loop to gather scans and info (have to preallocate for parfor)
for ii = 1:nScans
    
    % Get scan info from DICOM header
    cd([dicomDirs(ii).folder '/' dicomDirs(ii).name]);
    [error, hInfo] = system('dicom_hinfo -tag 0010,0010 0018,1030 0020,0011 1', '-echo');
    hParts = strsplit(hInfo,' ');
    sub = strtrim(hParts{2});
    runName = strtrim(hParts{3});
    seriesNum = strtrim(hParts{4});
    
    % Organize scan info into log struct
    status(ii).sub = sub;
    status(ii).runName = [runName '_' seriesNum]; % Scan protocol name _ series number
    status(ii).dicomDir = [dicomDirs(ii).folder '/' dicomDirs(ii).name];
    status(ii).outDir = [outDir '/' sub  subDir '/' status(ii).runName];
    
    % dcm2niix command
    status(ii).cmd = ['dcm2niix -f %p -v y -t y -o ' status(ii).outDir ' ' status(ii).dicomDir];
    status(ii).error = [];
    status(ii).log = [];
    
end

% Parfor loop to execute dcm2niix
if ~dryRun
    diary([logDir '/' logName '.txt']);
    parfor ii = 1:nScans
        % make output folder
        try
            mkdir(status(ii).outDir);
        catch
        end
        
        % Execute command
        [status(ii).error,status(ii).log] = system(status(ii).cmd, '-echo');
    end
    diary off
    save([logDir '/' logName '.mat'], 'status');
end
