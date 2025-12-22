# Modernizing Rodinia Benchmark Suite v4.0 for Contemporary GPUs

## Documentation

### 📄 **[Rodinia BFS Report](https://drive.google.com/file/d/1i8x5kvpJm-GqTta-PAp6gsCNFZhNlsTO/view?usp=drivesdk)** – Full technical analysis of BFS modernization

### 🎞️ **[BFS Presentation Slides](https://docs.google.com/presentation/d/1xvqU5VuZZwTaW6En_GH2kvEB1uqpemKHGwTH0Ou_qU4/edit?usp=sharing)** – Slide deck summarizing key findings

### 📚 **[Original Rodinia Paper (IEEE)](https://ieeexplore.ieee.org/document/5306797)** – Che et al., IISWC 2009

## Overview
This repository contains an ongoing effort to **modernize the Rodinia benchmark suite** for **contemporary GPU architectures**. Rodinia has been widely used in architecture studies and GPU simulators since 2009, but its kernels and datasets were designed for early CUDA-era GPUs and increasingly fail to stress modern hardware capabilities.

Our goal is not simply to replace old algorithms with faster ones, but to **guide GPU architecture evaluation** by providing implementations that:
1. Scale to stress modern GPU resources (high SM counts, large caches, high memory bandwidth)
2. Exercise architectural features relevant to current and future designs
3. Enable meaningful comparisons across GPU generations

This project is part of my **Capstone Project and Graduation Thesis (CS 4980, Spring 2025)** at the University of Virginia, advised by Professor Kevin Skadron.

## Modernization Approach
For each benchmark, we follow a systematic pipeline:
- **Algorithm & CUDA Features Update:** Modernize kernels using current CUDA features while retaining legacy versions and algorithm variants for fair comparison.
- **Dataset Scaling:** Add synthetic and real-world inputs that scale to modern GPU memory and bandwidth, replacing outdated toy datasets.
- **Explicit Metric Definitions:** Standardize timing (kernel-only vs. end-to-end GPU time) using NVTX ranges for consistent measurement.
- **Profiling Pipeline:** Use Nsight Systems and Nsight Compute with automated scripts to enable reproducible end-to-end and kernel-level profiling.

## Tools & Environment
- **GPUs:** RTX 6000 (Turing), A100 (Ampere), H100 (Hopper).
- **Software:** GPGPU-Sim, CUDA 12.8, Nsight Systems 2024.4, Nsight Compute 2024.4
- **Infrastructure:** UVA Computer Science GPU Servers

## Future Work
- Extend modernization pipeline to additional Rodinia benchmarks (SRAD, Hotspot, LUD)
- Validate trends in GPU simulators (GPGPU-Sim)
- Explore multi-GPU configurations
- Add automated result aggregation and reproducibility checks
- Add microbenchmarks to isolate and study specific GPU architectural features

## Acknowledgments
- Professor Kevin Skadron and Farzana (LAVA Lab, UVA)
- Professor Xinyao Yi (NeoRodinia insights)
- UVA Computer Science Portal and GPU Servers
