// macro to automatically calculate presence of MCM signal in heterochromatin
//
//
// 06/23/2019 Chapel Hill, Kate Kedziora

// initial cleaning
run("Close All");

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
if(!File.isDirectory(myDir+"segmentation")){
	File.makeDirectory(myDir+"segmentation");
	File.makeDirectory(myDir+"results");
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
	// divide signal into eu and het chromatin
	selectWindow("full_stack");
	run("Duplicate...", "duplicate channels="+d2s(channel_signal,0));
	rename("signal");

	// create a mask of euchrom
	imageCalculator("XOR create stack", "nucleus","hetChrom");
	rename("euChrom");

	// find nuclear signal
	selectWindow("nucleus");
	run("Divide...", "value=255 stack");
	imageCalculator("Multiply create stack", "signal","nucleus");
	rename("signal_nucleus");

	// find hetChrom signal
	selectWindow("hetChrom");
	run("Divide...", "value=255 stack");
	imageCalculator("Multiply create stack", "signal","hetChrom");
	rename("signal_hetChrom");

	// find euChrom signal
	selectWindow("euChrom");
	run("Divide...", "value=255 stack");
	imageCalculator("Multiply create stack", "signal","euChrom");
	rename("signal_euChrom");

	///////////////////////////////////////////////////
	// make calculations

	// clean up for the next image
	k
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
