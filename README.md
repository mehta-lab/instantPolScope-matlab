# Instantaneous-PolScope
Imaging molecular order in live cells using fluorescence polarization.

Instantaneous PolScope is a microscope designed to image concentration, alignmnet, and orientation of molecules in a single snapshot. The method directly images molecular alignment and orientation, which remain challenging to measure in live cells with fluorescence super-resolution. 

The microscope, its calibration, and its use for imaging actin network and septin filaments are reported here: 

*Mehta, S.B., McQuilken, M., La Riviere, P., Occhipinti, P., Verma, A., Oldenbourg, R., Gladfelter, A.S., and Tani, T. (2016). Dissection of molecular assembly dynamics by tracking orientation and position of single molecules in live cells. Proceedings of the National Academy of Sciences 113, E6352–E6361.*

This repository contains the MATLAB code used for calibration and analysis of data produced by such a microscope.

It includes the following:
* MATLAB class (RTFluorPol) that represents the microscope
  * Hardware calibration is stored as properties of the class.
  * Calibration and pixel-level analysis procedures are written as methods of the class.
* MATLAB class (instantPolGUI) that provides a GUI to calibrate the microscope (i.e., an RTFluorPol object) and analyze movies.

Representative time-series data (alongwith relevant calibration) on retrograde flow of actin network at a leading edge of a migrating cell can be downloaded [here](https://drive.google.com/drive/folders/0BzvZDqEFdoWwaUtmZXp5bWtRZVU?usp=sharing).



  
