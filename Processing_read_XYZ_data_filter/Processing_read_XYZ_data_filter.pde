import processing.serial.*;
import java.io.BufferedWriter;
import java.io.FileWriter;
// C_xxx  config.txt file related values  ====================
String[] C_text;                // array of lines  
int C_lines;                    // no lines in config file
String[] C_words;               // words separated by tab in a line
String C_first;                 // first character of C_words[0]

// G_xxx Colors and framesize  ===============================
color G_backg = color(0,0,0);
color G_text  = color(255,255,255);
color G_plotX = color(255,0,0);
color G_plotY = color(0,255,0);
color G_plotZ = color(255,255,0);
boolean G_showX = true;
boolean G_showY = true;
boolean G_showZ = true;
boolean G_filter = false;

// P_xxx serial Port related parameters  ====================
Serial P_serial;                // used comport, default second available [1] will be updated from config.txt file
int P_default = 1;              // default comport value (second available)
String P_recieved = "";         // received string
String P_send = "";             // string to send

// keyboard parameters
boolean keyUpdate = true;

// general purpose variables
int i = 0;
int j = 0;
int Phase = 1;   // 1 = run
int X = 0;       // 
int Y = 0;
int Z = 0;
float Xfilter = 0.0;
float Yfilter = 0.0;
float Zfilter = 0.0;
float Filter = 10.0;
int XYZmax = 1000; // range -XYZmax...XYZmax, out of range values will be coerced
float f = 0.0;


// load configfile "config.txt" from \Data directory ==========
void setup () {
  C_text = loadStrings("config.txt");
  C_lines = C_text.length;
  println("config.txt lines: ", C_lines);
  for (i=0; i<C_lines;i=i+1){
    C_words = split(C_text[i],'\t');
    C_first = C_words[0].substring(0,1);
        
    if (C_first.equals("p")) {      // comport
      if (C_words.length > 1) {
        println("portindex: "+ C_words[1]);
        P_default = int(C_words[1]);
      } // end  if length 
    } // end if equals
    
    if (C_first.equals("r")) {      // range
      if (C_words.length > 1) {
        println("range: "+ C_words[1]);
        XYZmax = int(C_words[1]);
      } // end  if length 
    } // end if equals
    
    if (C_first.equals("f")) {      // comport
      if (C_words.length > 1) {
        println("filtersize: "+ C_words[1]);
        Filter = float(C_words[1]);
      } // end  if length 
    } // end if equals
  } // end for i
  
  Filter = max(Filter,3);  // minumum filter size = 3
    
  size(640, 480);
  PFont font;
  font = loadFont("AgencyFB-Reg-25.vlw"); //copy from \Data directory!!
  textFont(font, 25);
  fill(G_text);
  background(G_backg);
  text(" r: run   spacebar: stop   esc: end", 0, 25);
  fill(G_plotX);
  text(" x: x on/off", 250, 25); 
  fill(G_plotY);
  text(" y: y on/off", 340, 25);
  fill(G_plotZ);
  text(" z: z on/off", 430, 25);
  fill(G_text);
  text(" f: filter on/off", 520, 25);
  
   // List all the available serial ports:
  printArray(Serial.list());
  // open selected serial port 
  P_serial = new Serial(this, Serial.list()[P_default], 38400);
  P_serial.clear(); // flush buffer
  P_serial.bufferUntil('\n'); // until end of line
  i = 0;
} // end setup
  
// serialEvent is executed data is available =========================================================== 
void serialEvent (Serial P_serial) {
  try { //2015-5-11 test if serialevent error can be trapped
    // get the ASCII string:
    String inString = P_serial.readStringUntil('\n');
    if (inString != null) {    // read [tab] separated data
      // trim off any whitespace:
      inString = trim(inString);
    }  // end if instring
    String [] XYZ = split(inString, '\t'); // split tab
    
    if (Phase == 1){
      X = int(XYZ[0]);
      Y = int(XYZ[1]);
      Z = int(XYZ[2]);
      if (X > XYZmax) {  // coerce if out of range
        X = XYZmax;
      } //end if X >
      if (Y > XYZmax) {
        Y = XYZmax;
      } //end if Y >
      if (Z > XYZmax) {
        Z = XYZmax;
      } //end if Z >
      XYZmax = XYZmax * -1;
      if (X < XYZmax) {
        X = XYZmax;
      } //end if X >
      if (Y < XYZmax) {
        Y = XYZmax;
      } //end if Y >
      if (Z < XYZmax) {
        Z = XYZmax;
      } //end if Z >
      XYZmax = XYZmax * -1;
      Xfilter = (((Filter-1.0) * Xfilter) + float(X))/Filter;
      Yfilter = (((Filter-1.0) * Yfilter) + float(Y))/Filter;
      Zfilter = (((Filter-1.0) * Zfilter) + float(Z))/Filter;
      
      println(inString); //test only
    
      if (G_showX) {
        fill(G_plotX);
        stroke(G_plotX);
        if (G_filter) {
          f = Xfilter;
        }
        else {  
          f = float(X);
        } // end if  
        j = 280 - int(f * 200.0 /float(XYZmax));
        point(i,j);
      } // enf if G_show  
    
      if (G_showY) {
        fill(G_plotY);
        stroke(G_plotY);
        if (G_filter) {
          f = Yfilter;
        }
        else {  
          f = float(Y);
        } //end if  
        j = 280 - int(f * 200.0 /float(XYZmax));
        point(i,j);
      } // enf if G_show  
      
      if (G_showZ) {
        fill(G_plotZ);
        stroke(G_plotZ);
        if (G_filter) {
          f = Zfilter;
        }
        else {  
          f = float(Z);
        } //end if  
        j = 280 - int(f * 200.0 /float(XYZmax));
        point(i,j);
      } // enf if G_show    
    
     i++;
     if (i >=640) {
       i = 0;
       fill(G_backg);
       stroke(G_backg);
       rect(0, 40,640, (480-40));
      }
    } //end if phase  
  } //end try
  catch(RuntimeException e) {
    // e.printStactTrace();
  }    
}
    
  
  void draw () {    // main loop ===========================================================================
  if (keyPressed && keyUpdate)  {      // check if keypressed
    keyUpdate = false;
    
    if (key == ' ') {                  //spacebar = stop
      Phase = 0;
    }
    
    if (key == 'r' || key == 'R') {    // start measurement
      Phase = 1; 
    }
    
    if (key == 'x' || key == 'X') {    // toggle show X
      G_showX = !G_showX; 
    }
    
    if (key == 'y' || key == 'Y') {    // toggle show Y
      G_showY = !G_showY; 
    }
    
    if (key == 'z' || key == 'Z') {    // toggle show Z
      G_showZ = !G_showZ; 
    }
    
    if (key == 'f' || key == 'F') {    // toggle filter
      G_filter = !G_filter; 
    }
  } // end keypressed
} // end draw 

void keyReleased() {
  keyUpdate = true;
}
 
    
