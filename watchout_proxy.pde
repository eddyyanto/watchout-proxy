/*
     Project      : Jaguar v2
     Created by   : Eddy
     Created date : 13 September 2011
     Description  : Proxy utility between multiple iPads control and WatchOut System
     Dependency   : ControlP5 http://www.sojamo.de/libraries/controlP5/
 */

import processing.net.*;
import controlP5.*;

Server myServer;
Client myClient;

ControlP5 controlP5;
Textarea txtLog;

float slider; //incremental value for animation x position
String animation; //keep track of animation position: left or right
boolean display_left_on; //left display active flag
boolean display_right_on; //right display active flag
float opacity; //incremental value for middle aux opacity

String command; //parse command
int pos, len;
String cue; //name of cue inside aux timeline
String aux_timeline; //name of aux timeline
String aux_timeline_left; //store position of last received aux timeline name
String aux_timeline_right;

SliderThread thread1;

void setup()
{
    size(500, 500);
    frameRate(15);
    background(0);

    //initialize a server on port 8080
    myServer = new Server(this, 8080);

    //open up a client connection to WatchOut Master
    myClient = new Client(this, "10.1.100.50", 3040);

    //set default values
    slider = 0;
    animation = "left";
    display_left_on = false;
    display_right_on = false;
    opacity = 0;
    command = "";
    aux_timeline = "";
    aux_timeline_left = "";
    aux_timeline_right = "";

    //add textarea to output log
    controlP5 = new ControlP5(this);
    txtLog = controlP5.addTextarea("label1", "", 10, 10, 480, 480);

    _log("Program started.");
}

void draw()
{
    //get the next available client
    Client thisClient = myServer.available();

    //if connection to watchout master died, reconnect
    if (!myClient.active()) {
        myClient = new Client(this, "10.1.100.50", 3040);
        _log("Reconnected to Watchout Master.");
    }

    if (thisClient !=null) {
        _log("Received from: " + thisClient.ip());
        //do not put $0D or carriage return from WatchOut
        String whatClientSaid = thisClient.readString();

        if (whatClientSaid != null) {
            //if the string is longer than 6 then it's from iPad, intercept it and forward to WatchOut
            //example command from iPad: gotoControlCue 01 true L_XF / run L_XF
            if (whatClientSaid.length() > 6) {
                //determine what command it is : gotoControlCue or run
                command = trim(whatClientSaid.substring(0, whatClientSaid.indexOf(" ")));

                if (command.equals("gotoControlCue")) {
                    //example command : gotoControlCue 01 true XF_L
                    pos = whatClientSaid.indexOf("true");
                    len = whatClientSaid.length();

                    //get aux timeline name
                    aux_timeline = trim(whatClientSaid.substring(pos + 5, len));

                    //get named cue
                    cue = trim(whatClientSaid.substring(pos - 3, pos -1));

                    //transform XF_L into L_XF
                    pos = aux_timeline.indexOf("_");
                    len = aux_timeline.length();
                    aux_timeline = aux_timeline.substring(len -1, len) + "_" + aux_timeline.substring(0, pos);

                    if (aux_timeline.substring(0, 2).equals("L_")) {
                        if (aux_timeline_left.length() > 3) {
                            myClient.write("kill " + aux_timeline_left + "\n");
                        }

                        aux_timeline_left = aux_timeline;
                        _log("Last left photo aux : " + aux_timeline_left);
                    }
                    else if (aux_timeline.substring(0, 2).equals("R_")) {
                        if (aux_timeline_right.length() > 3) {
                            myClient.write("kill " + aux_timeline_right + "\n");
                        }
                        aux_timeline_right = aux_timeline;
                        _log("Last right photo aux : " + aux_timeline_right);
                    }

                    //for gotoControlCue with named cue to work, we need to kill it first and then add some delay
                    myClient.write("kill " + aux_timeline + "\n");
                    delay(50);

                    myClient.write("gotoControlCue \"" + cue + "\" true \"" + aux_timeline + "\"\n");
                    myClient.write("run " + aux_timeline + "\n");
                }
                else if (command.equals("run")) {
                    //example command : run L_XF
                    pos = whatClientSaid.indexOf(" ");
                    len = whatClientSaid.length();

                    aux_timeline = trim(whatClientSaid.substring(pos + 1, len));

                    //store last aux timeline value (left or right) so that we can kill it if new one starts
                    //p.s: it's no longer necessary to issue kill command from iPads
                    if (aux_timeline.substring(0, 2).equals("L_")) {
                        if (aux_timeline_left.length() > 6) {
                            myClient.write("kill " + aux_timeline_left + "\n");
                        }
                        aux_timeline_left = aux_timeline;
                        _log("Last left video aux : " + aux_timeline_left);
                    }
                    else if (aux_timeline.substring(0, 2).equals("R_")) {
                        if (aux_timeline_right.length() > 6) {
                            myClient.write("kill " + aux_timeline_right + "\n");
                        }
                        aux_timeline_right = aux_timeline;
                        _log("Last right video aux : " + aux_timeline_right);
                    }

                    myClient.write("run " + aux_timeline + "\n");
                }
                aux_timeline = "";
            } //end if (whatClientSaid != null)

            //if whatClientSaid contains only one char, it's from WatchOut
            if (whatClientSaid.length() == 1) {
                //receive from WatchOut when left aux starts
                if (whatClientSaid.equals("m")) {
                    _log("Received : " + whatClientSaid + " | left aux started.");

                    //turn off volume if it's video
                    if (aux_timeline_left.indexOf("VIDEO") > 1) {
                        myClient.write("setInput volume 0\n");
                    }

                    display_left_on = true;

                    //slide animation to right only when right display is off else stay put
                    if (display_right_on == false) {
                        animation = "right";
                        new SliderThread("right").start();
                    }
                }

                //receive from WatchOut when left aux ends
                if (whatClientSaid.equals("n")) {
                    _log("Received : " + whatClientSaid + " | left aux ended.");

                    //turn on volume if both displays are inactive
                    if (display_right_on == false) {
                        myClient.write("setInput volume 1\n");
                    }

                    display_left_on = false;
                }

                //receive from WatchOut when right aux starts
                if (whatClientSaid.equals("o")) {
                    _log("Received : " + whatClientSaid + " | right aux started.");

                    //turn off volume if it's video
                    if (aux_timeline_right.indexOf("VIDEO") > 1) {
                        myClient.write("setInput volume 0\n");
                    }

                    display_right_on = true;

                    //slide animation to left only when left display is off else stay put
                    if (display_left_on == false) {
                        animation = "left";
                        new SliderThread("left").start();
                    }
                }

                //receive from WatchOut when right aux ends
                if (whatClientSaid.equals("p")) {
                    _log("Received : " + whatClientSaid + " | right aux ended.");

                    //turn on volume if both displays are inactive
                    if (display_left_on == false) {
                        myClient.write("setInput volume 1\n");
                    }

                    display_right_on = false;
                }

                //free running animation slider
                if (whatClientSaid.equals("q")) {
                    //do not slide when any one of auxiliary timeline is on
                    if (display_right_on == false && display_left_on == false) {
                        if (animation.equals("left")) {
                            animation = "right";
                            new SliderThread("right").start();
                        }
                        else {
                            animation = "left";
                            new SliderThread("left").start();
                        }
                    }
                }
            } //end if (whatClientSaid.length() == 1)

            //if both display are on, run MIDDLE aux
            if (display_right_on == true && display_left_on == true) {
                _log("Display : both");

                //start middle auxiliary timeline
                myClient.write("run MIDDLE\n");

                //todo:a better implementation of fade in/out for images.
                //fade in/out the black placeholders
                myClient.write("setInput black_left 1\n");
                myClient.write("setInput black_right 1\n");

                while (opacity < 1) {
                    opacity = opacity + 0.01; 
                    myClient.write("setInput opacity " + opacity + "\n");
                    delay(6);
                }
            }
            else if (display_right_on == true && display_left_on == false) {
                _log("Display : right");

                //fade in/out the black placeholders
                myClient.write("setInput black_left 0\n");
                myClient.write("setInput black_right 1\n");

                while (opacity > 0) {
                    opacity = opacity - 0.01; 
                    myClient.write("setInput opacity " + opacity + "\n");
                    delay(6);
                }

                //kill middle aux
                myClient.write("kill MIDDLE\n");

                //preventive: slide animation to the left
                animation = "left";
                slide_left();
            }
            else if (display_right_on == false && display_left_on == true) {
                _log("Display : left");

                //fade in/out the black placeholders
                myClient.write("setInput black_left 1\n");
                myClient.write("setInput black_right 0\n");

                while (opacity > 0) {
                    opacity = opacity - 0.01; 
                    myClient.write("setInput opacity " + opacity + "\n");
                    delay(6);
                }

                //kill middle aux
                myClient.write("kill MIDDLE\n");

                //preventive: slide animation to the right
                animation = "right";
                slide_right();
            }
            else if (display_right_on == false && display_left_on == false) {
                _log("Display : none");

                //fade in/out the black placeholders
                myClient.write("setInput black_left 0\n");
                myClient.write("setInput black_right 0\n");

                while (opacity > 0) {
                    opacity = opacity - 0.01; 
                    myClient.write("setInput opacity " + opacity + "\n");
                    delay(6);
                }

                //kill middle aux
                myClient.write("kill MIDDLE\n");
            }
        }
    } //end if (thisClient !=null)
}

