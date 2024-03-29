function[] = RASToProbePointsTransform(numCollectedDataSets, imagePoints, ProbeToReference, ReferenceToRAS, groundTruth)    

%Define the LPStoRAS and RAStoLPS transforms. These will be used to move
%the transform from the LPS coordinate system(the coordinate system which
%their files are saved in) to the RAS coordinate system(where they were
%collected in slicer)
LPStoRAS = [-1,0,0,0;0,-1,0,0;0,0,1,0;0,0,0,1];
RAStoLPS = inv(LPStoRAS);

%Move the ProbeToReference transforms from the LPS to RAS coordinate system
    for k = 1:4:16*numCollectedDataSets
        %ProbeToReference = RAStoLPS * inv(ProbeToReference) * LPStoRAS
        ProbeToReference(k:k+3,:) = RAStoLPS * inv(ProbeToReference(k:k+3,:)) * LPStoRAS;
    end

%Move the ReferenceToRAS transform from the LPS to RAS coordinate system
ReferenceToRAS = RAStoLPS * inv(ReferenceToRAS) * LPStoRAS;

figure;

    numPoints = 0;
    %Predefine space for intermediate steps
    imagePoints_InProbe = zeros(4*numCollectedDataSets,4);
    imagePoints_InReference = zeros(4*numCollectedDataSets,4);
    groundTruth_InReference = zeros(1,4);
    groundTruth_InProbe = zeros(4*numCollectedDataSets,4);
    
    
    %Used to pull out a given ProbeToReference transform from the matrix
    %that holds all ProbeToReference transforms
    k = 1;
    
%     Move the groundTruth point from the RAS coordinate system to the
%     Reference coordinate system. 
    groundTruth_InReference = inv(ReferenceToRAS) * (groundTruth');
    
    for i=1:4*numCollectedDataSets
    
        numPoints = numPoints + 1;
        %Move the image cross points from RAS coordinate 
        %system to reference coordinate system
        imagePoints_InReference(i,:) = inv(ReferenceToRAS) * (imagePoints(i,:)');      
        
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


        % Move groundTruth point and image cross points from reference
        % coordinate system to probe coordinate system. The same
        % ProbeToReference transform is applied to each point. 
        groundTruth_InProbe(i,:) = inv(ProbeToReference(k:k+3,:)) * (groundTruth_InReference);
        imagePoints_InProbe(i,:) =  inv(ProbeToReference(k:k+3,:)) * (imagePoints_InReference(i,:)');
        
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

    end

    [s, R, T, e] = absoluteOrientationQuaternion(imagePoints_InProbe(:,1:3)', groundTruth_InProbe(:,1:3)');
    for i = 1:4*numCollectedDataSets
        imagePoints_InProbe_Transformed(i,:) = s*R*imagePoints_InProbe(i,1:3)' + T;
        plot3(groundTruth_InProbe(i,1), groundTruth_InProbe(i,2), groundTruth_InProbe(i,3), 'bo');
        hold on;
        plot3(imagePoints_InProbe_Transformed(i,1), imagePoints_InProbe_Transformed(i,2), imagePoints_InProbe_Transformed(i,3), 'rx');
    end
    
disp('Scale Matrix: ');
disp(s)
disp('Rotation Matrix: ');
disp(R);
disp('Translation Vector: ');
disp(T);
disp('Error: ');
disp(e);


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


%Label axis on graph
xlabel('x (Probe Depth)','FontSize',10);
ylabel('y (Probe Width - Parallel to Crystals)','FontSize',10);
zlabel('z (Probe Thickness - Perpendicular to Crystals)','FontSize',10);

end
