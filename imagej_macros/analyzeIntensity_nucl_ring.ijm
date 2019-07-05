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
myDir="H:\\LIVE CELL IMAGING\\190201_JM_asynchronous\\19020171700/";
//myDir = getDirectory("Choose a Directory to Process");

dataPath=myDir+"\\data";
trackPath=myDir+"\\tracking";

myChannelList=newArray("dhb","Cdc6");
roiList=newArray("roi.zip","ring_roi.zip");

myChannelNum=lengthOf(myChannelList);
myRoisNum=lengthOf(roiList);

// saving
dirSave = myDir+"\\analysis";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
setBatchMode(true);

for(myIter=0;myIter<myChannelNum;myIter++){

	//channel line num
	lineNumChannel=0;

	myChannel=myChannelList[myIter];

	// cleaning
	run("Clear Results");
	
	if (isOpen("ROI Manager")) {
		selectWindow("ROI Manager");
		run("Close");
	}
	
	roiManager("Associate", "true");

	myList = getFileList(myDir+"\\smallStacks");
	
	lineNum=0;

	// calculate region based params
	run("Set Measurements...", "area mean standard modal stack redirect=None decimal=3");

	for (i=0;i<lengthOf(myList);i++){
	
		showProgress(i/lengthOf(myList));
	
		myFile = myList[i];

		if (indexOf(myFile,myChannel)>0){
	
			open(myDir+"//smallStacks//"+myFile);
	
			rename("nucleiStackCentered");

			cellID=substring(myFile,indexOf(myFile,"_")-4,indexOf(myFile,"_"));

			roiSet=roiList[0];

			// open selected regions
			temp=myChannel+"_cut.tif";
			myFile=replace(myFile,temp,roiSet);
	
			roiManager("Open", myDir+"//smallStacks//"+myFile);
			myRois=roiManager("count");

			// find beginning of a track
			myFile=replace(myFile,roiSet,"metaData.txt");
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
						setResult("Mean ring", lineNum, NaN);
						setResult("Median ring", lineNum, NaN);
						setResult("Std ring", lineNum, NaN);
						
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

			//clean roi manager	
			roiManager("Deselect");
			roiManager("Delete");
		
			//open second set or rois
			roiSet=roiList[1];
			myFile=replace(myFile,"metaData.txt",roiSet);

			roiManager("Open", myDir+"//smallStacks//"+myFile);

			// calculate mean signal of variance
			for (j=0; j<roiManager("count"); j++) {
	
			    roiManager("Select", j);
	
			 	roiManager("Measure");
	
				myMeanVar = getResult("Mean", lineNum);
				setResult("Mean ring", lineNum - (myRois+emptyFrames-emptyFramesArray[j]), myMeanVar);
	
				myModeVar = getResult("Mode", lineNum);
				setResult("Median ring", lineNum - (myRois+emptyFrames-emptyFramesArray[j]), myModeVar);
	
				myStdVar = getResult("StdDev", lineNum);
				setResult("Std ring", lineNum - (myRois+emptyFrames-emptyFramesArray[j]), myStdVar); 
	
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
		}
	}
	
	saveAs("Results", dirSave+"\\"+substring(myDir,lengthOf(myDir)-12,lengthOf(myDir)-1)+"_"+myChannel+"_.csv");
	run("Clear Results");
}

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
