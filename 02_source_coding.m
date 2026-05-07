%% 02_source_coding.m
% Source Coding Project
% This script uses the quantized signals generated in 01_quantization.m.
% It applies:
% 1. Fixed-length coding
% 2. Empirical probability modeling
% 3. Entropy calculation
% 4. Manual Huffman coding
% 5. Block coding with block length k = 2

clc;
clear;
close all;

%% Load quantization results

if ~isfile('quantization_results.mat')
    error('quantization_results.mat not found. Run 01_quantization.m first.');
end

load('quantization_results.mat');

fprintf('Quantization results loaded successfully.\n');

%% Prepare quantized signals

quantized_signals = {
    xq_2level;
    uniform_results(1).xq;
    uniform_results(2).xq;
    xq_lloyd
};

method_names = {
    '2-Level';
    'Uniform M=4';
    'Uniform M=32';
    'Lloyd-Max M=16'
};

%% Part A: Fixed-length source coding and decoding

fprintf('\n========================================\n');
fprintf('PART A: Fixed-Length Source Coding\n');
fprintf('========================================\n');

fixed_results = struct();

for m = 1:length(quantized_signals)

    xq_input = quantized_signals{m};

    % Alphabet of unique quantization levels
    alphabet = unique(xq_input);
    num_levels = length(alphabet);

    % Number of bits needed per symbol
    bits_per_symbol = ceil(log2(num_levels));

    fprintf('\nMethod: %s\n', method_names{m});
    fprintf('Alphabet size = %d\n', num_levels);
    fprintf('Fixed-length code = %d bits/symbol\n', bits_per_symbol);

    % Build fixed-length dictionary
    dictionary = cell(num_levels, 2);

    for k = 1:num_levels
        dictionary{k, 1} = alphabet(k);
        dictionary{k, 2} = dec2bin(k-1, bits_per_symbol);
    end

    % Encode signal into bitstream
    encoded_stream = '';

    for n = 1:length(xq_input)
        idx = find(alphabet == xq_input(n), 1);
        encoded_stream = [encoded_stream dictionary{idx, 2}];
    end

    total_bits = length(encoded_stream);
    bit_rate = total_bits / length(xq_input);

    fprintf('Encoded bitstream length = %d bits\n', total_bits);
    fprintf('Bit rate = %.2f bits/sample\n', bit_rate);

    % Decode bitstream back into quantized values
    decoded_signal = zeros(size(xq_input));

    for n = 1:length(xq_input)
        start_idx = (n-1) * bits_per_symbol + 1;
        end_idx = start_idx + bits_per_symbol - 1;
        bits = encoded_stream(start_idx:end_idx);

        for j = 1:num_levels
            if strcmp(dictionary{j, 2}, bits)
                decoded_signal(n) = dictionary{j, 1};
                break;
            end
        end
    end

    % Check reconstruction
    if isequal(decoded_signal, xq_input)
        fprintf('Decoding successful: perfect reconstruction.\n');
    else
        fprintf('Warning: decoding mismatch.\n');
    end

    % Store results
    fixed_results(m).method = method_names{m};
    fixed_results(m).alphabet = alphabet;
    fixed_results(m).dictionary = dictionary;
    fixed_results(m).encoded_stream = encoded_stream;
    fixed_results(m).total_bits = total_bits;
    fixed_results(m).bits_per_symbol = bit_rate;
end

%% Part B: Empirical probability modeling and entropy

fprintf('\n========================================\n');
fprintf('PART B: Empirical Probabilities and Entropy\n');
fprintf('========================================\n');

entropy_results = struct();

for m = 1:length(quantized_signals)

    xq_input = quantized_signals{m};

    alphabet = unique(xq_input);
    num_levels = length(alphabet);
    total_samples = length(xq_input);

    counts = zeros(1, num_levels);

    for i = 1:num_levels
        counts(i) = sum(xq_input == alphabet(i));
    end

    probabilities = counts / total_samples;

    % Entropy formula: H(A) = -sum p(a) log2 p(a)
    entropy_value = -sum(probabilities .* log2(probabilities));

    fprintf('\nMethod: %s\n', method_names{m});
    fprintf('Alphabet size = %d\n', num_levels);
    fprintf('Symbol probabilities:\n');

    for i = 1:num_levels
        fprintf('  %.4f : %.4f\n', alphabet(i), probabilities(i));
    end

    fprintf('Entropy H(A) = %.4f bits/symbol\n', entropy_value);

    % Store results
    entropy_results(m).method = method_names{m};
    entropy_results(m).alphabet = alphabet;
    entropy_results(m).counts = counts;
    entropy_results(m).probabilities = probabilities;
    entropy_results(m).entropy = entropy_value;
end

%% Part C: Manual Huffman coding

fprintf('\n========================================\n');
fprintf('PART C: Manual Huffman Coding\n');
fprintf('========================================\n');

huffman_results = struct();

