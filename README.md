# Suite2P-master_online
 A version of the Suite2p toolbox for calcium imaging analysis modified for real-time analysis of all-optical experimental data

The vast majority of this is identical to the original MATLAB version of the Suite2p toolbox written by Marius Pachitariu and Carsen Stringer (https://github.com/cortex-lab/Suite2P). This version is designed to work with imaging data that has been real-time motion-corrected via our Bruker/PrairieView motion correction functionality (https://github.com/llerussell/Bruker_PrairieLink), however it will work with any imaging data that is motion corrected and saved in the same binary file format.

Specifically, we have added 4 main optimisations for real-time analysis of all-optical experimental data:
(1) it imports raw real-time motion-corrected time-series binary files (instead of un-motion-corrected tifs; see above).
(2) it optionally imports a file recording the correlation of each acquired frame with the reference image used for real-time motion-correction (simultaneously recorded during real-time motion-correction; see above) which can be used to identify and exclude imaging frames corrupted by photostimulation artefacts (which typically have low correlation with the reference image)
(3) if multiple planes are imaged then analysis is parallelised on the CPU to process as many planes simultaneously as possible
(4) data is imported as memory mapped files to speed up data manipulation during ROI segmentation and trace extraction phases
(5) the ROI segmentation procedure is terminated after a fixed number of iterations that is manually selected to yield an optimal balance between speed and accuracy with the data acquired on our system