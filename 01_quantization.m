%% 01_quantization.m
% Signal Quantization Project
% This script applies different quantization methods to a sampled signal:
% 1. Two-level quantization
% 2. Uniform quantization with M = 4 and M = 32
% 3. Lloyd-Max quantization with M = 16
%
% The script also calculates the mean squared error (MSE) for each method
% and plots the original and reconstructed signals.

clc;
clear;
close all;

%% Generate sampled signal

fs = 1000;                       % Sampling frequency in Hz
time = 0:1/fs:1-1/fs;             % Time vector
x = cos(2*pi*5*time);             % Sampled cosine signal

fprintf('Original sampled signal generated successfully.\n');

%% Part A: Two-level quantization

% Since this is a 2-level quantizer, there is one threshold and two levels.
thresholds_2level = 0;
levels_2level = [-1, 1];

xq_2level = quan(x, thresholds_2level, levels_2level);

% Mean squared error for 2-level quantization
mse_2level = mean((x - xq_2level).^2);

fprintf('\n2-Level Quantization:\n');
fprintf('MSE = %.6f\n', mse_2level);

%% Part B: Plot original and 2-level quantized signal

figure('Position', [100 100 1200 400]);

subplot(1,2,1);
plot(time, x, 'LineWidth', 1.5);
title('Original Signal');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

subplot(1,2,2);
plot(time, xq_2level, 'LineWidth', 1.5);
title('2-Level Quantized Signal');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

%% Part C: Uniform multi-level quantization

M_values = [4, 32];
uniform_results = struct();

for j = 1:length(M_values)

    M = M_values(j);

    xmin = min(x);
    xmax = max(x);

    % Step size / region width
    delta = (xmax - xmin) / M;

    % Representation levels are the midpoints of the regions
    levels = xmin + (0.5 + (0:M-1)) * delta;

    % Quantize each sample to the closest representation level
    xq_uniform = zeros(size(x));

    for n = 1:length(x)
        [~, idx] = min(abs(x(n) - levels));
        xq_uniform(n) = levels(idx);
    end

    % Calculate MSE
    mse_uniform = mean((x - xq_uniform).^2);

    % Store results
    uniform_results(j).M = M;
    uniform_results(j).levels = levels;
    uniform_results(j).xq = xq_uniform;
    uniform_results(j).mse = mse_uniform;

    fprintf('\nUniform Quantization with M = %d:\n', M);
    fprintf('MSE = %.6f\n', mse_uniform);
end

%% Part D: Plot uniform quantization results

figure('Position', [100 100 1200 600]);

subplot(3,1,1);
plot(time, x, 'LineWidth', 1.5);
title('Original Signal');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

subplot(3,1,2);
plot(time, uniform_results(1).xq, 'LineWidth', 1.5);
title('Uniform Quantization with M = 4');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

subplot(3,1,3);
plot(time, uniform_results(2).xq, 'LineWidth', 1.5);
title('Uniform Quantization with M = 32');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

%% Part E: Lloyd-Max quantization

M_lloyd = 16;
xmin = min(x);
xmax = max(x);

% Initial representation levels are uniformly distributed
levels_lloyd = linspace(xmin, xmax, M_lloyd);

epsilon = 1e-6;
mse_previous = inf;
max_iterations = 1000;
iteration = 0;

while true

    iteration = iteration + 1;

    % Compute thresholds as midpoints between representation levels
    thresholds_lloyd = zeros(1, M_lloyd + 1);
    thresholds_lloyd(1) = xmin;
    thresholds_lloyd(end) = xmax;

    for j = 2:M_lloyd
        thresholds_lloyd(j) = (levels_lloyd(j-1) + levels_lloyd(j)) / 2;
    end

    % Quantize signal using current thresholds and levels
    xq_lloyd = zeros(size(x));

    for n = 1:length(x)
        for j = 1:M_lloyd
            if j == M_lloyd
                if x(n) >= thresholds_lloyd(j) && x(n) <= thresholds_lloyd(j+1)
                    xq_lloyd(n) = levels_lloyd(j);
                    break;
                end
            else
                if x(n) >= thresholds_lloyd(j) && x(n) < thresholds_lloyd(j+1)
                    xq_lloyd(n) = levels_lloyd(j);
                    break;
                end
            end
        end
    end

    % Update representation levels to centroids
    new_levels = zeros(size(levels_lloyd));

    for j = 1:M_lloyd
        assigned_samples = x(xq_lloyd == levels_lloyd(j));

        if ~isempty(assigned_samples)
            new_levels(j) = mean(assigned_samples);
        else
            new_levels(j) = levels_lloyd(j);
        end
    end

    % Calculate MSE
    mse_lloyd = mean((x - xq_lloyd).^2);

    % Stop if converged or if maximum iterations is reached
    if abs(mse_previous - mse_lloyd) < epsilon || iteration >= max_iterations
        break;
    end

    levels_lloyd = new_levels;
    mse_previous = mse_lloyd;
end

fprintf('\nLloyd-Max Quantization with M = %d:\n', M_lloyd);
fprintf('Number of iterations = %d\n', iteration);
fprintf('Final MSE = %.6f\n', mse_lloyd);
fprintf('Representation levels:\n');
disp(levels_lloyd);

%% Part F: Plot Lloyd-Max reconstruction and error

figure;

subplot(3,1,1);
plot(time, x, 'LineWidth', 1.5);
title('Original Signal');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

subplot(3,1,2);
plot(time, xq_lloyd, 'LineWidth', 1.5);
title('Lloyd-Max Reconstructed Signal');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

subplot(3,1,3);
plot(time, x - xq_lloyd, 'LineWidth', 1.5);
title('Error Signal: Original - Lloyd-Max Reconstruction');
xlabel('Time (s)');
ylabel('Error');
grid on;

%% Part G: Compare first 10 samples

fprintf('\nOriginal vs Reconstructed Values - First 10 Samples:\n');
fprintf('Sample\tOriginal\t2-Level\t\tUniform M=4\tUniform M=32\tLloyd-Max\n');

for n = 1:10
    fprintf('%d\t%.4f\t\t%.4f\t\t%.4f\t\t%.4f\t\t%.4f\n', ...
        n, ...
        x(n), ...
        xq_2level(n), ...
        uniform_results(1).xq(n), ...
        uniform_results(2).xq(n), ...
        xq_lloyd(n));
end

%% Part H: Save results for the next scripts

save('quantization_results.mat', ...
    'x', ...
    'time', ...
    'fs', ...
    'xq_2level', ...
    'uniform_results', ...
    'xq_lloyd', ...
    'mse_2level', ...
    'mse_lloyd');

fprintf('\nQuantization results saved to quantization_results.mat\n');
fprintf('This file will be used by the source coding and performance scripts.\n');

%% Local helper function

function xq = quan(x, thresholds, levels)
    % This function performs scalar quantization.
    % x: input signal
    % thresholds: decision thresholds
    % levels: representation levels

    xq = zeros(size(x));

    for i = 1:length(levels)
        if i == 1
            xq(x <= thresholds(1)) = levels(1);
        elseif i == length(levels)
            xq(x > thresholds(end)) = levels(end);
        else
            xq(x > thresholds(i-1) & x <= thresholds(i)) = levels(i);
        end
    end
end
