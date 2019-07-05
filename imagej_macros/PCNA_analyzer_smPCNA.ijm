/*
 * script to analyze the behavior of PCNA protein
 * 
 * looks for S phase based on variance of PCNA
 * 
 * v3
 * -> calculates var params for all the extracted tracks
 * -> saves them in separate files
 * -> requires sorted ROIs
 * 
 * v4
 * -> stores data in a single file
 * -> doesn't extract position value (as intensity script is doing it)
 * 
 * v5
 * -> works with cut out stacks
 * 
 * 10/19/2016 Chapel Hill, Kasia Kedziora
 */

 // pathways
//myDir="S:\\CookLab\\Liu\\180921_cdc6\\18092116000\\";
myDir = getDirectory("z:\\CookLab\\Liu\181102-cdc6\\18110216015/");

dataPath=myDir+"\\data";
trackPath=myDir+"\\tracking";

// saving
dirSave = myDir+"\\analysis";


//parameters
myScaleSmall1 = 0.5; // how much of the original regions take for the analysis of variance
myScaleSmall2 = 0.5; // how much of the original regions take for the analysis of variance

resc8bit = 2.0; // scaling to convert to 8 bit for variance analysis

lineNum=0; // initiating counting of the regions

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
setBatchMode(true);

// cleaning
run("Clear Results");

if (isOpen("ROI Manager")) {
	selectWindow("ROI Manager");
	run("Close");
}

roiManager("Associate", "true");

myList = getFileList(myDir+"\\smallStacks");

lineNum=0;

