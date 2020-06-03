// macro to automatically calculate presence of MCM signal in heterochromatin
//
//
// 06/23/2019 Chapel Hill, Kate Kedziora
// 1/29/2019 Chapel Hill, Amy Song - code modifed for new set of data

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
	
	
	run("Close All");

 

}

