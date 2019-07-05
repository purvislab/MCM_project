// macro to extract small stacks from the series
//
// 04/12/2017 Kasia Kedziora, Chapel Hill

// containers
var myMarkers = newArray(6); // we are so optimistic about the future
var myChannels = newArray(6); // we are so optimistic about the future
var channelDecision = newArray(6); // we are so optimistic about the future

// track params to extract from a meta file
var sqSize = 250;
var trackImageSize = 0;
var smallFramesNum = 0;
var myBit = "16 bit";
var sliceStart = 0;
var cellID = "";

//init cleaning
run("Close All");
run("Clear Results");

roiManager("Associate", "true"); // it open ROImanager if not open
roiManager("UseNames", "true");
if (isOpen("ROI Manager")) {
	selectWindow("ROI Manager");
	run("Close");
}


if (isOpen("Log")) {
	selectWindow("Log");
	run("Close");
}

// ask for the directory
//myDir = getDirectory("Choose a Directory to Process");
myDir = getDirectory("Choose a Directory to Process");

// read in the info
myList = getFileList(myDir+"\\tracking");
objectNumber = lengthOf(myList)/3;

readInfoFile(myDir);

// display the dialog
Dialog.create("Small stack extractor");

Dialog.addMessage("There are "+d2s(objectNumber,0)+" extracted objects.");

Dialog.addMessage("Choose channels to cut stacks from:");

for(i=0;i<lengthOf(myChannels);i++){

	Dialog.addCheckbox(myMarkers[i], false);	
}

Dialog.addString("Small stack size:", sqSize);

Dialog.show;

// read the dialog
for(i=0;i<lengthOf(myChannels);i++){
	
	channelDecision[i] = Dialog.getCheckbox();
}
channelDecision = Array.trim(channelDecision,i);

sqSize = parseInt(Dialog.getString());

// for every selected channel cut small stacks
setBatchMode(true);

chTotal=0;
for (i=0;i<lengthOf(channelDecision);i++){

	if (channelDecision[i]==true){
		chTotal++;
	}
}

for (i=0;i<lengthOf(channelDecision);i++){

	if (channelDecision[i]==true){

		open(myChannels[i]);
		rename("channelImage");

		getDimensions(myWidth, myHeight, myChannelsNum, mySlices, myFrames);

		for (myInd=0;myInd<lengthOf(myList);myInd++){
			
			if (indexOf(myList[myInd],"metaData")>0) {

				showProgress(myInd/(lengthOf(myList)*chTotal));

				readMetaInfo(myDir+"//tracking//"+myList[myInd]);

				// calculate scale of images
				myScale = myWidth/trackImageSize;

				newImage("objectStack", myBit+" grayscale-mode", sqSize, sqSize, 1, 1, smallFramesNum);
				
				fileName=replace(myList[myInd],"metaData.txt","roi.zip");		
				roiManager("Open", myDir+"//tracking//"+fileName);

				objectsTotal=roiManager("count");

				for(myObject=0;myObject<objectsTotal;myObject++){

					selectWindow("channelImage");
					roiManager("select",myObject);
					run("Scale... ", "x="+d2s(myScale,2)+" y="+d2s(myScale,2));
					roiManager("Update");
					roiManager("select",myObject);
					getSelectionBounds(x, y, w, h);	
					//print(x);

					//solving 1 pix issue
					x=x+w/2;
					y=y+h/2;
					if (round(w/2)>floor(w/2)) x=x-0.5;
					if (round(h/2)>floor(h/2)) y=y-0.5;
					
					mySlice = getSliceNumber(); 

					// copy from the original image
				 	x0 = maxOf(0,x-sqSize/2);
					y0 = maxOf(0,y-sqSize/2);
					myW = sqSize - maxOf(0,x+sqSize/2-myWidth) + minOf(0,x-sqSize/2);
					myH = sqSize - maxOf(0,y+sqSize/2-myHeight) + minOf(0,y-sqSize/2);

					selectWindow("channelImage");
					makeRectangle(x0, y0, myW, myH);
					run("Copy"); 
		
					// calculate where to put
					x0 = maxOf(0,-(x-sqSize/2));
					y0 = maxOf(0,-(y-sqSize/2));
		
					selectWindow("objectStack");
					setSlice(mySlice-sliceStart+1);
					makeRectangle(x0, y0, myW, myH);
					run("Paste");

					// move the ROIs accordingly
					roiManager("select",myObject);
					roiManager("Remove Slice Info");
					roiManager("Remove Frame Info");

					selectWindow("objectStack");
					setSlice(mySlice-sliceStart+1);

					roiManager("select",myObject);
					Roi.move(sqSize/2-w/2, sqSize/2-h/2);
					oldName=Roi.getName;
					roiManager("Rename",oldName+"_c");
					roiManager("Update");

				}

				roiManager("Save", myDir+"//smallStacks//"+cellID+"_roi.zip");
				// cleaning
				roiManager("Deselect");
				roiManager("Delete");

				selectWindow("objectStack");
				run("Select None");

				saveAs("Tiff", myDir+"//smallStacks//"+cellID+"_"+myMarkers[i]+"_cut.tif");
				close();
			}
		}
		run("Close All");
	}
}


///////////////////////////////////////////////////////////////////////////////////////////
function readInfoFile(myDir){ 
	
	// modifies: 
	// expDate
	// expID
	// expName

	//myPath=myDir+"//info//rawDataInfo.txt";
	myPath=myDir+ "/info/"+substring(myDir,lengthOf(myDir)-12,lengthOf(myDir)-1)+"_rawDataInfo.txt";

	// read in info file
	fileString=File.openAsString(myPath); 
	fileLines=split(fileString,"\r\n");

	j = 0; // counter for channels with names

	for(i=0;i<lengthOf(fileLines);i++){

		if(startsWith(fileLines[i],"Experimenter") > 0){
			expName = fileLines[i+1];
		}

		if(startsWith(fileLines[i],"Acquisition") > 0){
			expDate = fileLines[i+1];
			expDate = replace(expDate,'/','');
			expDate=substring(expDate,2);
		}

		if(startsWith(fileLines[i],"ID") > 0){
			expID = fileLines[i+1];
		}

		if(startsWith(fileLines[i],"Number of channels") > 0){
			chNum = parseInt(fileLines[i+1]);
		}

		if(startsWith(fileLines[i],"File") > 0){
			myChannels[j] = myDir+"/data/"+fileLines[i+1];
		}
		
		if(startsWith(fileLines[i],"Protein") > 0){
			myMarkers[j] = fileLines[i+1];
			j++;
		}
		
	}

	myMarkers = Array.trim(myMarkers,j);
	myChannels = Array.trim(myChannels,j);

}
///////////////////////////////////////////////////////////////////////////////////////////
function readMetaInfo(myPath){

	// read in info file
	fileString=File.openAsString(myPath); 
	fileLines=split(fileString,"\r\n");

	j = 0; // counter for channels with names

	for(i=0;i<lengthOf(fileLines);i++){

		if(startsWith(fileLines[i],"Cell ID") > 0){
			cellID = fileLines[i+1];
		}

		if(startsWith(fileLines[i],"Size") > 0){
			trackImageSize = parseInt(fileLines[i+1]);
		}

		if(startsWith(fileLines[i],"Track length") > 0){
			smallFramesNum = parseInt(fileLines[i+1]);
		}

		if(startsWith(fileLines[i],"Slice start") > 0){
			sliceStart = parseInt(fileLines[i+1]);
		}
	}
}
///////////////////////////////////////////////////////////////////////////////////////////