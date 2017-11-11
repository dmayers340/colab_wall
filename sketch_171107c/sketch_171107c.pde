import SimpleOpenNI.*;
SimpleOpenNI  kinect;

// declare these here
// so they persist over multiples
// runs of draw()
int closestX;
int closestY;
int currentX;
int currentY;

float image1X;
float image1Y;

PImage image1;


void setup()
{
  size(640, 480);
  kinect = new SimpleOpenNI(this);
  kinect.enableDepth(); 

image1 = loadImage("farm.png");

background(0);
}

void draw()
{
  background(0);
  // declare these within the draw loop
  // so they change every time
  int closestValue = 8000;
 

  kinect.update();

  // get the depth array from the kinect
  int[] depthValues = kinect.depthMap();
  
    // for each row in the depth image
    for(int y = 0; y < 480; y++){
      // look at each pixel in the row
      for(int x = 0; x < 640; x++){
        // pull out the corresponding value from the depth array
        int i = x + y * 640;
        int currentDepthValue = depthValues[i];
      
        // if that pixel is the closest one we've seen so far
        if(currentDepthValue > 0 && currentDepthValue < closestValue)
        {
          // save its value
          closestValue = currentDepthValue;
          // and save its position (both X and Y coordinates)
          currentX = x;
          currentY = y;
        }
      }
    }
  
  // closestX and closestY become
  // a running average with currentX and currentY
  closestX = (closestX + currentX) / 2;
  closestY = (closestY + currentY) / 2;
 
  
  
    
  //draw the depth image on the screen
  //image(kinect.depthImage(),0,0);
  
  // draw a red circle over it, 
  // positioned at the X and Y coordinates 
  // we saved of the closest pixel.
  fill(255,0,0);
  ellipse(closestX, closestY, 25, 25);
  
  
  //millisecond counter--if hold for 2 sec can then move //if closest values are x and y and time.deltatime has elapsed can then
 //save the last pos to be current pos of new image 
  if(closestX < 50 && closestY < 50 )
  {
    image1();
  }
  
}


void image1()
{
    image1 = loadImage("farm.png");
    image(image1,image1X,image1Y);

    rect(100,100,100,100);
}

  
