# impeller\_test

A minimal Flutter project demonstrating the performance impact of Impeller rendering compared to the default Skia backend.

## Overview

This project highlights how enabling Impeller can affect animation smoothness:

* **Impeller enabled**: May exhibit reduced frame rates and stuttering animations on some devices, including high-end hardware (e.g., ASUS Zenfone 10).
* **Impeller disabled (Skia default)**: Provides smooth animations across both low-end and high-end devices.

## Usage

1. **Run with Impeller enabled**

   ```bash
   flutter run --release
   ```

2. **Run with Impeller disabled**

   ```bash
   flutter run --release --no-enable-impeller
   ```

## Requirements

* Flutter 3.32 or newer
* A connected device or emulator
