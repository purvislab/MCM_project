// macro to calculate threshold parameters for colocalization study
// of MCM chromatin loading
//
// requires ImageJ v1.52o
//
// 06/19/2019 Chapel Hill, Kate Kedziora


// initial cleaning
run("Close All");

// set default values
thr_min_default=800;
thr_max_default=5000;

thr_channel=1;

// choose a directory for analysis
myDir=getDirectory("Choose directory to analyze");

myList=getFileList(myDir);

//remember max of all images
myMax=0

// iterate through the files
for(i=0;i<lengthOf(myList);i++){

	myFile=myList[i];

	if(endsWith(myFile,"ims")){

		// print a name of the file
		print(myFile);

		run("Bio-Formats Importer", "open=["+myDir+"\\"+myFile+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1");

		// collect info about the stack
		Stack.getDimensions(width, height, channels, slices, frames);

		// set channel 
		Stack.setChannel(thr_channel);

		// find the brightest frame
		brightestMean = 0;
		brightestSlice = 1;
		
		for(j=1; j<slices; j++) {
			Stack.setSlice(j);
			getStatistics(area, mean,min,max);
			if(brightestMean<mean) {
				brightestMean = mean;
				brightestSlice = j;
			}

			if(myMax<max) {
				myMax = max;
			}
		}
		
		Stack.setSlice(brightestSlice);
		print(brightestSlice);
		
		setMinAndMax(0, 1000);
		
	}
}

// arrange the files

run("Tile");

// give a user a chance to change display settings
run("Brightness/Contrast...");
waitForUser("Adjust display.", "Use B&C Window if the display range is off. \n \nUse the Set Button to open the additional menu. \nSet min and max to visualize the contrast between euchromatin and heterochromatin. \nRemember to propagate the settings to all the stacks. \n \nClick OK when done.");
getMinAndMax(min, max);



for (i=1; i<=nImages(); i++) {
	
    selectImage(i);
	setThreshold(thr_min_default, thr_max_default);	     
} 

run("Threshold...");

// allow user to interact with thresholds

getThreshold(lower, upper);
getMinAndMax(min, max);

showAgain=true;
while(showAgain==true){

	Dialog.createNonBlocking("Adjust Threshold");
	Dialog.addSlider("Min Threshold", 0, myMax, lower);
	Dialog.addSlider("Max Threshold", 0, myMax, upper);
	Dialog.addCheckbox("Done", false);
	Dialog.show();
	
	lower = Dialog.getNumber();
	upper = Dialog.getNumber();
	showAgain=!Dialog.getCheckbox();
	
	
	for (i=1; i<=nImages(); i++) {
	
		selectImage(i);
		setThreshold(lower, upper);
	}
}

////////////////////////////////////////////////////////////////////////////////
// save results

// check date
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

// change date format to use in the file name
timeString = d2s(year,0);
if (month<9) {timeString = timeString+"0";}
timeString = timeString+d2s(month+1,0);
if (dayOfMonth<10) {timeString = timeString+"0";}
timeString = timeString+dayOfMonth;

infoFileHandle = File.open(myDir+timeString+"_manual_threshold.txt");

print(infoFileHandle, "Date: \r\n");
print(infoFileHandle, year+"/"+d2s(month+1,0)+"/"+dayOfMonth);

print(infoFileHandle, "\r\nMin threshold: \r\n");
print(infoFileHandle, d2s(lower,0));
print(infoFileHandle, "Max threshold: \r\n");
print(infoFileHandle, d2s(upper,0));

File.close(infoFileHandle);
