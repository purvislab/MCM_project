// macro to automatically calculate presence of MCM signal in heterochromatin
//
//
// 06/23/2019 Chapel Hill, Kate Kedziora

// initial cleaning
run("Close All");

// set parameters
channel_thr=1; // 1-indexed
channel_DAPI=3; 

// initiate variables
var lower_thr=0;
var upper_thr=0;

////////////////////////////////////////////////

// ask for manual segmentation threshold
myThrFile=File.openDialog("Indicate the file with threshold values.") 
readThresholdFile(myThrFile);
print(lower_thr);

// open image
myDir=getDirectory("Choose directory to analyze");
myList=getFileList(myDir);
myFile=myList[0];
run("Bio-Formats Importer", "open=["+myDir+"\\"+myFile+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1");

////////////////////////////////////////////////
// segmentation of the heterochromatin channel

run("Duplicate...", "duplicate channels="+d2s(channel_thr,0));
setThreshold(lower_thr, upper_thr);	

////////////////////////////////////////////////
// segmentation of the DAPI signal


////////////////////////////////////////////////
// calculate pixels


////////////////////////////////////////////////
// save segmentation masks


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
