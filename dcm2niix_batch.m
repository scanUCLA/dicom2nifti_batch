%% dcm2niix batch tool - Kevin Tan
% Converts DICOM files in subject folders into NIFTIs
% Must have latest AFNI installed/loaded

%% User-editable parameters

% Folder to save logs in
logDir = '/u/project/sanscn/data/gratitude_mprage/dicom2nifti';

% Filename of log & status struct to be saved
logName = 'dcm2niix_BOLD_gratitude';

% Wildcard string to find *all* the DICOM directories you want to convert (test this out first; not the dicom files themselves!)
dicomDirs = dir('/u/project/sanscn/data/gratitude/grat*/dicom/*/*/*/*/BOLD_*');

% Root folder to put converted NIFTIs
outDir = '/u/project/sanscn/data/gratitude_mprage/gratitude_raw';

% Subject subdirectories under run directory
subDir = '/raw';

% Actually call dcm2niix or just look at outputs?
dryRun = 0;

% Save DICOM info in run folder?
saveDinfo = 1;

%%

% Prep
nScans = length(dicomDirs);
status = struct;

% Loop to gather scans and info (have to preallocate for parfor)
for ii = 1:nScans
    
    % Get scan info from DICOM header
    sDir = [dicomDirs(ii).folder '/' dicomDirs(ii).name];
    dinfo = dicominfo([sDir '/1']);
    sub = strrep(strtrim(dinfo.PatientID),' ','_');
    runName = strrep(strtrim(dinfo.ProtocolName),' ','_');
    seriesNum = num2str(dinfo.SeriesNumber);
    
    % Organize scan info into log struct
    status(ii).sub = sub;
    status(ii).runName = [runName '_' seriesNum]; % Scan protocol name _ series number
    status(ii).dicomDir = sDir;
    status(ii).outDir = [outDir '/' sub  subDir '/' status(ii).runName];
    
    % dcm2niix command
    status(ii).cmd = ['dcm2niix -f ' status(ii).runName ' -v y -o ' status(ii).outDir ' ' sDir];
    status(ii).error = [];
    status(ii).log = [];
    status(ii).dicomInfo = dinfo;
    
    if ~dryRun
        % make output folder
        try
            mkdir(status(ii).outDir);
        catch
        end
        if saveDinfo
            save([status(ii).outDir '/dicomInfo_' status(ii).sub '_' status(ii).runName '.mat'], 'dinfo');
        end
    end
end

% Parfor loop to execute dcm2niix
if ~dryRun
    parfor ii = 1:nScans
        % Execute command
        [status(ii).error,status(ii).log] = system(status(ii).cmd, '-echo');
    end
    save([logDir '/' logName '.mat'], 'status');
end
