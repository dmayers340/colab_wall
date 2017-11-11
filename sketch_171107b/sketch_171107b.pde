import SimpleOpenNI.*;
SimpleOpenNI kinect;

//.shift for full screen
int secondHold = second();
int closestValue;
int closestX;
int closestY;
int numImages = 4;
PImage [] images = new PImage[numImages];
int handCoordX;
int handCoordY;
float lastX;
float lastY;

float imageX;
float imageY;

boolean imageMoving;
boolean handCoord;



void setup()
{
  size(1280, 960);
  frameRate(24);
  
  kinect = new SimpleOpenNI(this);
  kinect.enableDepth();   
 
  // start the image out moving
  // so mouse press will drop it
  imageMoving = true;
 
  // load the image from a file
 
  images[0] = loadImage("farm.png");
  images[1] = loadImage("mainb.jpg");
  images[2] = loadImage("well.png");
  images[3] = loadImage("mithras.jpg");
}

void draw()
{
   // clear the previous drawing
  background(0);
  closestValue = 8000;
  kinect.update();
  
  image(images[0], 0,0);
  image(images[1], (1280-images[1].width/2), 0);
  image(images[2], 0, (960- images[2].height));
  image(images[3], (1280-images[3].width), 0);
  
 
  int[] depthValues = kinect.depthMap();
  
    for(int y = 0; y < 480; y++){
      for(int x = 0; x < 640; x++){

        int reversedX = 640-x-1;        
        int i = reversedX + y * 640;
        int currentDepthValue = depthValues[i];
      
        if(currentDepthValue > 610 && currentDepthValue < 1525 && currentDepthValue < closestValue){

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
  
   if (secondHold > 1 && handCoord != false)
   {
      if(imageMoving){
       imageX = interpolatedX;
       imageY = interpolatedY; 
     }
   }
   
     if (handCoordX == 100 && handCoordY == 100) 
  {
    handCoord = true;
  }
  else handCoord = false;
  
 
  
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

