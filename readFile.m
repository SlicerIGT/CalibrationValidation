%Using the file generated in formatFile.m we read the saved values into
%variables to be used for analysis. 

function[numCollectedDataSets, imagePoints, ProbeToReference, ReferenceToRAS, groundTruth] = readFile(filename)

%Open file that contains the number of data sets collected and all points, 
%ProbeToReference transforms,ReferenceToRAS transform and ground truth point 
file = fopen(filename);

%Read in the number of data sets collected. The total number of points will
%be four times this number
numCollectedDataSets(1,1) = fscanf(file, '%f', 1);

%predefine space for data
imagePoints = zeros(4,4,numCollectedDataSets);
ProbeToReference = zeros(16,4,numCollectedDataSets);
ReferenceToRAS = zeros(4,4);
groundTruth = zeros(1,4);

%Read in points collected

%Each data set collected (every four points) will be in it's own layer of a 
%3D matrix 
for p=1:numCollectedDataSets
    for i=1:4
        for j=1:4

            %read in the x, y and z coordinates of each points
            imagePoints(i,j,p) = fscanf(file, '%f', 1);
            %read in the coma delimiter from the file
            garbage = fscanf(file, '%c', 1);
        end
% %
% %
% %
% %ERROR CHECK: PLOT POINTS IN RAS COORDINATE SYSTEM
% plot3(imagePoints(i,1,p), imagePoints(i,2,p), imagePoints(i,3,p), 'rx');
% hold on;
% %
% %
% %
    end
end

%Each data set collected (four ProbeToReference transforms) will be in it's
%own layer of a 3D matrix
for p=1:numCollectedDataSets
    %12 of the 16 rows for the transforms are saved in the file. The bottom
    %line ([0,0,0,1]) is added after the rotation and translation values
    %have been read in 
    for k =0:4:12
        for i=1:4
            %Read in the rotation matrix
            for j=1:3
                ProbeToReference(i+k,j,p) = fscanf(file,'%f', 1);
                garbage = fscanf(file, '%c', 1);
            end
        end
        %Read in the translation vector
        for i=1:4
            ProbeToReference(i+k,4,p) = fscanf(file, '%f',1);
            garbage = fscanf(file, '%c', 1);
        end 
    end
end


%Read in the rotation matrix for the ReferenceToRAS transform
for p=1:4
    for j=1:3
        ReferenceToRAS(p,j) = fscanf(file, '%11f', 1);
        garbage = fscanf(file, '%c', 1);
    end
end
%Read in the translation matrix for the ReferenceToRAS transform
for i=1:4
    ReferenceToRAS(i,4) = fscanf(file, '%11f', 1);
    garbage = fscanf(file, '%c', 1);
end


%Read in the groundTruth point. This is the cross points of the two wires
%in the phantom coordinate system
for i=1:4
    groundTruth(1,i) = fscanf(file, '%11f', 1);
    garbage = fscanf(file, '%c', 1);
end
% % 
% % 
% % 
% % ERROR CHECK: PLOT GROUNDTRUTH IN RAS COORDINATE SYSTEM WITH LABELED AXIS.
% % UNCOMMENT WITH ABOVE ERROR CHECK
% plot3(groundTruth(1,1), groundTruth(1,2), groundTruth(1,3), 'bx');
% xlabel('x','FontSize',16);
% ylabel('y','FontSize',16);
% zlabel('z','FontSize',16);
% % 
% % 
% % 

%send generated variables to determineError where they will be analyzed
determineError(numCollectedDataSets, imagePoints, ProbeToReference, ReferenceToRAS, groundTruth);

end