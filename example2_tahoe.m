% =========================================================================
% This demo illustrates the CB-STAR and CT-STAR methods, for
% tensor-decompositon image fusion, described in the reference below, using
% the Lake Tahoe data (which contains variability).
% 
% For more details please see the following reference:
% 
%    Coupled tensor decomposition for hyperspectral and multispectral image fusion with inter-image variability
%    R.A. Borsoi, C. Prévost, K. Usevich, D. Brie, J.C.M. Bermudez, C. Richard
%    IEEE Journal of Selected Topics in Signal Processing 15 (3), 702-717, 2021.
% 
% =========================================================================



addpath(genpath('DATA'))
addpath(genpath('utils'))
addpath(genpath('other_methods'))
addpath(genpath('ALGS'))
addpath(genpath('method_adaptors'))

warning off;
clear all
clc

clus = gcp('nocreate'); % If no pool, do not create new one.
if isempty(clus)
    c = parcluster('local');
    c.NumWorkers = 1; 5;
    parpool(c, c.NumWorkers);
end

rng(10, 'twister') 



load('DATA/Tahoe_preproc_t1.mat')
clear MSI; load('DATA/MSI_tahoe_better_registered.mat') % load a better registered MSI
R = SRF;


MSI(MSI<1e-3) = 1e-3;
HSI(HSI<1e-3) = 1e-3;
MSI(MSI>1)=1;
HSI(HSI>1)=1;

MSim = MSI;
HSim = HSI;

MSp = zeros(size(MSim));
for i=1:size(MSim,3)
    x = MSim(:,:,i);
    xmax  = quantile(x(:),0.999);
    % Normalize to 1
    x = x/xmax;
    MSp(:,:,i) = x;
end
MSI = MSp;

HSp = zeros(size(HSim));
for i=1:size(HSim,3)
    x = HSim(:,:,i);
    xmax  = quantile(x(:),0.999);
    %normalize to 1
    x = x/xmax;
    HSp(:,:,i) = x;
end
HSI = HSp;

% Signal to noise ratio of HS and MS images
SNR_h = 30;
SNR_m = 40;

% Decimation factor:
decimFactor = 2;

L   = size(HSI,3);
L_l = size(MSI,3);
M1  = size(HSI,1);
M2  = size(HSI,2);
N1  = M1/decimFactor;
N2  = M2/decimFactor;

% Get MSI and HR HSI
Ym = MSI;
Zh = denoising(HSI);
Zh_th = Zh;

% setup

d1 = decimFactor; d2 = decimFactor; qq = 4; 
[P1,P2,Phi1,Phi2] = spatial_deg2(Zh_th, qq, d1, d2, 1); 
Pm = R;

Yh = tmprod(tmprod(Zh_th,P1,1),P2,2);

% add noise
Yh = Yh + sqrt(sum((Yh(:)).^2)/N1/N2/L/10^(SNR_h/10)) * randn(size(Yh));
Ym = Ym + sqrt(sum((Ym(:)).^2)/M1/M2/L_l/10^(SNR_m/10)) * randn(size(Ym));



%% run all methods

P = 30;

methods = {'HySure','hysure_adaptor','[]',P;
           'CNMF','cnmf_adaptor','[]',40;
           'GLPHS','glphs_adaptor','[]',[];
           'FuVar','fuvar_adaptor','[]',P;
           %'LTMR','ltmr_adaptor','[]',{20,1e-3};
           'STEREO','stereo_adaptor','30',[];
           'SCOTT','scott_adaptor','[40 40 7]',[];
           'CT-STAR','ctstar_adaptor','[30 30 10]',[3,3,1];
           'CB-STAR','cbstar_adaptor','[35 35 9]',{[50,50,4],1};
           };

DegMat = struct('Pm', Pm, 'P1', P1, 'P2', P2);
[res, est, optOut] = compare_methods(Zh_th, Yh, Ym, DegMat, decimFactor, methods);

res2 = cell(size(methods,1)+1, 6);
res2(1,:) = {'Method', 'SAM', 'ERGAS', 'PSNR', 'UIQI', 'Time'}; % SAM (< better), ERGAS (< better), PSNR (> better), UIQI (> better)
res2(2:end,:) = res;
res2



% error('stopping before plots.')



%% Plot stuff
alg_names = {'FuVar','STEREO','SCOTT','CT-STAR','CB-STAR'};
est = est([4:8]);
plot_results(Zh_th, est, alg_names, 'results_examples/ex1_tahoe');


% try to plot Psi ---------------------------
plot_psis({optOut{7}{2},optOut{8}{2}}, 'results_examples/estimPsis/ex1_tahoe_both_algs', {'CT-STAR','CB-STAR'})

save_results('results_examples/ex1_tahoe.txt', res2)






