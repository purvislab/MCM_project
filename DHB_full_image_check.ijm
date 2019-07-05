// macro to check DHB status to guide selection of cells for confocal
//
//
// 07/05/2019 Chapel Hill, Kate Kedziora

// initial cleaning
run("Close All");
run("Clear Results");

if (isOpen("ROI Manager")) {
	selectWindow("ROI Manager");
	run("Close");
}

// analysis settings
Dialog.create("Analysis details");
Dialog.addNumber("Frame to analyze:", 1);
Dialog.addNumber("Ring width:", 10);
Dialog.show();

myFrame = Dialog.getNumber();
myRing = Dialog.getNumber();;


// get pcna file to analyze
pcnaFile=File.openDialog("Choose PCNA tif file to analyze.");

run("Bio-Formats Importer", "open=["+pcnaFile+"] color_mode=Default rois_import=[ROI manager] specify_range view=Hyperstack stack_order=XYCZT t_begin="+myFrame+" t_end="+myFrame+" t_step=1");
rename("pcnaImage");
run("Enhance Contrast", "saturated=0.35");
run("Fire");


// subtract background
run("Duplicate...", "title=bck");
run("Median...", "radius=20");
run("Subtract Background...", "rolling=300 create");
imageCalculator("Subtract", "pcnaImage","bck");
selectWindow("bck");
close();

// threshold 
selectWindow("pcnaImage");
run("Median...", "radius=5");
setAutoThreshold("Li dark no-reset");
setOption("BlackBackground", true);
run("Convert to Mask");

// cleaning of regions
run("Fill Holes");
run("Options...", "iterations=3 count=4 black edm=8-bit do=Open");
run("Watershed");

// get rid of small particles
run("Analyze Particles...", "size=500-Infinity show=Masks add in_situ");

// create ring rois
roiNum=roiManager("count");
myRing="10";	//toDel
for (j=0; j<roiNum; j++) {

	roiManager("Select", j);
	run("Make Band...", "band=10");
	roiManager("Add");
}

// open dhb image
dhbFile=replace(pcnaFile,"c1.","c2.");
run("Bio-Formats Importer", "open=["+dhbFile+"] color_mode=Default rois_import=[ROI manager] specify_range view=Hyperstack stack_order=XYCZT t_begin="+myFrame+" t_end="+myFrame+" t_step=1");
rename("dhbImage");
run("Enhance Contrast", "saturated=0.35");
run("Fire");

// subtract background
setForegroundColor(0, 0, 0);

makeRectangle(0, 0, 2048, 1);
run("Fill", "slice");
makeRectangle(0, 0, 1, 2048);
run("Fill", "slice");
makeRectangle(2047, 0, 1, 2048);
run("Fill", "slice");
makeRectangle(0, 2047, 2048, 1);
run("Fill", "slice");

selectWindow("dhbImage");
run("Select None");
run("Duplicate...", "title=bck");
run("Median...", "radius=10");
run("Subtract Background...", "rolling=500 create");
imageCalculator("Subtract", "dhbImage","bck");
selectWindow("bck");
close();

run("Set Measurements...", "area mean standard modal centroid redirect=None decimal=3");
// calculate signal
selectWindow("dhbImage");
roiNum=roiManager("count")/2;
for (j=0; j<roiNum; j++) {

	roiManager("Select", j);
	roiManager("Measure");
	meanNucleus = getResult("Mean", j);

	roiManager("Select", j+roiNum);
	roiManager("Measure");

	meanRing = getResult("Mean", j+1);
	setResult("MeanRing", j, meanRing);

	setResult("MeanRatio", j, meanRing/meanNucleus);

	// clean ring measurements line
	selectWindow("Results");
	Table.deleteRows(j+1, j+1);
}

// clean roi manager
roiNum=roiManager("count")/2;
for (j=0; j<roiNum; j++) {
	roiManager("Select", roiNum);
	roiManager("Delete");
}

selectWindow("dhbImage");
roiManager("Show All");

//save results
saveAs("Results", replace(pcnaFile,"c1.tif",".csv"));

//save image
selectWindow("dhbImage");
run("From ROI Manager");
run("Flatten");
saveAs("Tiff",replace(pcnaFile,"c1.tif","_regions.tif"));

run("Tile");
selectWindow("Results");