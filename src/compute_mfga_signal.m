function results = compute_mfga_signal(experiment, initial_signal, dtensor)
%COMPUTE_MFGA_SIGNAL Compute the Matrix Formalism Gaussian approximation signal.
%
%   experiment: struct with fields
%       ndirection
%    	direction
%     	qvalues
%     	bvalues
%    	sequences
% 	volumes
%	initial_density
% 	dtensor
%
%   results: struct with fields
%       signal_allcmpts
%   	adc_allcmpts


% Extract gradient directions
dir_points = experiment.directions.points;
dir_inds = experiment.directions.indices;
opposite = experiment.directions.opposite;

% Extract experiment parameters
bvalues = experiment.bvalues;

% Sizes
namplitude = size(bvalues, 1);
nsequence = size(bvalues, 2);
ndirection = size(dir_points, 2);

% Initialize output arguments
signal = zeros(namplitude, nsequence, ndirection);
adc = zeros(nsequence, ndirection);

% Compute signal
for idir = dir_inds
    g = dir_points(:, idir);
    for iseq = 1:nsequence
        b = experiment.bvalues(:, iseq);
        D = g' * dtensor(:, :, iseq) * g;
        adc(iseq, idir) = D;
        signal(:, iseq, idir) = initial_signal * exp(-D * b);
    end

    % Copy signal in oposite directions
    if ~isempty(opposite{idir})
        signal(:, :, opposite{idir}) = signal(:, :, idir);
        adc(:, opposite{idir}) = adc(:, idir);
    end
end

% Create output structure
results.signal_allcmpts = signal;
results.adc_allcmpts = adc;