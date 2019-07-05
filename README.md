# MCM_project


2019.06.24

This version of tools was developed after a conversation 06/13/2019.

Pipeline:

* create a directory for a set of imaging data that shared staining and should share thresholding 
* create subdirectory 'data' and put all the images inside
  * remember that each image should contain only a single cell
  * if it's not a case - the cells should be separated 
* create a csv file (Excel) with the information about cells for analysis (example columns: file_name, cell_age, cell_category, CDK2_activity)
* run __gestaltColocalizationThreshold.ijm__ to find a common threshold for heterochromatin 
  * I assumed that it is always channel 1 but please let me know if we need to change it.
  * The macro should guide the user to choose the right threshold - it's possible to change slices during the process and recalculate threshold for all the images unlimited number of times.
  * When the threshold is selected please mark 'Done' checkpoint.
* run __batchMCMsegmentation.ijm__ to segment nuclei and heterochromatin
  * this step requires threshold file generated by the previous macro
  * results are stored:
    * in 'results' directory
    * without calibration (pixel units)
    * separately for nucleus, heterochromatin and euchromatin
    * slice/line (good for internal quality control)
  * segmentation masks are stored separately ('segmentation' directory)
  * segmentation example 
![nucl_hetChrom](https://user-images.githubusercontent.com/7549583/60064340-17e7b000-96ce-11e9-8d8a-6badb8148da9.JPG)
* run __MCM_inHetChrom_plotter.ipynb__ to plot the data
  * it requires python (Anaconda)