for m = 1:length(quantized_signals)

    xq_input = quantized_signals{m};

    alphabet = entropy_results(m).alphabet;
    probabilities = entropy_results(m).probabilities;

    % Build Huffman tree
    nodes = cell(length(alphabet), 1);

    for i = 1:length(alphabet)
        nodes{i} = struct( ...
            'symbol', alphabet(i), ...
            'prob', probabilities(i), ...
            'left', [], ...
            'right', [] ...
        );
    end

    while length(nodes) > 1

        % Sort nodes by increasing probability
        [~, idx] = sort(cellfun(@(node) node.prob, nodes));
        nodes = nodes(idx);

        % Merge the two nodes with smallest probabilities
        left = nodes{1};
        right = nodes{2};

        merged_node = struct( ...
            'symbol', [], ...
            'prob', left.prob + right.prob, ...
            'left', left, ...
            'right', right ...
        );

        nodes = [nodes(3:end); {merged_node}];
    end

    huffman_tree = nodes{1};

    % Assign Huffman codes
    dictionary = assignHuffmanCodes(huffman_tree, '');

    % Encode signal using Huffman dictionary
    encoded_stream = '';

    for n = 1:length(xq_input)
        idx = find(cell2mat(dictionary(:, 1)) == xq_input(n), 1);
        encoded_stream = [encoded_stream dictionary{idx, 2}];
    end

    % Decode Huffman bitstream
    decoded_signal = zeros(size(xq_input));
    bit_index = 1;

    for n = 1:length(xq_input)
        for j = 1:size(dictionary, 1)
            code = dictionary{j, 2};
            code_length = length(code);

            if bit_index + code_length - 1 <= length(encoded_stream)
                current_bits = encoded_stream(bit_index:bit_index + code_length - 1);

                if strcmp(current_bits, code)
                    decoded_signal(n) = dictionary{j, 1};
                    bit_index = bit_index + code_length;
                    break;
                end
            end
        end
    end

    % Calculate average code length
    code_lengths = cellfun(@length, dictionary(:, 2));
    average_code_length = sum(probabilities(:) .* code_lengths(:));

    fprintf('\nMethod: %s\n', method_names{m});

    if isequal(decoded_signal, xq_input)
        fprintf('Huffman decoding successful: perfect reconstruction.\n');
    else
        fprintf('Warning: Huffman decoding mismatch.\n');
    end

    fprintf('Average Huffman code length = %.4f bits/symbol\n', average_code_length);
    fprintf('Entropy = %.4f bits/symbol\n', entropy_results(m).entropy);

    % Store results
    huffman_results(m).method = method_names{m};
    huffman_results(m).dictionary = dictionary;
    huffman_results(m).encoded_stream = encoded_stream;
    huffman_results(m).total_bits = length(encoded_stream);
    huffman_results(m).average_code_length = average_code_length;
end

%% Part D: Block coding with block length k = 2

fprintf('\n========================================\n');
fprintf('PART D: Block Coding\n');
fprintf('========================================\n');

block_length = 2;
block_results = struct();

for m = 1:length(quantized_signals)

    xq_input = quantized_signals{m};

    % Form blocks of length k
    blocks = [];

    for i = 1:length(xq_input) - block_length + 1
        blocks = [blocks; xq_input(i:i + block_length - 1)];
    end

    % Find unique blocks and their probabilities
    [unique_blocks, ~, block_indices] = unique(blocks, 'rows');

    num_blocks = size(unique_blocks, 1);
    counts = histcounts(block_indices, 1:num_blocks + 1);
    probabilities = counts / sum(counts);

    % Block entropy
    block_entropy = -sum(probabilities .* log2(probabilities));

    % Fixed-length coding for blocks
    bits_per_block = ceil(log2(num_blocks));
    total_bits_fixed_block = bits_per_block * size(blocks, 1);
    bits_per_sample_fixed_block = total_bits_fixed_block / length(xq_input);

    fprintf('\nMethod: %s\n', method_names{m});
    fprintf('Block length k = %d\n', block_length);
    fprintf('Number of unique blocks = %d\n', num_blocks);
    fprintf('Block entropy H(A^k) = %.4f bits/block\n', block_entropy);
    fprintf('Entropy rate H(A^k)/k = %.4f bits/symbol\n', block_entropy / block_length);
    fprintf('Fixed-length block code = %d bits/block\n', bits_per_block);
    fprintf('Fixed-length block bitrate = %.4f bits/sample\n', bits_per_sample_fixed_block);

    fprintf('First 10 block probabilities:\n');

    for i = 1:min(10, num_blocks)
        fprintf('  [%s] : %.4f\n', num2str(unique_blocks(i, :)), probabilities(i));
    end

    % Store results
    block_results(m).method = method_names{m};
    block_results(m).block_length = block_length;
    block_results(m).unique_blocks = unique_blocks;
    block_results(m).probabilities = probabilities;
    block_results(m).block_entropy = block_entropy;
    block_results(m).entropy_rate = block_entropy / block_length;
    block_results(m).bits_per_block = bits_per_block;
    block_results(m).total_bits_fixed_block = total_bits_fixed_block;
    block_results(m).bits_per_sample_fixed_block = bits_per_sample_fixed_block;
end

%% Save source coding results for performance summary

save('source_coding_results.mat', ...
    'fixed_results', ...
    'entropy_results', ...
    'huffman_results', ...
    'block_results', ...
    'method_names');

fprintf('\nSource coding results saved to source_coding_results.mat\n');
fprintf('This file will be used by the performance summary script.\n');

%% Local helper function

function dictionary = assignHuffmanCodes(node, prefix)
    % Recursively assigns binary Huffman codes to symbols.

    if isempty(node.left) && isempty(node.right)

        % If there is only one symbol, assign code '0'
        if isempty(prefix)
            prefix = '0';
        end

        dictionary = {node.symbol, prefix};

    else
        left_dictionary = assignHuffmanCodes(node.left, [prefix '0']);
        right_dictionary = assignHuffmanCodes(node.right, [prefix '1']);
        dictionary = [left_dictionary; right_dictionary];
    end
end
