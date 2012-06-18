function[] = ImageProbeError (filename)

%Open file that contains the number of data sets collected and all points, 
%ProbeToReference transforms,ReferenceToRAS transform and ground truth point 
file = fopen(filename);

%Read in the number of data sets collected. The total number of points will
%be four times this number
numCollectedDataSets(1,1) = fscanf(file, '%d', 1);

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
        for j=1:3
            %read in the x, y and z coordinates of each points
            imagePoints(i,j,p) = fscanf(file, '%f', 1);
            %read in the coma delimiter from the file
            garbage = fscanf(file, '%c', 1);
        end
        %add one to the end of the point coordinates so it can be used with
        %a homogenous matrix
        imagePoints(i,4,p) = 1;
    end
end

%Each data set collected (four ProbeToReference transforms) will be in it's
%own layer of a 3D matrix
for p=1:numCollectedDataSets
    %12 of the 16 rows for the transforms are saved in the file. The bottom
    %line ([0,0,0,1]) is added after the rotation and translation values
    %have been read in 
    for k =0:4:12
        for i=1:3
            %Read in the rotation matrix
            for j=1:3
                ProbeToReference(i+k,j,p) = fscanf(file,'%f', 1);
                garbage = fscanf(file, '%c', 1);
            end
        end
        %Read in the translation vector
        for i=1:3
            ProbeToReference(i+k,4,p) = fscanf(file, '%f',1);
            garbage = fscanf(file, '%c', 1);
        end
        %add the fourth row  
        ProbeToReference(k+4,:,p) = [0,0,0,1];
    end
end

%There is only one ReferenceToRAS transform to read in

%Read in the rotation matrix for the ReferenceToRAS transform
for p=1:3
    for j=1:3
        ReferenceToRAS(p,j) = fscanf(file, '%f', 1);
        garbage = fscanf(file, '%c', 1);
    end
end
%Read in the translation matrix for the ReferenceToRAS transform
for i=1:3
    ReferenceToRAS(i,4) = fscanf(file, '%f', 1);
    garbage = fscanf(file, '%c', 1);
end
%Add the fourth row of the transform
ReferenceToRAS(4,:) = [0,0,0,1];

%Read in the groundTruth point. This is the cross points of the two wires
%in the phantom coordinate system
for i=1:3
    groundTruth(1,i) = fscanf(file, '%f', 1);
    garbage = fscanf(file, '%c', 1);
end
%Add one to the end of the point so it can be used with the homogenous
%matrices
groundTruth(1,4) = 1;


%Define the LPStoRAS and RAStoLPS transforms. These will be used to move
%the transform from the LPS coordinate system(the coordinate system which
%their files are saved in) to the RAS coordinate system(where they were
%collected in slicer)
LPStoRAS = [-1,0,0,0;0,-1,0,0;0,0,1,0;0,0,0,1];
RAStoLPS = inv(LPStoRAS);

%Move the ProbeToReference transforms from the LPS to RAS coordinate system
for p=1:numCollectedDataSets
    for k = 1:4:13
        %ProbeToReference = RAStoLPS * inv(ProbeToReference) * LPStoRAS
        ProbeToReference(k:k+3,:,p) = RAStoLPS * inv(ProbeToReference(k:k+3,:,p)) * LPStoRAS;
    end
end

%Move the ReferenceToRAS transform from the LPS to RAS coordinate system
ReferenceToRAS = RAStoLPS * inv(ReferenceToRAS) * LPStoRAS;

%Predefine space for the differences between the groundTruth point and the
%collected fiducial points in the RAS system
differences = zeros(4,3,5);
figure;


for j=1:numCollectedDataSets
    
    %Predefine space for intermediate steps
    imagePoints_InProbe = zeros(4,4);
    imagePoints_InReference = zeros(4,4);
    groundTruth_InReference = zeros(4,1);
    groundTruth_InProbe = zeros(4,4);
    
    k = 1;
    
    %Move the groundTruth point from the RAS coordinate system to the
    %Reference coordinate system. 
    groundTruth_InReference = inv(ReferenceToRAS) * (groundTruth');
    
    for i=1:4
        
        %Move the image cross points from RAS coordinate 
        %system to reference coordinate system
        imagePoints_InReference(i,:) = inv(ReferenceToRAS) * (imagePoints(i,:,j)');

        %Move groundTruth point and image cross points from reference
        %coordinate system to probe coordinate system. The same
        %ProbeToReference transform is applied to each point. 
        groundTruth_InProbe(i,:) = inv(ProbeToReference(k:k+3, :, j))*(groundTruth_InReference);
        imagePoints_InProbe(i,:) = inv(ProbeToReference(k:k+3, :, j))*(imagePoints_InReference(i,:)');

        k = k + 4;
        
        %Find and plot the difference between each imaged cross point and 
        %ground truth cross points transformed from RAS coordinate system 
        %to the Probe coordinate system
        differences(i,:,j) = imagePoints_InProbe(i,1:3) - groundTruth_InProbe(i,1:3);
        plot3(differences(i,1,j), differences(i,2,j), differences(i,3,j), 'rx');
        hold on;
    end
end

%Calculate the average difference for all points
avgDiff = [0,0,0]; %error in ImageToProbe transform
for i=1:numCollectedDataSets
    for j=1:4
        avgDiff = avgDiff + differences(j,1:3,i);
    end
end
avgDiff = avgDiff/(numCollectedDataSets * 4);

%Display average difference error
disp('ImageToProbe transform error: ');
disp(avgDiff);

%Label axis on graph
xlabel('x','FontSize',16);
ylabel('y','FontSize',16);
zlabel('z','FontSize',16);

end
