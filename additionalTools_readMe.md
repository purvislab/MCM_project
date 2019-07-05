__DHB_full_image_check.ijm__

* it's a tool to help in selection of cells for confocal imaging
* works with movies exported to tif files (-> changes possible in the future to nd2 files)
* pipeline summary:
  * ask for the ring width and last frame number
  * ask for PCNA file (assumes PCNA to be 'c1' and DHB to be 'c2')
  * background correction for PCNA
  * thresholding of nuclei
  * morphological operation on nuclei regions
  * nuclei regions expanded to ring regions (bands)
  * DHB image opened
  * background correction for DHB
  * DHB signal is measured in nuclei and ring regions
  * results stored
  * annotated DHB image stored
