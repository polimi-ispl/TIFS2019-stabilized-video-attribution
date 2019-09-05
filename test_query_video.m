%% Testing the video query
% Reference:"Facing device attribution problem for stabilized video sequences"
% S Mandelli, P Bestagini, L Verdoliva, S Tubaro
% IEEE Transactions on Information Forensics and Security, 2019
% Implementation of Section IV
% @author: Sara Mandelli - sara.mandelli@polimi.it

close all
clearvars
clc

%% addpath

addpath(genpath('CameraFingerprint'));

%% Particle Swarm parameters

% number of variables to estimate
nvars = 2;
% options for the optimization
options_pce = optimoptions('particleswarm','SwarmSize',50, ...
    'UseParallel', true, 'MaxStallIterations', 20,'FunctionTolerance', 5e-4, ...
    'SelfAdjustmentWeight',1.49, 'SocialAdjustmentWeight', 1.49, ...
    'MaxIterations', 50);
% lower and upper bounds
theta_min = -.15;
theta_max = .15;
scale_min = .99;
scale_max = 1.01;
lower_b = [scale_min; theta_min];
upper_b = [scale_max; theta_max];

%% other parameters

% frame size for Full-HD sequences
M = 1080;
N = 1920;

% max number of tested frames
F = 10;

%% load device reference fingerprint (either Kiv or Kv)

K = [];

%% load I-frames and Noise residuals from the selected sequence

% I-frames (N x M x n_frames) --> uint8 gray-scale I-frames
i_frames = [];

% Noise residuals (N x M x n_frames)
i_noises = [];

n_frames = size(i_frames, 3);

%% select nf frames for the test

% do not consider first frame
test_frames = setdiff(randperm(n_frames, F), 1);

% loop until you select F test_frames
while length(test_frames) < F
    
    test_frames =  setdiff(randperm(size(i_frames, 3), F), 1);
    
end

%% test nf frames using the complete test strategy

cnt_frames = 1;

% define the estimated transformation for each frame (scaling factor and rotation angle)
tx_est = zeros(F, 2);

% define Pf value for each frame (containing the obtained PCE, as described
% in eq.(12) of the reference paper
Pf = zeros(F, 1);

for f = test_frames
    
    img = i_frames(:, :, f);
    noise = i_noises(:, :, f);
    
    %%% estimate the transformation which register the frame on the
    %%% reference fingerprint and compute the PCE
    func = @(x) computePCE_similarity(x, noise, img, K);
   
    [tx_est(cnt_frames, :), fval, exitflag, output] = particleswarm(func, ...
        nvars, lower_b, upper_b, options_pce);
    
    % assign to Pf the negative value of fval
    Pf(cnt_frames) = -fval;
    
    cnt_frames = cnt_frames + 1;
    
end

% P_comp value of the video query as defined in eq.(13) of the reference
% paper
P_comp = max(Pf);

%% test nf frames using the quick test strategy

cnt_frames = 1;

% auxiliary variable to save the resulting PCE for each frame
P_aux = zeros(F, 1);

for f = test_frames
    
    img = i_frames(:, :, f);
    noise = i_noises(:, :, f);
    
    %%% estimate the transformation which register the frame with the
    
    C = crosscorr(K.*double(img), noise);
    detection = PCE(C, size(K)-1);
    P_aux(cnt_frames) = detection.PCE;
    
    cnt_frames = cnt_frames + 1;
    
end

% P_quick value of the video query as defined in eq.(14) of the reference
% paper
P_quick = max(P_aux);


