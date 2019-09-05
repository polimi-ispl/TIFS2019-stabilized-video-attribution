function pce_negative = computePCE_similarity(x, noise, img, K)
% Reference:"Facing device attribution problem for stabilized video sequences"
% S Mandelli, P Bestagini, L Verdoliva, S Tubaro
% IEEE Transactions on Information Forensics and Security, 2019
% @author: Sara Mandelli - sara.mandelli@polimi.it
% compute the PCE between the warped K by similarity and the query frame
% INPUT:
% x = [scaling_factor, rotation_angle]
% noise = noise residual of the frame
% img = gray-scale intensity of the frame (uint8)
% K = device reference fingerprint
% OUTPUT:
% pce_negative = negative value of the computed PCE
% N.B.: search for the minimum value of the negative PCE by means of the
% Particle Swarm algorithm, in order to find the global maximum of PCE. 

% define geometrical transformations
% rotation
t1 = [cos(x(2)), -sin(x(2)), 0;...
    sin(x(2)), cos(x(2)), 0;...
    0, 0, 1];
% scale
t2 = [x(1), 0, 0;...
    0, x(1), 0; ...
    0, 0, 1];
% complete transformation
t = t2*t1;
tform = affine2d(t);

ref = imref2d(size(noise));

% warp the device reference fingerprint
[warped_K,~] = imwarp(K,tform,'OutputView',ref, 'interp', 'cubic');

% cross-correlation
C = crosscorr(noise, double(img).*warped_K);
% PCE
detection = PCE(C, size(noise)-1);

pce_negative = -detection.PCE;

end
