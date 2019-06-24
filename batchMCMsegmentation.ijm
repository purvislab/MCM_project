// macro to automatically calculate presence of MCM signal in heterochromatin
//
//
// 06/23/2019 Chapel Hill, Kate Kedziora

// initial cleaning
run("Close All");

if (isOpen("ROI Manager")) {
	selectWindow("ROI Manager");
	run("Close");
}

setBatchMode(true);

// set parameters
channel_thr=1; // 1-indexed
channel_DAPI=3; 
channel_signal=2;

// initiate variables
var lower_thr=0;
var upper_thr=0;

// get directory
myDir=getDirectory("Choose directory to analyze");

// create subdirectories
if(!File.isDirectory(myDir+"results")){
	File.makeDirectory(myDir+"results");
}
if(!File.isDirectory(myDir+"segmentation")){
	File.makeDirectory(myDir+"segmentation");
}

////////////////////////////////////////////////

// ask for manual segmentation threshold
myThrFile=File.openDialog("Indicate the file with threshold values.");
readThresholdFile(myThrFile);

// list files
myList=getFileList(myDir+"data");

for(i=0;i<lengthOf(myList);i++){

	myFile=myList[i];
	run("Bio-Formats Importer", "open=["+myDir+"\\data\\"+myFile+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1");
	rename("full_stack");

	////////////////////////////////////////////////
	// segmentation of the DAPI signal
	run("Duplicate...", "duplicate channels="+d2s(channel_DAPI,0));
	
	run("Median...", "radius=4 stack");
	setAutoThreshold("Li dark no-reset stack");
	run("Convert to Mask", "method=Li background=Dark black");

	run("Options...", "iterations=10 count=4 black edm=8-bit do=Open stack");
	run("Analyze Particles...", "size=200-Infinity pixel show=Masks in_situ stack");
	run("Fill Holes", "stack");

	saveAs("Tiff", myDir+"//segmentation//"+replace(myFile,".ims","_nucleus.tif"));
	rename("nucleus");

	////////////////////////////////////////////////
	// segmentation of the heterochromatin channel

	selectWindow("full_stack");
	run("Duplicate...", "duplicate channels="+d2s(channel_thr,0));
	setThreshold(lower_thr, upper_thr);	
	
	run("Convert to Mask", "method=Default background=Dark black list");
	rename("hetChrom_temp");

	// remove structures outside of the nucleus
	imageCalculator("AND create stack", "nucleus","hetChrom_temp");
	
	saveAs("Tiff", myDir+"//segmentation//"+replace(myFile,".ims","_hetChrom.tif"));
	rename("hetChrom");

	selectWindow("hetChrom_temp");
	close();

	////////////////////////////////////////////////
	// find euchromatin
	selectWindow("full_stack");
	run("Duplicate...", "duplicate channels="+d2s(channel_signal,0));
	rename("signal");

	// create a mask of euchrom
	imageCalculator("XOR create stack", "nucleus","hetChrom");
	rename("euChrom");

	///////////////////////////////////////////////////
	// make calculations
	selectWindow("nucleus");
	setAutoThreshold("Li dark no-reset stack");

	run("Set Measurements...", "area mean standard modal stack redirect=None decimal=3");

	getDimensions(width, height, channels, slices, frames);


	/////////////////////////////////////////
	//set nucleus as selections in ROI
	for(mySlice=1;mySlice<=slices;mySlice++){

		setSlice(mySlice);
		run("Create Selection");
		if(is("area")){
			roiManager("Add");
		}
	}

	//measure full nucleus signal
	selectWindow("signal");

	roiManager("Associate", "true");
	run("Select All");
	roiManager("Measure");

	saveAs("Results", myDir+"results//"+replace(myFile,".ims","_nucleusSignal.csv"));
	run("Clear Results");

	roiManager("Deselect");
	roiManager("Delete");

	/////////////////////////////////////////
	//set hetChrom as selections in ROI
	selectWindow("hetChrom");
	setAutoThreshold("Li dark no-reset stack");
	for(mySlice=1;mySlice<=slices;mySlice++){

		setSlice(mySlice);
		run("Create Selection");
		if(is("area")){
			roiManager("Add");
		}
	}

	//measure hetChrom signal
	selectWindow("signal");

	roiManager("Associate", "true");
	run("Select All");
	roiManager("Measure");

	saveAs("Results", myDir+"results//"+replace(myFile,".ims","_hetChromSignal.csv"));
	run("Clear Results");

	roiManager("Deselect");
	roiManager("Delete");


	/////////////////////////////////////////
	//set euChrom as selections in ROI
	selectWindow("euChrom");
	setAutoThreshold("Li dark no-reset stack");
	for(mySlice=1;mySlice<=slices;mySlice++){

		setSlice(mySlice);
		run("Create Selection");
		if(is("area")){
			roiManager("Add");
		}
	}

	//measure hetChrom signal
	selectWindow("signal");

	roiManager("Associate", "true");
	run("Select All");
	roiManager("Measure");

	saveAs("Results", myDir+"results//"+replace(myFile,".ims","_euChromSignal.csv"));
	run("Clear Results");

	roiManager("Deselect");
	roiManager("Delete");
	

	// clean up for the next image
	run("Close All");
}


///////////////////////////////////////////////////////////////////////////////
// function

function readThresholdFile(myPath){ 

	// to read manualy chosen threshold value
 	//
	// input:
	// path to the txt file
	// modifies: 
	// lower_thr

	// read in info file
	fileString=File.openAsString(myPath); 
	fileLines=split(fileString,"\r\n");


	for(i=0;i<lengthOf(fileLines);i++){

		if(startsWith(fileLines[i],"Min") > 0){
			lower_thr = fileLines[i+1];
		}

		if(startsWith(fileLines[i],"Max") > 0){
			upper_thr = fileLines[i+1];
		}
	}
}
