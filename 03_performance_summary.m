%% 03_performance_summary.m
% Performance Summary Script
% This script loads the results from:
% 1. 01_quantization.m
% 2. 02_source_coding.m
%
% It compares the quantization and source coding methods using:
% - Alphabet size
% - Quantization MSE
% - Entropy
% - Fixed-length bits per sample
% - Huffman bits per sample
% - Total encoded bits

clc;
clear;
close all;

%% Load required result files

if ~isfile('quantization_results.mat')
    error('quantization_results.mat not found. Run 01_quantization.m first.');
end

if ~isfile('source_coding_results.mat')
    error('source_coding_results.mat not found. Run 02_source_coding.m first.');
end

load('quantization_results.mat');
load('source_coding_results.mat');

fprintf('Quantization and source coding results loaded successfully.\n');

%% Prepare method names and MSE values

method_names = {
    '2-Level';
    'Uniform M=4';
    'Uniform M=32';
    'Lloyd-Max M=16'
};

mse_values = [
    mse_2level;
    uniform_results(1).mse;
    uniform_results(2).mse;
    mse_lloyd
];

%% Build performance summary table

num_methods = length(method_names);

alphabet_size = zeros(num_methods, 1);
entropy_values = zeros(num_methods, 1);
fixed_bits_per_sample = zeros(num_methods, 1);
huffman_bits_per_sample = zeros(num_methods, 1);
fixed_total_bits = zeros(num_methods, 1);
huffman_total_bits = zeros(num_methods, 1);
block_entropy_rate = zeros(num_methods, 1);
block_fixed_bits_per_sample = zeros(num_methods, 1);

for m = 1:num_methods
    alphabet_size(m) = length(entropy_results(m).alphabet);
    entropy_values(m) = entropy_results(m).entropy;

    fixed_bits_per_sample(m) = fixed_results(m).bits_per_symbol;
    huffman_bits_per_sample(m) = huffman_results(m).average_code_length;

    fixed_total_bits(m) = fixed_results(m).total_bits;
    huffman_total_bits(m) = huffman_results(m).total_bits;

    block_entropy_rate(m) = block_results(m).entropy_rate;
    block_fixed_bits_per_sample(m) = block_results(m).bits_per_sample_fixed_block;
end

summary_table = table( ...
    method_names, ...
    alphabet_size, ...
    mse_values, ...
    entropy_values, ...
    fixed_bits_per_sample, ...
    huffman_bits_per_sample, ...
    fixed_total_bits, ...
    huffman_total_bits, ...
    block_entropy_rate, ...
    block_fixed_bits_per_sample, ...
    'VariableNames', { ...
        'Method', ...
        'AlphabetSize', ...
        'MSE', ...
        'Entropy_bits_per_symbol', ...
        'Fixed_bits_per_sample', ...
        'Huffman_bits_per_sample', ...
        'Fixed_total_bits', ...
        'Huffman_total_bits', ...
        'Block_entropy_rate', ...
        'Block_fixed_bits_per_sample' ...
    } ...
);

fprintf('\n=== End-to-End Performance Summary ===\n');
disp(summary_table);

%% Display interpretation

fprintf('\n=== Interpretation ===\n');

fprintf('\n1. Quantization distortion:\n');
fprintf('Lower MSE means the quantized signal is closer to the original signal.\n');
fprintf('The 2-level quantizer has the highest distortion because it uses only two amplitude levels.\n');
fprintf('Uniform quantization improves as M increases because more representation levels are available.\n');
fprintf('Lloyd-Max quantization adapts the representation levels to the signal distribution.\n');

fprintf('\n2. Source coding efficiency:\n');
fprintf('Fixed-length coding uses the same number of bits for every symbol.\n');
fprintf('Huffman coding assigns shorter codes to more frequent symbols and longer codes to less frequent symbols.\n');
fprintf('Therefore, Huffman coding usually achieves a lower average number of bits per symbol.\n');

fprintf('\n3. Entropy comparison:\n');
fprintf('Entropy represents the theoretical lower limit for lossless source coding.\n');
fprintf('A good Huffman code should have an average code length close to the entropy.\n');

fprintf('\n4. Block coding:\n');
fprintf('Block coding groups symbols together and can capture repeated patterns in the signal.\n');
fprintf('The block entropy rate helps compare block coding performance on a per-symbol basis.\n');

%% Plot MSE comparison

figure;
bar(mse_values);
set(gca, 'XTickLabel', method_names);
xtickangle(30);
ylabel('Mean Squared Error');
title('Quantization MSE Comparison');
grid on;

%% Plot source coding comparison

figure;
bar([fixed_bits_per_sample, huffman_bits_per_sample, entropy_values]);
set(gca, 'XTickLabel', method_names);
xtickangle(30);
ylabel('Bits per Symbol');
title('Fixed-Length Coding vs Huffman Coding vs Entropy');
legend('Fixed-Length', 'Huffman', 'Entropy', 'Location', 'best');
grid on;

%% Plot total encoded bits comparison

figure;
bar([fixed_total_bits, huffman_total_bits]);
set(gca, 'XTickLabel', method_names);
xtickangle(30);
ylabel('Total Bits');
title('Total Encoded Bits Comparison');
legend('Fixed-Length', 'Huffman', 'Location', 'best');
grid on;

%% Save summary table

writetable(summary_table, 'performance_summary.csv');

fprintf('\nPerformance summary saved to performance_summary.csv\n');
fprintf('Project completed successfully.\n');
