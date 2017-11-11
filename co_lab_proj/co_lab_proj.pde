import SimpleOpenNI.*;
SimpleOpenNI kinect;

int secondHold = second();

int closestValue;

int closestX;
int closestY;


int handCoordX;
int handCoordY;

float lastX;
float lastY;

//.shift for full screenn
// declare x-y coordinates
// for the image
float image1X;
float image1Y;

// declare a boolean to
// store whether or not the
// image is moving
boolean imageMoving;
boolean handCoord;

// declare a variable
// to store the image
PImage image1;


void setup()
{
  size(1280, 960);
  kinect = new SimpleOpenNI(this);
  kinect.enableDepth();   
 
  // start the image out static so hand hold grabs and moves
  imageMoving = true;
 
  // load the image from a file
  image1 = loadImage("farm.png");
  img
   
}

void draw()
{
  background(0);
  closestValue = 8000;
  kinect.update();

  int[] depthValues = kinect.depthMap();
  
    for(int y = 0; y < 480; y++){
      for(int x = 0; x < 640; x++){

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
   
  if (handCoordX == 640 && handCoordY == 480) 
  {
    handCoord = true;
  }
  else handCoord = false;
  
  //IF hand is in the coordinants and hold for 1 sec then move the image
   if (secondHold > 1 && handCoord)
   {
      if(imageMoving)
      {
       image1X = interpolatedX;
       image1Y = interpolatedY; 
      }
   }
   

  
  //why?
  if(imageMoving = !imageMoving && secondHold >1)
  {
     imageMoving = !imageMoving;
  }
   //img x coord, y coord, width, height
   //draw the image on the screen
   image(image1, 100, 100, image1X/2,image1Y/2);
  // image(image2, 640, 480, image2X/2, image2Y/2);

   lastX = interpolatedX;
   lastY = interpolatedY;

  fill(255,0,0);
  ellipse(closestX, closestY, 25, 25);
 


   
}

