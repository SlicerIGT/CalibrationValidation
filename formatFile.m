%Generates a file that can be used for analysis of data

%Input: 
%
%NumCollectedDataSets - the number of collected data sets. each set of four
%points is considered a data set
%
%path - full path to the folder containing: data set folders, file
%containing ground truth position and file containing referenceToRAS transform.  

function[] = formatFile(numCollectedDataSets, path)

cd(path);

output = fopen('outputfile.txt','w');

%Write to output file the number of data sets that are collected
fprintf(output,'%d\n', numCollectedDataSets);

%Find data folders
directory = dir('Data*');

%Enter folder for each data set. Each should contain four files corresponding
%to image points and four files corresponding to the ProbeToReference 
%transforms, which each correlate to an image point. We first add the image
%points to the file
for i=1:numCollectedDataSets
    folder = directory(i).name;
    cd(folder);
    for j=1:4
        %search for image point files
        pointFiles = dir ('CrossPoint*.fcsv');
        file = pointFiles(j).name;
        
        fid = fopen(file);
        while ~feof(fid)
                point = textscan(fid, '%s%f%f%f', 'delimiter', ',', 'headerLines', 18);
                %print image point coordinate to the output.txt file. Add
                %and extra '1' at the end of the x, y and z coordinates
                fprintf(output,'%f,%f,%f,%f\n', point{2}(1), point{3}(1), point{4}(1), 1);
        end
    end
    cd(path);
end
cd(path);

%from the same folder as above we now add the ProbeToReference transforms
%to the file
for i=1:numCollectedDataSets
    folder = directory(i).name;
    cd(folder);
    for j=1:4
        %search for ProbeToReference transforms
        ProbeToReferenceTransformFiles = dir('ProbeToReference*.tfm');
        file = ProbeToReferenceTransformFiles(j).name;
        
        fid = fopen(file);
        while ~feof(fid)
            transform = textscan(fid, '%s%f%f%f%f%f%f%f%f%f%f%f%f', 'delimiter', ' ', 'headerLines', 3);
            %print transform matrices to the output.txt file. add a fourth
            %line [0, 0, 0, 1]
            fprintf(output, '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f\n',transform{2}(1),transform{3}(1),transform{4}(1),transform{5}(1),transform{6}(1),transform{7}(1),transform{8}(1),transform{9}(1),transform{10}(1),0,0,0,transform{11}(1),transform{12}(1),transform{13}(1),1); 
        end
    end
    cd(path);
end

%In the Path that is given as input the ReferenceToRAS transform that is
%used when collecting data should be saved. This transform is the written
%to the output file

%find the ReferenceToRAS transform file
ReferenceToRASTransformFile = dir('ReferenceToRASTr*.tfm');
file = ReferenceToRASTransformFile.name;
fid = fopen(file);
while ~feof(fid)
    transform = textscan(fid, '%s%f%f%f%f%f%f%f%f%f%f%f%f', 'delimiter', ' ', 'headerLines', 3);
    %Write the transform to the output folder and add the fourth line [0,
    %0, 0, 1]
    fprintf(output, '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f\n',transform{2}(1),transform{3}(1),transform{4}(1),transform{5}(1),transform{6}(1),transform{7}(1),transform{8}(1),transform{9}(1),transform{10}(1),0,0,0,transform{11}(1),transform{12}(1),transform{13}(1), 1); 
end 

%In the same path the groundTruth point file should be saved. 
groundTruth = dir('groundTruth.fcsv');
file = groundTruth.name;
fid = fopen(file);
point = textscan(fid, '%s%f%f%f', 'delimiter', ',', 'headerLines', 18);
%write the x, y and z coordinate to the output.txt file with an extra 1 at
%the end so it can be used with the homogenous matrices
fprintf(output,'%f,%f,%f,%f\n', point{2}(1), point{3}(1), point{4}(1), 1);


fclose(output);

%send the generated file to a function to be read into appropriate
%variables. 
readFile('outputfile.txt');
end