# Cobiveco - LDRB_Fibers | CDT Personalization Pipeline

This repository is a component of the **Cardiac Digital Twin Personalization Pipeline** implemented for the Master Thesis: _"Implementation of a pipeline to generate a patient-specific Digital Twin of Cardiac Electrophysiology"_

For more details on the complete Pipeline refer to the main repository 

## Overview
This repository is a fork of the **Cobiveco** and **LDRB_Fibers** tools originally developed by **KIT-IBT** (https://github.com/KIT-IBT/Cobiveco - https://github.com/KIT-IBT/LDRB_Fibers)

Given a biventricular cardiac mesh, it performs the following steps to prepare the mesh for the **Functional Twinning** Phase of the CDT Pipeline:
- computation of ventricular coordinates according to the Cobiveco system (Consistent Biventricular Coordinates);
- computation of additional projective coordinates (continuous transventricular and posterior-to-anterior coordinates);
- generation of cardiac fiber orientations using LDRB algorithm (Laplace-Dirichlet Rule-Based).

## Main modifications
To integrate the tools in the CDT Personalization Pipeline the original code was modified and adapted as follows:

- **Full Containerization**: creation of a custom MATLAB Docker Container based on the r2023a  MATLAB Docker Image from Mathworks that includes all the required dependencies
- **Automated Workflow**: a Matlab script was developed to automate the coordinate-generation workflow for the meshes following a configuration file

## Workflow details

### Inputs
- **Volumetric biventricular meshes** recontrusted in the previous Anatomical Twinning phases from CMR (Cardiac Magnetic Resonance) using biv-me and meshtool
   - Format: the meshes are in `.vtk` thetraedral format at coarse resolution of 1.5 mm

- **Configuration File**: pipeline_config.json

   - specify the list of cases to process, the output path of previous phase were to retrieve the input meshes files, the folder were to store the cobiveco files, the coarse and fine resolution
   
### Operation performed
1. Input mesh preparation
   - truncates the mesh at the base excluding the valves;
   - labels and extracts the four cardiac surfaces: LV Endocardium, RV Endocardium, Epicardium and flat Base
2. Computation of Cobiveco and projective coordinates
3. Computation of Myocardial Fibers orientation using the LDRB_Fibers tool
4. Resamples the mesh at fine resolution of 0.5 mm and repeats athe step 2 and 3 on this mesh as well

### Outputs
Processed Mesh files as reqired by the next Functional Twinning phase of the CDT Pipeline
- Coarse Mesh at 1.5 mm resolution
- Fine mesh at 0.5 resolution
All mesh nodes have associates fields:
- Nodal coordinates: tv, tm, rt, ab, lvrv, pa
- Fibers vector fileds: longitudinal, sheet and sheet-normal fiber vectors

## Standalone Usage

1. Clone the repository

2. Build the Docker Image

   The matlab-docker folder contains the Dockerfile to build the image

3. Start the Docker container with the following additional parameters
   - mount the repository folder and the input files folder as volumes
   - forward the port 8888

4. open the browser to localhost:8888 to access MATLAB web interface and login with a mathworks account

5. Run the script /main-pipeline-script/computeAllSB_coarse_fine.m to perform all the workflow operations described above 


## Acknowledgments and License

This repository incorporates and integrates the code from the following open-source projects.

* **Cobiveco**: [KIT-IBT/Cobiveco](https://github.com/KIT-IBT/Cobiveco)

   Copyright 2021 Steffen Schuler, Karlsruhe Institute of Technology.

   Reseased under the Apache License 2.0

   References:

   - [Schuler, S., Pilia, N., Potyagaylo, D., Loewe, A., 2021. Cobiveco: Consistent biventricular coordinates for precise and intuitive description of position in the heart – with MATLAB implementation. Medical Image Analysis.](https://doi.org/10.1016/j.media.2021.102247)

   - [Pankewitz, L. et al., 2024. A universal biventricular coordinate system incorporating valve annuli: Validation in congenital heart disease. Medical Image Analysis.](https://doi.org/10.1016/j.media.2024.103091)

* **LDRB\_Fibers**: [KIT-IBT/LDRB\_Fibers](https://github.com/KIT-IBT/LDRB_Fibers)

   Copyright 2021 Steffen Schuler, Karlsruhe Institute of Technology.

   Released under the GPL-3.0 License

   Reference: [Bayer, J. et al., 2012. A novel rule-based algorithm for assigning myocardial fiber orientation to computational heart models. Ann Biomed Eng.](https://doi.org/10.1007/s10439-012-0593-5)
