/* We want a program that will display images of various projects, people, events on a wall. 
The eclipse tracks hand movement.  
The user will move their hand to an image hold for a second and then be able to pull the image where they want (i.e. 
the middle of the screen). 
Once in the center, the image/video/content should be enlarged and display extra details

Can it do a video? <--Reminder: Check making things see book
*/
import SimpleOpenNI.*;
//import processing.video.*;
SimpleOpenNI kinect;

//Movie exampleMovie;

//.shift for full screen

//to hold for seconds
int secondHold = second();

//getting values of hand
int closestValue;
int closestX;
int closestY;

//hand tracking
float lastX;
float lastY;

//array for images--better as arraylist?? but then numImages is used to make the grid below
int numImages = 11;
PImage [] images = new PImage[numImages];

//getting hand coordinates
int handCoordX;
int handCoordY;

//image coords
float imageX;
float imageY;

//to create grid
int tileSize;
int margin;
int column;
int row;

//check if image is moving or not and if hands are in right position
boolean imageMoving;
boolean handCoord;

void setup()
{
  size(1280, 960);
  frameRate(24);
  smooth();
  
  //does this work for movie? <-- No it won't. PImage Array can't support a movie upload...but possible to store a movie somewhere else?
 // exampleMovie = new Movie(this, "find a movie and its path");
  //exampleMovie.loop();
  
  kinect = new SimpleOpenNI(this);
  kinect.enableDepth();   
   
 // start the image out moving so mouse press will drop it
  imageMoving = true;
  
  //setting up the grid
  tileSize = 300;
  margin = 20;
  column = (width-margin)/tileSize; 
  row = (height-margin)/tileSize;
  
   
  // load the image from a file--BETTER IN AN ARRAY LIST?--STILL NEED TO DEFINE THE LOAD, BUT EASIER TO UPLOAD CONTENT?
  images[0] = loadImage("farm.png");
  images[1] = loadImage("mainb.jpg");
  images[2] = loadImage("well.png");
  images[3] = loadImage("mithras.jpg");
  images[4] = loadImage("snowman.png");
  images[5] = loadImage("render_mainbuilding.png");
  images[6] = loadImage("mithraeum.jpg");
  images[7] = loadImage("download.jpg");
  images[8] = loadImage("one.png");
  images[9] = loadImage("two.png");
  images[10] = loadImage("three.png");
  
  //user tracking
// kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
  kinect.enableUser();
  
  
}

void draw()
{
  //do I want this to change to map a person? Probably not. 
  background(0);
  closestValue = 8000;
  kinect.update();
  
  //VECTOR Of ints to store list of user
  IntVector userList = new IntVector();
  kinect.getUsers(userList);
  
  if (userList.size()>0)
  {
    //first user
    int userID = userList.get(0);
    
    if (kinect.isTrackingSkeleton(userID))
    {
      PVector rightHand = new PVector();
      
      float confidence = kinect.getJointPositionSkeleton(userID, SimpleOpenNI.SKEL_LEFT_HAND, rightHand);
      
      PVector convertedRightHand = new PVector();
      kinect.convertRealWorldToProjective(rightHand, convertedRightHand);
      fill(255, 0,0);
      ellipse(convertedRightHand.x, convertedRightHand.y, 10,10);
    }
  }
//prints images in a grid. One image per tile. NEED TO TIDY UP GRID SO IT MAPS THE SCREEN
 for (int col= 0; col<=column; col++)
  {
    for (int r=0; r<=row; r++)
    {  
        int diffImage = col*row+r;
        diffImage %= numImages; 
        //image will be in the array, with x coord, y coord, width, height
        image(images[diffImage], (col*tileSize), (r*tileSize), tileSize, tileSize);   
    }
    }
  
  
  //better so it doesn't look like a grid, but it needs work to put images in correct coordinates and scale down images
//  for (int i = 0; i<images.length; i++)
//  {
//    
//    image(images[0], 0,0); //farm
//    image(images[1], (1280-images[1].width/2), 0); //main building
//    image(images[2], 0, (960- images[2].height)); //well
//    image(images[3], (1280-images[3].width), 0); //mithras
//    image(images[4], 450, 450); //snowman
//    image(images[5], 1280, 0); //mainbuilding 3d
//    image(images[6], 10, 10); //mithraeum
//    image(images[7], 200, 200); //brain
//  }
  
 
  int[] depthValues = kinect.depthMap();
  
  //what is this doing? --if x and y coordinates are a certain value, then it matches the hand (for elipse? ASK TOM
  //out of bounds if y and x = size of screen
    for(int y = 0; y < 480; y++)
    {
      for(int x = 0; x < 640; x++)
      {

        int reversedX = 640-x-1;        
        int i = reversedX + y * 640;
        int currentDepthValue = depthValues[i];
      
        if(currentDepthValue > 610 && currentDepthValue < 1525 && currentDepthValue < closestValue)
        {

          closestValue = currentDepthValue;
          closestX = x;
          closestY = y;
      
        }
      }
    }
//this gets the last place the hand is. 
   float interpolatedX = lerp(lastX, closestX, 0.3);   
   float interpolatedY = lerp(lastY, closestY, 0.3);
  
   // only update image position
   // if image is in moving state
   
//  if (handCoordX == 640 && handCoordY == 480) 
//  {
//    handCoord = true;
//  }
//  else handCoord = false;
//  
//   if (secondHold > 1 && handCoord != false)
//   {
//      if(imageMoving)
//      {
//       imageX = interpolatedX;
//       imageY = interpolatedY; 
//      }
//   }
   
   //If the image is moving, it should store image in the last place the hand coords were mapped
   if(imageMoving)
   {
     imageX = interpolatedX;
     imageY = interpolatedY;
   }
   
   //this brings image 10 to the last place...however this should be whatever image is grabbed...how to do this? images[diffImage]? TRY 
   //Draw image to screen
   image(images[9], imageX, imageY);
  
 
  //WHY?? ASK TOM. This does not make sense...
  //WANT: if the image is not moving and hold for more than one second then move the image to where hand coord is last mapped
  //so...TRY..if (!imageMoving && secondHold >1)? 
  if(imageMoving = !imageMoving && secondHold >1)
  {
   imageMoving = !imageMoving;
  }
   //if has gesture movement then get img --DON'T WORRY ABOUT GESTURES FOR NOW. JUST MOVE IMAGE TO LAST PLACE HAND WAS--MIDDLE SCREEN
 
   lastX = interpolatedX;
   lastY = interpolatedY;

//tracks hand movement...or should. VERY CHOPPY, FIGURE OUT HOW TO SMOOTH and accuratley track hand
// fill(255,0,0);
// ellipse(closestX, closestY, 25, 25);

   
}


