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

run("Input/Output...", "jpeg=85 gif=-1 file=.csv use_file save_column");

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
if(!File.isDirectory(myDir+"segmentation_nucleus_Otsu")){
	File.makeDirectory(myDir+"segmentation_nucleus_Otsu");
}
if(!File.isDirectory(myDir+"segmentation_gestalt")){
	File.makeDirectory(myDir+"segmentation_gestalt");
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

	myEnding=substring(myFile,lastIndexOf(myFile,"."));

	//remove scale
	run("Set Scale...", "distance=0 global");

	////////////////////////////////////////////////
	// segmentation of the DAPI signal
	run("Duplicate...", "duplicate channels="+d2s(channel_DAPI,0));
	
	run("Median...", "radius=4 stack");
	setAutoThreshold("Li dark no-reset stack");
	run("Convert to Mask", "method=Otsu background=Dark black");

	run("Options...", "iterations=10 count=4 black edm=8-bit do=Open stack");
	run("Analyze Particles...", "size=1000-Infinity pixel show=Masks in_situ stack");
	run("Fill Holes", "stack");

	saveAs("Tiff", myDir+"//segmentation_nucleus_Otsu//"+replace(myFile,myEnding,"_nucleus.tif"));
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
	
	saveAs("Tiff", myDir+"//segmentation_gestalt//"+replace(myFile,myEnding,"_hetChrom.tif"));
	rename("hetChrom");

	selectWindow("hetChrom_temp");
	close();

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
