# Signal Quantization and Source Coding

A MATLAB project that implements signal quantization, source coding, entropy analysis, Huffman coding, block coding, and performance comparison for a sampled signal.

## Project Overview

This project studies how a sampled signal can be quantized, encoded, decoded, and evaluated using different signal processing and source coding techniques.

The project is divided into three main parts:

- Signal quantization
- Source coding and entropy analysis
- End-to-end performance comparison

## Technologies Used

- MATLAB
- Signal Processing
- Quantization
- Lloyd-Max Algorithm
- Source Coding
- Entropy Analysis
- Huffman Coding
- Block Coding

## Features

- Generates a sampled cosine signal
- Applies 2-level quantization
- Applies uniform quantization with different numbers of levels
- Implements Lloyd-Max quantization
- Calculates mean squared error for quantized signals
- Performs fixed-length source coding and decoding
- Computes symbol probabilities and entropy
- Implements manual Huffman coding
- Applies block coding with block length 2
- Compares total bits, bits per symbol, entropy, and distortion
- Generates performance plots and summary tables

## Repository Structure

```text
signal-quantization-source-coding/
│
├── README.md
├── 01_quantization.m
├── 02_source_coding.m
└── 03_performance_summary.m
