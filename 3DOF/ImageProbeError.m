%Takes a .txt file containing:

%Number of data sets collected: defined as image points
%collected at four different orientation with their correlated
%ProbeToReference transforms

%Image points: fiducial points collected in the RAS coordinate system at
%the position where the cross appears on the image

%ProbeToReference Transforms: ProbeToReference transforms for each Image 
%point collected in the RAS coordinate system. 

%ReferenceToRAS Transform

%GroundTruth: The ground truth position of the cross point collected in the
%RAS coordinate system. 

function[] = ImageProbeError (filename)    

%Open file containing the number of data sets collected and all points, 
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
    %Number of points in a layer of 3D matrix
    for i=1:4
        %x,y and z coorindate of a point collected and saved in RAS
        for j=1:3
            imagePoints(i,j,p) = fscanf(file, '%f', 1);
            %read in the coma delimiter from the file
            garbage = fscanf(file, '%c', 1);
        end
        %add one to the end of the point coordinates so it can be used with
        %a homogenous matrix
       imagePoints(i,4,p) = 1;

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
    for k =0:4:12
        %traverse through each row in the rotation matrix saved in the file
        for i=1:3
            %add x, y and z rotation values
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


%Read in the rotation matrix for the ReferenceToRAS transform
for p=1:3
    for j=1:3
        ReferenceToRAS(p,j) = fscanf(file, '%11f', 1);
        garbage = fscanf(file, '%c', 1);
    end
end
%Read in the translation matrix for the ReferenceToRAS transform
for i=1:3
    ReferenceToRAS(i,4) = fscanf(file, '%11f', 1);
    garbage = fscanf(file, '%c', 1);
end
%Add the fourth row of the transform
ReferenceToRAS(4,:) = [0,0,0,1];


%Read in the groundTruth point.
for i=1:3
    groundTruth(1,i) = fscanf(file, '%11f', 1);
    garbage = fscanf(file, '%c', 1);
end
groundTruth(1,4) = 1;

% %
% %
% %
% %ERROR CHECK: PLOT GROUNDTRUTH IN RAS COORDINATE SYSTEM WITH LABELED AXIS.
% %UNCOMMENT WITH ABOVE ERROR CHECK
% plot3(groundTruth(1,1), groundTruth(1,2), groundTruth(1,3), 'bx');
% xlabel('x','FontSize',16);
% ylabel('y','FontSize',16);
% zlabel('z','FontSize',16);
% %
% %
% %


%Define the LPStoRAS and RAStoLPS transforms. Will be used to move
%the transforms from the LPS coordinate system(the coordinate system which
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
    groundTruth_InReference = zeros(1,4);
    groundTruth_InProbe = zeros(4,4);
    
    k = 1;
    
    %Move the groundTruth point from the RAS coordinate system to the
    %Reference coordinate system. 
    groundTruth_InReference = inv(ReferenceToRAS) * (groundTruth');
    
    for i=1:4
        
        %Move the image cross points from RAS coordinate 
        %system to reference coordinate system
        imagePoints_InReference(i,:) = inv(ReferenceToRAS) * (imagePoints(i,:,j)');
% %
% %
% %
% %
% %ERROR CHECK: PLOT IMAGE POINTS IN THE REFERENCE COORDINATE SYSTEM.
% %ERROR CHECK BELOW THAT PLOTS GROUND TRUTH IN REFERENCE SHOULD ALSO BE 
% %UNCOMMENTED.       
% plot3(imagePoints_InReference(i,1), imagePoints_InReference(i,2), imagePoints_InReference(i,3), 'rx');
% hold on;       
% %
% %
% %
% %ERROR CHECK: PLOT DIFFERENCES BETWEEN THE IMAGE POINTS AND THE GROUNDTRUTH
% %POINT IN THE REFERENCE COORDINATE SYSTEM. ERROR CHECK BELOW THAT PLOTS
% %GROUND TRUTH IN REFERENCE SHOULD ALSO BE UNCOMMENTED.
% differences1(i,:,j) = imagePoints_InReference(i,1:3) - groundTruth_InReference(1:3,1)';
% plot3(differences1(i,1,j), differences1(i,2,j), differences1(i,3,j), 'rx');
% hold on;
% %
% %
% %

        %Move groundTruth point and image cross points from reference
        %coordinate system to probe coordinate system. The same
        %ProbeToReference transform is applied to each point. 
        groundTruth_InProbe(i,:) = inv(ProbeToReference(k:k+3, :, j)) * (groundTruth_InReference);
        imagePoints_InProbe(i,:) =  inv(ProbeToReference(k:k+3, :, j)) * (imagePoints_InReference(i,:)');
% %
% %
% %
% %ERROR CHECK: PLOT THE IMAGE POINTS IN THE PROBE COORDINATE SYSTEM.
% plot3(imagePoints_InProbe(i,1), imagePoints_InProbe(i,2), imagePoints_InProbe(i,3), 'rx');
% hold on;
% %
% %
% %
        k = k + 4;
        
        %Find and plot the difference between each imaged cross point and 
        %ground truth cross points transformed from RAS coordinate system 
        %to the Probe coordinate system
        differences(i,:,j) = imagePoints_InProbe(i,1:3) - groundTruth_InProbe(i,1:3);
        plot3(differences(i,1,j), differences(i,2,j), differences(i,3,j), 'rx');
        hold on;
     end
end
% %
% %
% %
% %ERROR CHECK: PLOTS THE GROUNDTRUTH POINT IN THE REFERENCE COORDINATE
% %SYSTEM. SHOULD BE UNCOMMENTED WITH ABOVE STATEMENT CHECKING IMAGEPOINTS IN 
%REFERENCE COORDINATE SYSTEM.
% plot3(groundTruth_InReference(1,1), groundTruth_InReference(2,1), groundTruth_InReference(3,1), 'bx');
% %
% %
% %

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
