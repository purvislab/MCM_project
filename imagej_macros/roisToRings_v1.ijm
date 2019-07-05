// script to change regions into rings - for DHB measurement
//
// 07/16/2018 Chapel Hill, Kasia Kedziora

// cleaning
run("Close All");
run("Clear Results");

if (isOpen("ROI Manager")) {
	selectWindow("ROI Manager");
	run("Close");
}

roiManager("Associate", "true");

setBatchMode(true);

myDir = getDirectory("z:\\CookLab\\Liu\181102-cdc6\\18110216015/");
//myDir="z:\\CookLab\\Liu\181102-cdc6\\18110216015/";
myChannel="PCNA"; 	//example channel, doesn't matter which
myRing="5"; // dilation of 5 pixels for 20X objective and 7 pixels for 40x objective
roiSet="roi.zip";
roiSetSave="ring_roi.zip";

dataPath=myDir+"\\smallStacks\\";


myList = getFileList(dataPath);


for (i=0;i<lengthOf(myList);i++){

	showProgress(i/lengthOf(myList));
	
	myFile = myList[i];

	if (indexOf(myFile,myChannel)>0){

		open(dataPath+myFile);

		rename("nucleiStackCentered");

		cellID = substring(myFile,indexOf(myFile,"_")-4,indexOf(myFile,"_"));

		// open selected regions
		temp=myChannel+"_cut.tif";
		myFile=replace(myFile,temp,roiSet);

		roiManager("Open", dataPath+myFile);

		oldRoisNum=roiManager("count");
		print(oldRoisNum);
		for (j=0; j<oldRoisNum; j++) {
	
			roiManager("Select", j);
			Stack.getPosition(channel, objSlice, objFrame);
			run("Create Mask");
			run("Duplicate...", "title=big");
			run("Options...", "iterations="+myRing+" count=1 black edm=8-bit do=Dilate");		
			imageCalculator("Subtract create", "big","Mask");
			setAutoThreshold("Default dark");
			run("Create Selection");
			roiManager("Add");
			
			selectWindow("nucleiStackCentered");
			roiManager("Select", oldRoisNum+j);
			roiManager("Update");
			
			selectWindow("Result of big");
			close();
			selectWindow("Mask");
			close();
			selectWindow("big");
			close();
			
		}
		
		// remove old rois
		for (j=0; j<oldRoisNum; j++) {

			roiManager("Select", 0);
			roiManager("Delete");
		}

		
		selectWindow("nucleiStackCentered");
		close();
		
		roiManager("Save", dataPath+replace(myFile,roiSet,roiSetSave));

		// cleaning
		roiManager("Deselect");
		roiManager("Delete");
		
	}
}