# Heartwall Data Directory

## Overview

The Heartwall benchmark simulates cardiac motion tracking using ultrasound video data. This workload requires video data files that are too large to store directly in the repository.

## Required Data Files

The heartwall benchmark requires the following data files:

- **`test.avi`** - Test video file containing ultrasound cardiac imaging data
- **`input.txt`** - Configuration file with tracking parameters

## Data Availability

**The video data for this workload is available in the [GitHub release](https://github.com/huygnguyen04/gpu-rodinia-v4.0/releases/tag/heartwall-sample-data).**

Due to the large size of the video files, they are not included in the main repository but can be downloaded from the project's GitHub releases page.

## Installation

Once you have downloaded the required data files from the GitHub release:

1. Place `test.avi` and `input.txt` in this directory
2. Refer to the implementation-specific README files for build and run instructions

## Data Format

- **Video file**: AVI format containing ultrasound cardiac imaging sequences
- **Input file**: Text file with endocardium and epicardium tracking points

The video data is processed frame by frame to track cardiac wall motion for medical imaging applications.