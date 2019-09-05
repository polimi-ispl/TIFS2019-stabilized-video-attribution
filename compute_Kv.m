%% Reference video fingerprint from videos only
% Reference:"Facing device attribution problem for stabilized video sequences"
% S Mandelli, P Bestagini, L Verdoliva, S Tubaro
% IEEE Transactions on Information Forensics and Security, 2019
% Implementation of Section III-B
% @author: Sara Mandelli - sara.mandelli@polimi.it

close all
clearvars
clc

%% addpath

addpath(genpath('CameraFingerprint'));

%% parameters

% maximum mutual shift
Delta = 10; % --> you can try also [5, 15, 20, 25, 30]

% frame size for Full-HD sequences
M = 1080;
N = 1920;

%% load I-frames and Noise residuals from the selected sequence
% N.B.: select an almost flat and static sequence

% I-frames (N x M x n_frames) --> uint8 gray-scale I-frames
i_frames = [];

% Noise residuals (N x M x n_frames)
i_noises = [];

n_frames = size(i_frames, 3);

%% Loop over all video frames and compute the mutual PCE

% relative PCE between frames
pce_frames = zeros(n_frames, n_frames);
% mutual shift between frames
loc_frames = zeros(n_frames, n_frames, 2);

% loop over all video frames
for f1 = 1:n_frames
    
    loop_frames = setdiff(1:n_frames, f1);
    
    % fix f1 as reference frame
    ref_noise = i_noises(:, :, f1);
    
    % loop over the remaining frames
    for f2 = loop_frames
        
        img = i_frames(:, :, f2);
        noise = i_noises(:, :, f2);
        
        % cross-correlation matrix
        C = crosscorr(ref_noise.*double(img), noise);
        
        % PCE
        detection = PCE(C, size(ref_noise)-1);
        % relative PCE between frames f1 and f2
        pce_frames(f1, f2) = detection.PCE;
        % mutual shift between frames f1 and f2
        loc_frames(f1, f2, :) = detection.PeakLocation;
        
    end
    
end

%% Analyze the relative PCE values in search for noise residual?s matching

% matrix containing the information on relative matching.
% loc_match = 0 if frames do not match
% loc_match = 1 if frames match
loc_match = zeros(n_frames, n_frames);

% loop over frames
for f1 = 2:n_frames % --> never consider the first I-frame
    
    loop_frames = setdiff(2:n_frames, f1);
    
    for f2 = loop_frames
        
        % check the constraints for the match
        if (loc_frames(f1, f2, 1) <= Delta || loc_frames(f1, f2, 1) >= M-Delta) ...
                && (loc_frames(f1, f2, 2) <= Delta || loc_frames(f1, f2, 2) >= N-Delta)
            
            loc_match(f1, f2) = 1;
            
        end
        
    end
    
end

%% Select the reference frame I_r

% auxiliary variable to save the relative PCE only if there is a match,
% otherwise pce_aux = 0
pce_aux = pce_frames;
pce_aux(loc_match == 0) = 0;

% maximum allowed value for PCE
pce_max = inf;
% minimum allowed value for PCE
pce_min = 0;

% count number of correlating frames per each reference frame
corr_f = zeros(n_frames, 1);
for f1 = 1: n_frames
    
    corr_f(f1) = sum(pce_aux(f1, :) <= pce_max & pce_aux(f1, :) > pce_min);
    
end

% reference frame index
[~, i_r] = max(corr_f);

% indices of frames that match with the reference one
corr_i = find(pce_aux(i_r, :) < pce_max & pce_aux(i_r, :) > pce_min);

% save the reference prnu from the reference frame
K_v = i_noises(:, :, i_r);

% number of used frames for computing the fingerprint
K_v_frames = 1; % --> at the beginning, only 1 frame, I_r

% set F_v of used noises for computing the fingerprint
Fvset_i_noises = K_v; % --> at the beginning, only i_noises(:, :, i_r)

%% Continue to loop until reaching the stopping conditions

% remaining frames
rem_frames = setdiff(2:n_frames, i_r); % --> never consider the first I-frame

% loop until there are no more correlating frames
while ~isempty(corr_i)
        
    % auxiliary variable to save noises compensated for their relative shift misalignment   
    shifted_w_aux = zeros(N, M, length(corr_i));
    
    % counter for matching frames
    cnt_match = 1;
    
    % loop on the correlating frames
    for i = corr_i
        
        img = i_frames(:, :, i);
        noise = i_noises(:, :, i);
        
        % correlate with K_v
        C = crosscorr(K_v.*double(img), noise);
        % PCE
        detection = PCE(C, size(K_v)-1);
        % peak location
        loc = detection.PeakLocation;
       
        % auxiliary variable
        noise_aux = noise;
        
        % check constraints on loc
        % If there is a match, compensate the shift
        if (loc(1) <= delta || loc(1) >= M-delta) && (loc(2) <= delta || loc(2) >= N-delta)
            
            if loc(1) > M/2 && loc(2) > N/2
                noise_aux = circshift(noise_aux, [M-loc(1), N-loc(2)]);
                noise_aux(1:M-loc(1), :)= 0;
                noise_aux(:, 1:N-loc(2)) = 0;
                
            elseif loc(1) < M/2 && loc(2) < N/2
                noise_aux = circshift(noise_aux, [-loc(1), -loc(2)]);
                noise_aux(end-loc(1)+1:end, :) = 0;
                noise_aux(:, end-loc(2)+1:end) = 0;

            elseif loc(1) < M/2 && loc(2) > N/2
                noise_aux = circshift(noise_aux, [-loc(1), N-loc(2)]);
                noise_aux(end-loc(1)+1:end, :) = 0;
                noise_aux(:, 1:N-loc(2)) = 0;

            elseif loc(1) > M/2 && loc(2) < N/2
                noise_aux = circshift(noise_aux, [M-loc(1), -loc(2)]);
                noise_aux(1:M-loc(1), :) = 0;
                noise_aux(:, end-loc(2)+1:end) = 0;

            end
            
            % save the shifted noise
            shifted_w_aux(:, :, cnt_match) = noise_aux;
            
            % update the counter
            cnt_match = cnt_match + 1;
            
        else
            
            % delete the index i from the set of correlating frames
            corr_i = setdiff(corr_i, i);
            
        end
        
    end
    
    % add matching frames to Fvset, and update the estimated fingerprint K_v
    
    K_v_aux = K_v;
    
    for i = 1:length(corr_i)
        
        Fvset_i_noises = cat(3, Fvset_i_noises, shifted_w_aux(:, :, i));
        
        % average the contributions of noise residuals
        K_v_aux = (K_v_aux.*(K_v_frames + i-1) + shifted_w_aux(:, :, i))./(K_v_frames + i);
      
    end
    
    % update K_v
    K_v = K_v_aux;
    % update the number of frames used for computing K_v
    K_v_frames = K_v_frames + length(corr_i);
    
    % check if there are other frames that correlate with K_v    
    rem_frames = setdiff(rem_frames, corr_i);
    
    if ~isempty(rem_frames) && ~isempty(corr_i)
        
        pce_rem = [];
        for i = rem_frames
            
            img = i_frames(:, :, i);
            noise = i_noises(:, :, i);
            
            % correlate with K_v
            C = crosscorr(K_v.*double(img), noise);
            % PCE
            detection = PCE(C, size(K_v)-1);
            pce_rem = [pce_rem; detection.PCE];
            
        end
        
        % add frames to corr_i if they satisfy the constraints
        corr_i = rem_frames(pce_rem > pce_min & pce_rem < pce_max);

    else
        
        corr_i = [];
        
    end    
    
end