for (i=0;i<lengthOf(myList);i++){

	showProgress(i/lengthOf(myList));

	myFile = myList[i];

	if (indexOf(myFile,"PCNA_cut")>0){

		open(myDir+"//smallStacks//"+myFile);

		rename("nucleiStackCentered");

		cellID=substring(myFile,indexOf(myFile,"_")-4,indexOf(myFile,"_"));

		// open small regions
		myFile=replace(myFile,"PCNA_cut.tif","roi.zip");

		roiManager("Open", myDir+"//smallStacks//"+myFile);

		// find beginning of a track
		myFile=replace(myFile,"roi.zip","metaData.txt");
		metaFile= myDir+"//tracking//"+myFile;
		sliceStart = findSliceStart(metaFile);
		
		// calculate region based params
		run("Set Measurements...", "area mean standard modal stack redirect=None decimal=3");

		emptyFrames = 0; // for each cell separately
		emptyFramesArray=newArray(roiManager("count"));
		
		for (j=0; j<roiManager("count"); j++) {

			makeMeasurement=true;
		
			roiManager("Select", j);
			Stack.getPosition(channel, objSlice, objFrame);

			// empty frame correction
			if(j>0){

				myPositionNew = objSlice*objFrame;

				k=1;
				while ((myPosition+k) < myPositionNew){ //counting off-set loop

					roiManager("Measure");

					setResult("Cell ID #",lineNum,cellID);
					setResult("Slice", lineNum, myPosition+k);
					setResult("Movie Slice", lineNum, myPosition+k+sliceStart-1);
					setResult("Mean", lineNum, NaN);
					setResult("Area", lineNum, NaN);
					setResult("StdDev", lineNum, NaN);
					setResult("Mode", lineNum, NaN);
					setResult("Mean var", lineNum, NaN);
					setResult("Median var", lineNum, NaN);
					setResult("Std var", lineNum, NaN);
					
					lineNum++;
					emptyFrames++;
					k++;
				}
				if ((myPosition+1) > myPositionNew){ // measure only for a new slice	
					makeMeasurement=false;
				}
			}

			if (makeMeasurement==true){
				// measure
			    roiManager("Select", j);
				roiManager("Measure");
	
				emptyFramesArray[j]=emptyFrames;
			
				// add cell ID
				setResult("Cell ID #", lineNum, cellID);
				//add region slice
				myPosition=objSlice*objFrame;
				setResult("Slice", lineNum, myPosition);
				setResult("Movie Slice", lineNum, myPosition+sliceStart-1);
			
				lineNum++;
			} else {
			    roiManager("Select", j);
				roiManager("Delete");
			}
		}	
		
		selectWindow("nucleiStackCentered");
		run("Select All");
		run("Duplicate...", "title=myVar duplicate");

		// variance
		selectWindow("myVar");
		run("Median...", "radius=1");

		run("Z Project...", "projection=[Max Intensity]");
		rename("zProj");
		getStatistics(area, mean, min, max);
		close();
		
		selectWindow("myVar");
		//resc8bit=1.5;
		setMinAndMax(0, max*resc8bit);
		
		run("8-bit");
		run("Remove Outliers...", "radius=10 threshold=3 which=Dark stack");

		// solving edge problem
		for (j=0; j<roiManager("count"); j++) {

			roiManager("Select", j);
			run("Scale... ", "x="+d2s(0.8,2)+" y="+d2s(0.8,2)+" centered");

			getStatistics(area, mean, min, max);
			setForegroundColor(mean, mean, mean);
			run("Make Inverse");
			run("Fill", "slice");
			
			
		}
		roiManager("Deselect");
		run("Select All");
		run("Variance...", "radius=2 stack");

		// get regions for eroded regions
		myRois=roiManager("count");
		firstPartRois=floor(roiManager("count")/2);
		for (j=0; j<firstPartRois; j++) {

		    roiManager("Select", j);
		 	run("Scale... ", "x="+d2s(myScaleSmall1,2)+" y="+d2s(myScaleSmall1,2)+" centered");
		    roiManager("update");
		}

		selectWindow("myVar");
		// calculate mean signal of variance
		for (j=0; j<firstPartRois; j++) {

		    roiManager("Select", j);

		 	roiManager("Measure");

			myMeanVar = getResult("Mean", lineNum);
			setResult("Mean var", lineNum - (myRois+emptyFrames-emptyFramesArray[j]), myMeanVar);

			myModeVar = getResult("Mode", lineNum);
			setResult("Median var", lineNum - (myRois+emptyFrames-emptyFramesArray[j]), myModeVar);

			myStdVar = getResult("StdDev", lineNum);
			setResult("Std var", lineNum - (myRois+emptyFrames-emptyFramesArray[j]), myStdVar); 

			lineNum++;
		}

		//step 2 of collecting variance data
				
		for (j=firstPartRois; j<roiManager("count"); j++) {

		    roiManager("Select", j);
		 	run("Scale... ", "x="+d2s(myScaleSmall2,2)+" y="+d2s(myScaleSmall2,2)+" centered");
		    roiManager("update");
		}

		selectWindow("myVar");

		// calculate mean signal of variance
		for (j=firstPartRois; j<roiManager("count"); j++) {

		    roiManager("Select", j);

		 	roiManager("Measure");

			myMeanVar = getResult("Mean", lineNum);
			setResult("Mean var", lineNum - (myRois+emptyFrames-emptyFramesArray[j]), myMeanVar);

			myModeVar = getResult("Mode", lineNum);
			setResult("Median var", lineNum - (myRois+emptyFrames-emptyFramesArray[j]), myModeVar);

			myStdVar = getResult("StdDev", lineNum);
			setResult("Std var", lineNum - (myRois+emptyFrames-emptyFramesArray[j]), myStdVar);

			lineNum++;
		}

		// because lines where counted double
		lineNum=lineNum-roiManager("count");


		// clear unneeded lines from results
		IJ.deleteRows(lineNum,myRois+lineNum);

		roiManager("Deselect");
		roiManager("Delete");

		selectWindow("nucleiStackCentered");
		close();

		selectWindow("myVar");
		close();

	}
}
saveAs("Results", dirSave+"\\"+substring(myDir,lengthOf(myDir)-12,lengthOf(myDir)-1)+"_pcnaVar_v60_resc20.csv");


run("Clear Results");

/////////////////////////////////////////////////////////////////////////////////////////////////////////
function findSliceStart(metaFile){ // takes pathway to metafile of this particular cell

	fileString=File.openAsString(metaFile); 
	fileLines=split(fileString,"\r\n");

	sliceStart = 0;

	for(i=0;i<lengthOf(fileLines);i++){

		if(startsWith(fileLines[i],"Slice start") > 0){

			sliceStart = fileLines[i+1];;
		}
	} 
	
	return sliceStart;
}
