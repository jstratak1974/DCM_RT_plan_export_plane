% Script to export transverse dose planes from a DICOM RT Plan
% Prompts for input DICOM RT Plan and output folder

% Prompt for the DICOM RT Plan input file
[inputFile, inputPath] = uigetfile('*.dcm', 'Select the DICOM RT Plan file');
if isequal(inputFile, 0)
    disp('User canceled the input selection.');
    return;
end
inputFilePath = fullfile(inputPath, inputFile);

% Prompt for the output folder
outputFolder = uigetdir('', 'Select the output folder for dose planes');
if outputFolder == 0
    disp('User canceled the output folder selection.');
    return;
end

% Read the DICOM RT Plan file
rtPlan = dicomread(inputFilePath);
info = dicominfo(inputFilePath);

% Check if the file contains dose planes
if ~isfield(info, 'DoseGridScaling')
    error('The selected file does not contain dose information.');
end

% Extract dose information
doseGridScaling = info.DoseGridScaling;
doseArray = rtPlan * doseGridScaling; % Apply scaling factor to get physical dose

% Get dimensions
[dimX, dimY, dimZ] = size(doseArray);

% Check if ImagePositionPatient and SliceThickness fields exist
if ~isfield(info, 'ImagePositionPatient') || numel(info.ImagePositionPatient) < 3
    % Initialize with default values if not present or incorrect dimensions
    imagePositionPatient = [0, 0, 0];
else
    imagePositionPatient = info.ImagePositionPatient;
end
if ~isfield(info, 'SliceThickness')
    sliceThickness = 1; % Set a default slice thickness if not specified
else
    sliceThickness = info.SliceThickness;
end

% Loop through each transverse dose plane and save it as a new DICOM file
for z = 1:dimZ
    % Extract the dose plane
    dosePlane = doseArray(:,:,z);
    
    % Prepare new DICOM info for each plane
    planeInfo = info;
    planeInfo.InstanceNumber = z;
    
    % Update the full ImagePositionPatient for each slice
    planeInfo.ImagePositionPatient = [imagePositionPatient(1), imagePositionPatient(2), imagePositionPatient(3) + (z - 1) * sliceThickness];
    
    % Define the output file name
    outputFileName = sprintf('DosePlane_%03d.dcm', z);
    outputFilePath = fullfile(outputFolder, outputFileName);
    
    % Write the dose plane to a new DICOM file
    dicomwrite(dosePlane, outputFilePath, planeInfo, 'CreateMode', 'Copy');
    fprintf('Saved dose plane %d to %s\n', z, outputFilePath);
end

disp('All dose planes have been exported successfully.');
