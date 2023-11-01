# LSystems-Chaos-Fractals
A macOS application to generating and animating LSystems, Chaos Theory's Strange Attractors, and Fractals

I wrote this app in my spare time.  I had written a few fractal generators in C++ and libPNG years ago and wanted to consolidate those old programs into a single application. It could use more GUI elements to make the user experience better. (So far the only user has been the developer, who can just edit and rebuild as needed).  But with that said, it is usable through the GUI todo some cool things and some more features are in the works (as always).

![Gif of Attractor](/Examples/Screenshots/Attractor_Animated.gif)

## Features
* Leverages Metal to render drawings
* Uses the NSDocument class to archive rules, axioms, and colors
* Real-time editting (for reasonable iteration limits)
  * Attractor conditions can be modified and colors changed, then rendered automatically   
* Multiple coloring options
  * Solid colors (LAB palette)
  * Customizable gradients
  * Coloring map (the color of each pixel picked from a provided map)
* Animations
  * All of the variables in a Strange Attractor document are animatable
  * Useful for seeing the chaos in action, i.e. slight changes to the initial conditions
* Video and Image Output
  * Animation can be saved as .mov files   

## "I actually downloaded your program"
Don't panic.  Try one of the included examples by going to File->Open, selecting the .lsys or .attr file, and then click "Show Drawing"   

## L-Systems
L-Systems or Lindenmayer systems are a type of drawing procedure with a formal grammar.  Originally, Aristid Lindenmayer invented L-Systems to study theoretic biology in 1968, but they can also be used to draw self-similar objects like the Dragon Curve or the Sierpinski Triangle.
A string is generated from an axiom, a set of variables, and a set of rules.  This string represents a list of drawing commands.  The variable can specify things like how many units to move or how many degrees to turn.  The rule outline how to replace the variables on each iteration.
For example, to generate the Sierpinski Triangle start with the axiom F-F-F. (Or draw - turn 120° - draw - turn 120° - draw). And use the rules F = "F-G+F+G-F" and G = "GG". (G also means draw). After 1 iteration, the string becomes "F-G+F+G-F-F-G+F+G-F-F-G+F+G-F"

## Strange Attractors
An attractor is strange if it has a fractal structure (according [Wikipedia](https://en.wikipedia.org/wiki/Attractor#Strange_attractor)).  The attractors in this program are produced using an iterative function which is currently hardcoded in PickoverAttractorOperation.main()
It is:
```
let new_x: Float = sin(A*y) + z*cos(B*x)
let new_y: Float = z*sin(C*x) - cos(D*y)
let new_z: Float = sin(x)
```
Another example to try would be:
```
let new_x: Float = sin(A*y) + cos(B*x)
let new_y: Float = sin(C*x) + cos(D*y)
let new_z: Float = z
```

## Fractals
Newtonian and Julian fractals are mostly implemented on a separate branch, but not ready to be user facing (the issues below take the cake).  Will try to add these sooner than later

# Screen Shots
![Screenshot of Bush](/Examples/Screenshots/Cool_Bush_Screenshot.png)
![Screenshot of Evergreen](/Examples/Screenshots/Evergreen_Screenshot.png)
![Screenshot of Triangle](/Examples/Screenshots/Sieroinskis_Triangle_Screenshot.png)
![Screenshot of Attractor](/Examples/Screenshots/Attractor_Screenshot.png)

# Issues
## More friendly GUI
+ Currently the only way to zoom the draw is to use the pinch gesture on the trackpad of a laptop.  Need to add hotkey options (and add help dialog to explain this)
  + Panning also in 3D renderer (uses 2 finger swipe on trackpad) 
+ Video output url textbox is broken (might be hardcoded)
+ Add way to remove variables and rules in lsystems
+ Color info for lsystems seems to hardcoded to a colormap, add coloring options like attractors
+ Color panels in attractors windows not saved in document/ not loading
+ Add blurb in color selector "Click to apply color" above preview panel
+ Maybe allow other color palettes over than LAB
+ Allow user to color map (currently hardcoded)
+ Add reordering to color gradient picker
+ Double check animations are working correctly
+ LSystem renderer creates some artifacts near the origin
+ Video capture can be non responive at time, there might be a memory leak or maybe too much work on the main thread


# References
* Some of the examples and formulas were found on [Paul Bourke's website](https://paulbourke.net/fractals/), which contains an extensive collections of everything self-similar and fractal.
