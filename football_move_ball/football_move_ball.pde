//for using the kinect
import SimpleOpenNI.*;
SimpleOpenNI kinect;
//storing current hand positions
ArrayList<PVector> handPositions;
PVector currentHand;

PFont f;
PImage b;
Thing t;



void setup() {
  size(1000,660);
  
  // for scores
  f = loadFont("Serif-48.vlw");
  smooth();
  
  // Create the thing object
  PVector a = new PVector(0.0,0.0);
  PVector v = new PVector(0.0,0.0);
  PVector l = new PVector(width/2,height/2);
  t = new Thing(a,v,l);
  
  //for background image
  b = loadImage("footballfield.jpg");
  //innitialize the kinect 
  kinect = new SimpleOpenNI(this);
  kinect.setMirror(true);
  kinect.enableDepth();
  kinect.enableGesture();
  kinect.enableHands();
  kinect.addGesture("RaiseHand"); 
  handPositions = new ArrayList(); 
}

void draw() {
  //getting information from the kinect
  kinect.update();
  //scale(2);
  //image(kinect.depthImage(), 0, 0);
  
  background(b);
  fill(0);
  //player1
  ellipse (width/3, height/4, 30, 50);
  //player2
  ellipse (width/3, 3*height/4, 30, 50);
  //player3
  ellipse (width/4, height/2, 30, 50);
  //player4
  ellipse (2*width/3, height/4, 30, 50);
  //player5
  ellipse (2*width/3, 3*height/4, 30, 50);
  //player6
  ellipse (3*width/4, height/2, 30, 50);
  
  //acceleration of the ball
  float factor;
  //start collecting information from the kinect
 for (int i = 1; i < handPositions.size(); i++) 
 {
  currentHand = handPositions.get(i);
  //suggested: currentHand = handPositions.get(handPostions.size()-1);
  //draw an ellipse at where the hand is
  ellipse(currentHand.x, currentHand.y,20,20);
  // Run the Thing object
  t.go();
   if (dist(currentHand.x, currentHand.y, t.loc.x, t.loc.y) < 60  ) {
    // Compute difference vector between handposition and object location
    //  (1) Get hand Location, (2) Get Difference Vector, (3) Normalize difference vector
    PVector m = new PVector(currentHand.x,currentHand.y);
    PVector diff = PVector.sub(t.getLoc(),m);
    diff.normalize();
    /*if hand is on the ball, stop it
    if (dist(currentHand.x,currentHand.y, t.loc.x, t.loc.y) < 20  )
    {
      t.vel.x = 0.0;
      t.vel.y = 0.0;
    }
    */
    factor = 0.005;  //acceleration constant
    diff.mult(factor);
    //object accelerates away from kinect hand position 
    t.setAcc(diff);
  
}

else {
    t.setAcc(new PVector(0,0));
  }
 
  textFont(f, 50);                 
  fill(255);                        
  //display scores
  text(t.rgoal,50,100);
  text(t.lgoal,width-75,100);

 }
}
