function[] = determineError (numCollectedDataSets, imagePoints, ProbeToReference, ReferenceToRAS, groundTruth)    

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
    imagePoints_InProbe = zeros(4,4,numCollectedDataSets);
    imagePoints_InReference = zeros(4,4, numCollectedDataSets);
    groundTruth_InReference = zeros(1,4);
    groundTruth_InProbe = zeros(4,4, numCollectedDataSets);
    
    k = 1;
    
%     Move the groundTruth point from the RAS coordinate system to the
%     Reference coordinate system. 
    groundTruth_InReference = inv(ReferenceToRAS) * (groundTruth');
    
    for i=1:4
        
        %Move the image cross points from RAS coordinate 
        %system to reference coordinate system
        imagePoints_InReference(i,:,j) = inv(ReferenceToRAS) * (imagePoints(i,:,j)');      
        
% % 
% % 
% % 
% % 
% % ERROR CHECK: PLOT IMAGE POINTS IN THE REFERENCE COORDINATE SYSTEM.
% % ERROR CHECK BELOW THAT PLOTS GROUND TRUTH IN REFERENCE SHOULD ALSO BE 
% % UNCOMMENTED.       
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


        % Move groundTruth point and image cross points from reference
        % coordinate system to probe coordinate system. The same
        % ProbeToReference transform is applied to each point. 
        groundTruth_InProbe(i,:,j) = inv(ProbeToReference(k:k+3, :, j)) * (groundTruth_InReference);
        imagePoints_InProbe(i,:,j) =  inv(ProbeToReference(k:k+3, :, j)) * (imagePoints_InReference(i,:, j)');
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
        differences(i,:,j) = imagePoints_InProbe(i,1:3,j) - groundTruth_InProbe(i,1:3,j);
        plot3(differences(i,1,j), differences(i,2,j), differences(i,3,j), 'rx');
        hold on;
     end
end

% % 
% % 
% % 
% % ERROR CHECK: PLOTS THE GROUNDTRUTH POINT IN THE REFERENCE COORDINATE
% % SYSTEM. SHOULD BE UNCOMMENTED WITH ABOVE STATEMENT CHECKING IMAGEPOINTS IN 
% % REFERENCE COORDINATE SYSTEM.
% plot3(groundTruth_InReference(1,1), groundTruth_InReference(2,1), groundTruth_InReference(3,1), 'bx');
% % 
% % 
% % 

%Calculate the average difference for all points
totalError = [0,0,0]; %error in ImageToProbe transform
for i=1:numCollectedDataSets
    for j=1:4
        totalError = totalError + differences(j,1:3,i);
    end
end
totalError = totalError/(numCollectedDataSets * 4);
standardDev1 = std(differences, 0, 1);
standardDevFinal = std(standardDev1, 0, 3);

%Display average difference error
disp('Image-to-Reference transform error: ');
disp(totalError);

disp('Image-to-Reference transform error Standard Deviation: ');
disp(standardDevFinal);


%Label axis on graph
xlabel('x (Probe Depth)','FontSize',10);
ylabel('y (Probe Width - Parallel to Crystals)','FontSize',10);
zlabel('z (Probe Thickness - Perpendicular to Crystals)','FontSize',10);

end