void _log(String log) {
    println(log);
    background(0); //a hack to prevent controlP5 textarea from overlapping text, ref: http://processing.org/discourse/yabb2/YaBB.pl?num=1246830224

    txtLog.setText(hour() + ":" + minute() + ":" + second() + "\t" + log + "\n" + txtLog.text());
}

// updated to use third "fade rate" parameter
void slide_right() {
    // while (slider < 1) {
    //     slider = slider + 0.01; 
        myClient.write("setInput animation_x " + slider + " 500\n");
    //     delay(6);
    // }
}

// updated to use third "fade rate" parameter
void slide_left() {
    // while (slider > 0) {
    //     slider = slider - 0.01; 
        myClient.write("setInput animation_x " + slider + " 500\n");
    //     delay(6);
    // }
}

class SliderThread extends Thread {
    String position;
    SliderThread (String animation) {
        position = animation;
    }

    void start () {
        super.start();
    }

    // We must implement run, this gets triggered by start()
    void run () {
        if (position.equals("left")) {
            while (slider > 0) {
                slider = slider - 0.01; 
                myClient.write("setInput animation_x " + slider + "\n");
                try {
                    sleep((long)(6));
                } 
                catch (Exception e) {
                }
            }
        }
        else if (position.equals("right")) {
            while (slider < 1) {
                slider = slider + 0.01; 
                myClient.write("setInput animation_x " + slider + "\n");
                try {
                    sleep((long)(6));
                } 
                catch (Exception e) {
                }
            }
        }
        this.quit();
    }

    // Our method that quits the thread
    void quit() {
        interrupt();
    }
}
