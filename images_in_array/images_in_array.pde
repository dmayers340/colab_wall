/* We want a program that will display images of various projects on a wall. The eclipse tracks hand movement.  
The user will move their hand to an image hold for a second and then be able to pull the image where they want (i.e. 
the middle of the screen). 
*/
import SimpleOpenNI.*;
SimpleOpenNI kinect;

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

//array for tiles
int [] tiles; 

//array for images
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
int cnt = 0;


//check if image is moving or not and if hands are in right position
boolean imageMoving;
//boolean handCoord;



void setup()
{
  size(1280, 960);
//  frameRate(24);
//  smooth();
  
  kinect = new SimpleOpenNI(this);
  kinect.enableDepth();   
 
  // start the image out moving
  // so mouse press will drop it
  imageMoving = true;
  
  tileSize = 300;
  margin = 20;
  column = (width-margin)/tileSize; 
  row = (height-margin)/tileSize;
  
  
  
 
  // load the image from a file
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
  
}

void draw()
{
  background(0);
  closestValue = 8000;
  kinect.update();
  
//prints images in a grid
 for (int col= 0; col<=column; col++)
  {
    for (int r=0; r<=row; r++)
    {  
        int whichImage = col*row+r;
        whichImage %= 11;
        image(images[whichImage], (col*tileSize), (r*tileSize), tileSize, tileSize);   
    }
    }
  
  
  //better so it doesn't look like a grid, but it needs work to put images in correct coordinates
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
   
   if(imageMoving)
   {
     imageX = interpolatedX;
     imageY = interpolatedY;
   }
   
   image(images[9], imageX, imageY);
  
 
  
  if(imageMoving = !imageMoving && secondHold >1)
  {
   imageMoving = !imageMoving;
  }
   //if has gesture movement then get img 
   //
   //draw the image on the screen
  // image(image1,image1X/2,image1Y/2);
   //draing overtop
 //  image(image2, image2X/2, image2Y/2);

   lastX = interpolatedX;
   lastY = interpolatedY;

 fill(255,0,0);
 ellipse(closestX, closestY, 25, 25);

   
}

