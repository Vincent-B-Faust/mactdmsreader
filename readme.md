# mactdmsreader

macOS-compatible TDMS reader for MATLAB

This MATLAB function was developed to solve the issue of using `mex TDMS` on Apple Silicon Macs, which prevents the standard `tdmsread` function from working properly. It provides a fully compatible way to read TDMS files on macOS.

## Features

- Works on macOS, including Apple Silicon (M1/M2) machines
- Reads TDMS files without relying on `mex TDMS`
- Compatible with MATLAB
- Lightweight and easy to integrate into existing workflows

## Dependencies

This project includes the TDMS Reader package by Jim Hokanson, licensed under BSD 3-Clause License.

The TDMS Reader code is included to simplify usage but remains under its original BSD 3-Clause License. You should not remove or modify the original copyright and license notices when redistributing the TDMS Reader code.

## Installation

1. Clone or download this repository.
2. Ensure the `tdmsreader` folder (original TDMS Reader) is present.
3. Add the repository folder to your MATLAB path.
4. Call the function:

```matlab
data = mactdmsreader('your_file.tdms');
```
## **License**

- **mactdmsreader**: GNU GPLv3 (Copyright 2025 LiuZY)
    
- **TDMS Reader dependency**: BSD 3-Clause License (Copyright 2020 Jim Hokanson)
    
Please see the LICENSE file for details.

## **Notes**

- Designed specifically for macOS environments where mex TDMS is not supported.
    
- Tested on Apple Silicon machines with MATLAB R2023a/b.
    
- You can freely modify or redistribute this function under the terms of the GPLv3, but TDMS Reader remains under its original BSD 3-Clause license.