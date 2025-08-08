# Leukocyte Data Directory

## Overview

The Leukocyte benchmark simulates leukocyte (white blood cell) detection and tracking in blood vessel microscopy videos. This workload requires video data files that are too large to store directly in the repository.

## Required Data Files

The leukocyte benchmark requires the following data files:

- **`testfile.avi`** - Test video file containing microscopy footage of blood vessels with leukocytes

## Data Availability

**The video data for this workload is available in the [GitHub release](https://github.com/huygnguyen04/gpu-rodinia-v4.0/releases/tag/leukocyte-sample-data).**

Due to the large size of the video files, they are not included in the main repository but can be downloaded from the project's GitHub releases page.

## Installation

Once you have downloaded the required data files from the GitHub release:

1. Place `testfile.avi` in this directory
2. Refer to the implementation-specific README files for build and run instructions

## Data Format

- **Video file**: AVI format containing microscopy footage of blood vessels with leukocytes
- **Content**: Each frame contains blood vessel imagery for cell detection and tracking analysis
- **Purpose**: Used for studying leukocyte behavior in blood flow for medical imaging applications
