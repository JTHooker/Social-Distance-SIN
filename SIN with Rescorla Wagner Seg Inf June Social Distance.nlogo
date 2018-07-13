turtles-own [ speed speed-limit speed-min energy collisionsbikes timenow vmax vmin saliencybike initialassociationstrength care newv memory
       saliencyopenroad newassociationstrength selfcapacity care_attitude crashed ]
globals

   [ collisions
  grid-x-inc               ;; the amount of patches in between two roads in the x direction
  grid-y-inc               ;; the amount of patches in between two roads in the y direction


; patch-agentsets
 intersections
 roads
   ]

  breed [ cars car ]
  breed [ bicycles bike ]
  breed [ pedestrians pedestrian ]
  breed [ barriers barrier ]
  breed [ cities city ]
  breed [ planners planner ]
  breed [ building buildings ]
  breed [ points point ]


bicycles-own [ VRUdensity targetb ]
cars-own [ targetc mates ]
planners-own [ targetp ]


patches-own
[
  intersection?   ;; true if the patch is at the intersection of two roads
  my-row          ;; the row of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.
  my-column       ;; the column of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.
  ]


to setup
  clear-all
    ;; create turtles on random patches.
      setup-globals
  setup-patches
 ;; set Network 0
  ; create cars on green areas
    ask n-of initial_cars (patches with [pcolor = one-of [ grey green ]])
  [
    sprout 1
      [ set breed cars set color white set shape "circle" set speed .8
          set speed-limit max_speed_cars set speed-min 0  set energy random 30 set heading one-of [ 0 90 180 270 ]  set collisionsbikes 0
             set timenow 0 set vmax maxv set vmin minv set saliencybike BicycleSaliency set selfcapacity .05 set saliencyopenroad roadsaliency
        set initialassociationstrength initialv set newassociationstrength initialv set memory memoryspan  set timenow random memoryspan ]

]
  ; create bikes on green areas
   ask n-of initial_bicycles (patches with [ pcolor = grey ])
  [
    sprout 1
      [ set breed bicycles set speed .3 set size .8
  set speed-limit max_speed_bikes set speed-min .05 set energy random 100 set VRUdensity 0 set color black set shape "circle" set heading random 360 set crashed 0 ]
  ]
  ; create cities of blue areas
  ;;ask n-of 4225 (patches with [ pcolor = blue ]) [ sprout 1
  ;;  [ set breed cities set size 1 set color blue set shape "square" ]]

;; create pathways by planners
ask n-of Pathbuilders (patches with [ pcolor = grey ] )
[
    sprout 1 [
      set breed planners set speed 100 set color green set targetp one-of points face targetp ]
]


      ask cars [ put-on-empty-road calculatemates ]
      ask bicycles [ put-on-empty-road ]
      ask planners [ put-on-empty-road ]
      set pathbuilders 0

 reset-ticks
end

to setup-globals
  set grid-x-inc world-width / grid-size-x
  set grid-y-inc world-height / grid-size-y

end

to separate-cars  ;; turtle procedure
  if any? other cars-here
    [ fd 1 separate-cars ]
end

to setup-patches
ask patches
  [
    set intersection? false
    set my-row -1
    set my-column -1
    set pcolor blue

  ]

  ;; initialize the global variables that hold patch agentsets
  set roads patches with
    [(floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0) or
    (floor((pycor + max-pycor) mod grid-y-inc) = 0)]
    set intersections roads with
    [(floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0) and
    (floor((pycor + max-pycor) mod grid-y-inc) = 0)]
  ask roads [ set pcolor grey ]
  ask n-of (count roads * network2) roads [ set pcolor green ]
  ;; import-pcolors "Melbmap2.png"
    setup-intersections
    build
end

to setup-intersections
  ask intersections
  [
    set intersection? true
    set my-row floor((pycor + max-pycor) / grid-y-inc)
    set my-column floor((pxcor + max-pxcor) / grid-x-inc)
     ]
end

to build
  ask patches with [ pcolor = blue ] [ sprout 1 [ set breed building set color blue set size 1 set shape "square" set heading 0  ] ]
  ask n-of Points_of_Interest patches with [ pcolor = blue ] [ sprout 1 [ set breed points set color yellow set size 1 set shape "cylinder" ] ]
end

to separate-pedestrians  ;; turtle procedure
  if any? other pedestrians-here
    [ fd 1 separate-pedestrians ]
end

to collide ;count collisions - collision risk reduces at rate proportional to newassociation strength
  if speed > 0 and any? bicycles-on patch-here and (newassociationstrength * 10 ) < random 10  and pcolor = grey [ set collisionsbikes 1 set shape "star" ]
  if not any? bicycles-on patch-here [ set collisionsbikes 0 set shape "circle" ]
end


to iceblock
  if count bicycles-on patch-here > 0 [ set VRUdensity (count bicycles in-radius 1 )]
end

to car-energy
  if not any? cars-on patch-ahead 1 and patch-ahead 1 != blue [ set energy energy + energy-from-roads ]
  if patch-here = grey [ set energy energy + energy-from-roads ]
end

to bike-energy
  if not any? cars-on patch-ahead 1 and [ pcolor ] of patch-here = green [ set energy energy + energy-from-roads ]
end

to death
   if energy > 30 [ set energy random 30 ]
   if energy < 0 [ die ]
end

;;to max-turtles-cars
;;  if count cars < (initial_cars )[ reproduce ]
;;end

to morebikes
   if more_bikes and count bicycles <= 1000 [ reproducebicycles ]
end




;;to
;;  reproduce
;;  if energy > 15 [ hatch 1 fd ( - random drop ) set energy random 30 ]
;;end

to reproducebicycles ;;limit the number of bicycles in the system
   ask one-of bicycles [ hatch 1 fd ( - random drop ) set energy random 30 ]
end

to
  go
  ;; if ticks >= 1280 [ stop ]
       if ticks > Origdest
   [
         ask cars [
    let bicycle-ahead one-of bicycles-on patch-ahead 1
    ifelse bicycle-ahead != nobody and [ pcolor ] of patch-ahead 1 = gray
          [ set speed  [ speed ] of bicycle-ahead
        slow-down-turtle ]
      ;; otherwise, speed up
      [ speed-up-turtle ]
    ;;; don't slow down below speed minimum or speed up beyond speed limit
    if speed < speed-min  [ set speed speed-min ]
    if speed > speed-limit  [ set speed speed-limit ]
    fd speed ]
]
    if ticks > Origdest [
    ; and for bicycles
    ask bicycles [
    let turtle-ahead one-of turtles-on patch-ahead 1
    ifelse turtle-ahead != nobody and [ pcolor ] of patch-ahead 1 = gray
      [ set speed  [ speed ] of turtle-ahead
        slow-down-turtle ]
      ;; otherwise, speed up
      [ speed-up-turtle ]
    ;;; don't slow down below speed minimum or speed up beyond speed limit
    if speed < speed-min  [ set speed speed-min ]
    if speed > speed-limit  [ set speed speed-limit ]
    fd speed ]
    ]
        ask cars [ separate-cars death turntoo calculatecarefactor remember resetinitial colour tracker avoidbuildings collide ]
        ask bicycles [ bike-energy iceblock death turn hadacrash check-bicycles avoidbuildings bali coallesce ]
        ask planners [ maketracks avoidbuildings ]
    changenetwork
    growpoints
    killpoints
    growinfrastructureovertime
    morebikes
    swapcarsforbikes
    tick
 end

to avoidbuildings
  if any? building-on patch-ahead 1 [ set heading heading + one-of [ 45 -45 ] ]
end

to hadacrash
   if any? cars-here with [ collisionsbikes = 1 ] [ set crashed 1 ]
   if not any? cars-here with [ collisionsbikes = 1 ] [ set crashed 0 ]
   if not any? cars-here [ set crashed 0 ]
end

to maketracks
  ask patch-here [ set pcolor green ]
  face targetp fd 1
  if ticks > origdest [ die ]
end

to bali
  ifelse [ pcolor ] of patch-here = green [ set color blue ] [ set color black ]
end


to calculatecarefactor
  if pcolor = grey and memory = 1 [ set newv ( ( saliencybike * Saliencyopenroad ) * (( vmax - initialassociationstrength ) * ( Careattitude * selfcapacity )))  ]
  if newv > vmax [ set newv vmax ]
  if newv < vmin [ set newv vmin ]
  set newassociationstrength ( initialassociationstrength + newv )
  set vmax maxv set vmin minv
  set saliencybike BicycleSaliency set Saliencyopenroad Roadsaliency set selfcapacity capacity
  if saliencybike > 1 [ set saliencybike 1 ]
  if saliencyopenroad > 1 [ set saliencyopenroad 1 ]
end

to resetinitial
    if newassociationstrength <= maxv [ set initialassociationstrength ( newassociationstrength ) ]

end

to turn
     if random 1000 < stray [  set targetb one-of points face targetb ]
     if any? points-on patch-at-heading-and-distance 0 2 [ set targetb one-of points face targetb ]
end

to turntoo
     if random 1000 < straycars [ set targetc one-of points face targetc ]
     if any? points-on patch-at-heading-and-distance 0 2 [ set targetc one-of points face targetc ]
end

to put-on-empty-road  ;; turtle procedure
  move-to one-of intersections
end

to slow-down-turtle  ;; turtle procedure
  set speed speed - .1
end

to speed-up-turtle  ;; turtle procedure
  set speed speed + .1
end

to remember ;; if cars see a bike ahead of them on a road that is not segregated they remember that they have seen a bike - This is the gateway to losing memory that there were bikes on the road you just travelled on
  if any? bicycles-on patch-ahead 1 and [ pcolor ] of patch-ahead 1 = grey [ set memory 1 set timenow ticks ]
    if ticks - timenow >= memoryspan [ set memory 0 set newassociationstrength ( newassociationstrength - (newassociationstrength * ( saliencybike * saliencyopenroad )))  ] ;; > has been changed to >= to see if the saliency variable drops at low levels in response
     if memory = 0 [ set color white ]
     if memory = 1 [ set color red ]
end


to check-bicycles
   if [ pcolor ] of patch-here = grey and any? cars-on patch-here
    [ set energy energy + car-on-pedestrian ]
end

to tracker
  ifelse track [ pen-down ] [ pen-up ]
end

to colour
  if shade [ set color newassociationstrength * 10 + white ]
end

to growpoints ;;increases the number of points of interest in the network that attract activi
  if Points_of_Interest > ( count points ) [
    ask n-of 1 patches with [ pcolor  = blue ]  [ sprout 1 [ set breed points set color yellow set size 1 set shape "cylinder" ]
      ]]
end

to killpoints
   if Points_of_Interest < ( count points ) [
    ask n-of 1 points [ die ]
      ]
end

to changenetwork
  if count patches with [ pcolor = green ] > network [
  ask n-of Infrastructure_build patches with [ pcolor = green ]  [ set pcolor grey ]  ]


  if count patches with [ pcolor = green ] < network [
  ask n-of infrastructure_build patches with [ pcolor = grey ] [ set pcolor green ] ]
end

to growinfrastructureovertime
  if growinfrastructure = true
   [ set network ticks ]
end

to calculatemates
  ifelse any? bicycles in-radius friendshipradius [ set Care_attitude (CareAttitude + (1 - (1 / sqrt count bicycles in-radius friendshipradius)) / 2 ) ] [ set Care_Attitude CareAttitude ]
  ;; set mates min-one-of bicycles [ distance myself ]
  ;;set mates bicycles with [ distance myself < friendshipradius ]
end

to swapcarsforbikes
  if Less_cars = true and count bicycles < 1001 and count cars > 0 [
    ask one-of cars [ die ]
    ask one-of patches [ sprout-bicycles 1 [ set speed .3 set size .8
      set speed-limit max_speed_bikes set speed-min .05 set energy random 100 set VRUdensity 0 set color black set shape "circle" set heading random 360 set crashed 0 ]]
  ]

  if More_cars = true and count bicycles > 1  [
    ask one-of bicycles [ die ]
    ask one-of patches [ sprout-cars 1 [ set color white set shape "circle" set speed .8
          set speed-limit max_speed_cars set speed-min 0  set energy random 30 set heading one-of [ 0 90 180 270 ]  set collisionsbikes 0
             set timenow 0 set vmax maxv set vmin minv set saliencybike BicycleSaliency set Care_attitude ( CareAttitude + (random 50 / 100 )) set selfcapacity .05 set saliencyopenroad roadsaliency
          set initialassociationstrength initialv set newassociationstrength initialv set memory memoryspan  set timenow random memoryspan ]]]

end

to coallesce
  if VRUdensity < Local_Density and DensityTrigger > random 1000 [ move-to one-of other bicycles fd 5 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
715
16
1378
680
-1
-1
5.0
1
10
1
1
1
0
1
1
1
-65
65
-65
65
1
1
1
ticks
30.0

BUTTON
7
28
70
61
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
100
30
163
63
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
216
255
354
300
Percentage of bicycles
( count bicycles ) / ( count turtles - count cities ) * 100
2
1
11

SLIDER
9
185
181
218
Initial_cars
Initial_cars
0
5000
2000.0
250
1
NIL
HORIZONTAL

SLIDER
10
222
182
255
Initial_bicycles
Initial_bicycles
0
2000
50.0
50
1
NIL
HORIZONTAL

SLIDER
380
68
628
101
Max_Speed_Cars
Max_Speed_Cars
0
1
1.0
.1
1
NIL
HORIZONTAL

SLIDER
381
111
562
144
Max_Speed_Bikes
Max_Speed_Bikes
0
.5
0.3
.1
1
NIL
HORIZONTAL

SLIDER
197
67
369
100
energy-from-roads
energy-from-roads
0
1
0.0
.01
1
NIL
HORIZONTAL

SLIDER
9
104
179
138
car-on-pedestrian
car-on-pedestrian
-10
0
0.0
.01
1
NIL
HORIZONTAL

SLIDER
7
65
179
98
straycars
straycars
0
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
201
110
373
143
car-on-car
car-on-car
-20
0
-3.0
1
1
NIL
HORIZONTAL

PLOT
8
355
420
475
Population
Time
NIL
0.0
10.0
0.0
10.0
true
true
"" "if ticks = Origdest [ clear-plot ]"
PENS
"Bicycles" 1.0 0 -10899396 true "" "plot count bicycles"
"Collisions" 1.0 0 -7500403 true "" "plot count cars with [ collisionsbikes = 1 ] * 10"
"BikeCrashes" 1.0 0 -2674135 true "" "plot count bicycles with [ crashed = 1 ] * 10"

MONITOR
443
10
500
55
Bikes
count bicycles
17
1
11

MONITOR
503
10
560
55
Cars
count cars
17
1
11

MONITOR
624
514
705
559
VRU Density
mean [ vrudensity] of bicycles
2
1
11

MONITOR
574
159
666
204
Bike Accidents
count cars with [ collisionsbikes = 1 ]
17
1
11

PLOT
421
354
687
504
VRU Density
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" "if ticks = Origdest [ clear-plot ]"
PENS
"VRU Density" 1.0 0 -16777216 true "" "plot mean [ VRUdensity ] of bicycles"

SLIDER
201
151
373
184
grid-size-x
grid-size-x
0
150
66.0
1
1
NIL
HORIZONTAL

SLIDER
203
192
375
225
grid-size-y
grid-size-y
0
150
66.0
1
1
NIL
HORIZONTAL

MONITOR
378
248
496
293
NIL
count intersections
17
1
11

MONITOR
389
184
468
229
NIL
count roads
17
1
11

SLIDER
386
148
558
181
Drop
Drop
0
65
10.0
1
1
NIL
HORIZONTAL

SLIDER
10
143
182
176
Stray
Stray
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
10
568
182
601
CareAttitude
CareAttitude
0
1
0.5
.01
1
NIL
HORIZONTAL

MONITOR
422
509
528
562
Mean V
mean [ newassociationstrength ] of cars
2
1
13

PLOT
199
490
418
640
Mean V
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" "if ticks = Origdest [ clear-plot ]"
PENS
"Mean V" 1.0 0 -16777216 true "" "plot mean [ newassociationstrength ] of cars * 10"
"Aware" 1.0 0 -7500403 true "" "plot count cars with [ color = red ] / count cars * 10"

MONITOR
422
563
496
616
Aware %
count cars with [ color = red ] / ( count cars ) * 100
1
1
13

SLIDER
10
525
182
558
BicycleSaliency
BicycleSaliency
0
1
0.8
.01
1
NIL
HORIZONTAL

SLIDER
10
263
182
296
Maxv
Maxv
0
1
1.0
.01
1
NIL
HORIZONTAL

SLIDER
10
301
182
334
Minv
Minv
0
1
0.0
.01
1
NIL
HORIZONTAL

SLIDER
429
625
601
658
Memoryspan
Memoryspan
0
50
15.0
1
1
NIL
HORIZONTAL

SLIDER
10
479
182
512
RoadSaliency
RoadSaliency
0
1
0.8
.01
1
NIL
HORIZONTAL

SLIDER
211
309
354
343
InitialV
InitialV
0
.8
0.0
.1
1
NIL
HORIZONTAL

SWITCH
577
111
700
145
Shade
Shade
1
1
-1000

SWITCH
544
210
659
244
More_bikes
More_bikes
0
1
-1000

SLIDER
10
607
182
640
Capacity
Capacity
0
1
1.0
.01
1
NIL
HORIZONTAL

SWITCH
11
657
114
690
Track
Track
1
1
-1000

SLIDER
148
661
320
694
Network
Network
0
12936
123.0
100
1
NIL
HORIZONTAL

SLIDER
11
702
193
735
Infrastructure_Build
Infrastructure_Build
0
100
0.0
1
1
NIL
HORIZONTAL

INPUTBOX
650
697
805
757
Additional_Bikes
1.0
1
0
Number

MONITOR
817
698
922
751
Road Network
count patches with [ pcolor = green ] / 12936
2
1
13

SLIDER
428
664
600
697
Origdest
Origdest
0
200
0.0
1
1
NIL
HORIZONTAL

SLIDER
428
703
600
736
Pathbuilders
Pathbuilders
0
500
0.0
1
1
NIL
HORIZONTAL

SLIDER
428
742
608
775
Points_of_Interest
Points_of_Interest
1
500
5.0
1
1
NIL
HORIZONTAL

MONITOR
538
510
615
563
SafeBikes
count bicycles with [ color = blue ]
0
1
13

SWITCH
202
703
363
736
Growinfrastructure
Growinfrastructure
1
1
-1000

SLIDER
509
571
681
604
Network2
Network2
0
1
0.0
.01
1
NIL
HORIZONTAL

SLIDER
368
310
493
344
Friendshipradius
Friendshipradius
0
20
0.0
1
1
NIL
HORIZONTAL

MONITOR
616
629
666
674
Mates
mean [ mates ] of cars
1
1
11

MONITOR
937
702
1026
747
Care Attitude
mean [ care_attitude ] of cars
5
1
11

SWITCH
545
298
659
332
Less_Cars
Less_Cars
1
1
-1000

SWITCH
545
252
658
286
More_Cars
More_Cars
1
1
-1000

MONITOR
348
425
406
470
Vehicles
count bicycles + count cars
17
1
11

SLIDER
15
747
188
781
Local_Density
Local_Density
1
2
1.5
.01
1
NIL
HORIZONTAL

SLIDER
203
747
376
781
DensityTrigger
DensityTrigger
0
100
11.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ambulance
false
0
Rectangle -7500403 true true 30 90 210 195
Polygon -7500403 true true 296 190 296 150 259 134 244 104 210 105 210 190
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Circle -16777216 true false 69 174 42
Rectangle -1 true false 288 158 297 173
Rectangle -1184463 true false 289 180 298 172
Rectangle -2674135 true false 29 151 298 158
Line -16777216 false 210 90 210 195
Rectangle -16777216 true false 83 116 128 133
Rectangle -16777216 true false 153 111 176 134
Line -7500403 true 165 105 165 135
Rectangle -7500403 true true 14 186 33 195
Line -13345367 false 45 135 75 120
Line -13345367 false 75 135 45 120
Line -13345367 false 60 112 60 142

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bike
false
1
Line -7500403 false 163 183 228 184
Circle -7500403 false false 213 184 22
Circle -7500403 false false 156 187 16
Circle -16777216 false false 28 148 95
Circle -16777216 false false 24 144 102
Circle -16777216 false false 174 144 102
Circle -16777216 false false 177 148 95
Polygon -2674135 true true 75 195 90 90 98 92 97 107 192 122 207 83 215 85 202 123 211 133 225 195 165 195 164 188 214 188 202 133 94 116 82 195
Polygon -2674135 true true 208 83 164 193 171 196 217 85
Polygon -2674135 true true 165 188 91 120 90 131 164 196
Line -7500403 false 159 173 170 219
Line -7500403 false 155 172 166 172
Line -7500403 false 166 219 177 219
Polygon -16777216 true false 187 92 198 92 208 97 217 100 231 93 231 84 216 82 201 83 184 85
Polygon -7500403 true true 71 86 98 93 101 85 74 81
Rectangle -16777216 true false 75 75 75 90
Polygon -16777216 true false 70 87 70 72 78 71 78 89
Circle -7500403 false false 153 184 22
Line -7500403 false 159 206 228 205

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

train passenger car
false
0
Polygon -7500403 true true 15 206 15 150 15 135 30 120 270 120 285 135 285 150 285 206 270 210 30 210
Circle -16777216 true false 240 195 30
Circle -16777216 true false 210 195 30
Circle -16777216 true false 60 195 30
Circle -16777216 true false 30 195 30
Rectangle -16777216 true false 30 140 268 165
Line -7500403 true 60 135 60 165
Line -7500403 true 60 135 60 165
Line -7500403 true 90 135 90 165
Line -7500403 true 120 135 120 165
Line -7500403 true 150 135 150 165
Line -7500403 true 180 135 180 165
Line -7500403 true 210 135 210 165
Line -7500403 true 240 135 240 165
Rectangle -16777216 true false 5 195 19 207
Rectangle -16777216 true false 281 195 295 207
Rectangle -13345367 true false 15 165 285 173
Rectangle -2674135 true false 15 180 285 188

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="With roads experiment" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count bicycles</metric>
    <metric>count cars with [ collisionsbikes = 1 ]</metric>
    <metric>mean [ VRUdensity ] of bicycles</metric>
    <enumeratedValueSet variable="car-on-pedestrian">
      <value value="-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial_cars">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Speed_Cars">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-on-car">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-from-roads">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial_bicycles">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Density">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Speed_Bikes">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="citydensity">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersion">
      <value value="130"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drop">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stray">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count cars</metric>
    <metric>count bicycles</metric>
    <metric>Mean [ newassociationstrength ] of cars</metric>
    <metric>count cars with [ color = red ] / ( count cars )</metric>
    <metric>mean [ VRUDensity ] of bicycles</metric>
    <metric>count bicycles with [ crashed = 1 ]</metric>
    <metric>count cars with [ collisionsbikes = 1 ]</metric>
    <enumeratedValueSet variable="More">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="straycars">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-on-car">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grid-size-x">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Shade">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stray">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maxv">
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
      <value value="0.8"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial_bicycles">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial_cars">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-on-pedestrian">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RoadSaliency">
      <value value="0"/>
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Capacity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialV">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Speed_Cars">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BicycleSaliency">
      <value value="0"/>
      <value value="0.2"/>
      <value value="0.4"/>
      <value value="0.6"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grid-size-y">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersion">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Drop">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CareAttitude">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Memoryspan">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Speed_Bikes">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-from-roads">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Friends Network" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count cars</metric>
    <metric>count bicycles</metric>
    <metric>Mean [ newassociationstrength ] of cars</metric>
    <metric>count cars with [ color = red ] / ( count cars )</metric>
    <metric>mean [ VRUDensity ] of bicycles</metric>
    <metric>count bicycles with [ crashed = 1 ]</metric>
    <metric>count cars with [ collisionsbikes = 1 ]</metric>
    <metric>count bicycles with [ color = blue ]</metric>
    <metric>count patches with [ pcolor = green ]</metric>
    <metric>mean [ mates ] of cars</metric>
    <enumeratedValueSet variable="More">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="straycars">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-on-car">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grid-size-x">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Shade">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stray">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial_bicycles">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial_cars">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-on-pedestrian">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RoadSaliency">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Capacity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialV">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Speed_Cars">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BicycleSaliency">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grid-size-y">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Drop">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CareAttitude">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Memoryspan">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Speed_Bikes">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-from-roads">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Network2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Points_of_Interest">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OrigDest">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Pathbuilders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friendshipradius">
      <value value="0"/>
      <value value="3"/>
      <value value="6"/>
      <value value="9"/>
      <value value="12"/>
      <value value="15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Segregation Exp with paths" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count cars</metric>
    <metric>count bicycles</metric>
    <metric>Mean [ newassociationstrength ] of cars</metric>
    <metric>count cars with [ color = red ] / ( count cars )</metric>
    <metric>mean [ VRUDensity ] of bicycles</metric>
    <metric>count bicycles with [ crashed = 1 ]</metric>
    <metric>count cars with [ collisionsbikes = 1 ]</metric>
    <metric>count bicycles with [ color = blue ]</metric>
    <enumeratedValueSet variable="More">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="straycars">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-on-car">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grid-size-x">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Shade">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stray">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial_bicycles">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial_cars">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-on-pedestrian">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RoadSaliency">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Capacity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialV">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Speed_Cars">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BicycleSaliency">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grid-size-y">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Drop">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CareAttitude">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Memoryspan">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Speed_Bikes">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-from-roads">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Network">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Points_of_Interest">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Pathbuilders">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OrigDest">
      <value value="0"/>
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-on-pedestrian">
      <value value="0"/>
      <value value="-0.5"/>
      <value value="-1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Segregation experiment March 16" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count cars</metric>
    <metric>count bicycles</metric>
    <metric>Mean [ newassociationstrength ] of cars</metric>
    <metric>count cars with [ color = red ] / ( count cars )</metric>
    <metric>mean [ VRUDensity ] of bicycles</metric>
    <metric>count bicycles with [ crashed = 1 ]</metric>
    <metric>count cars with [ collisionsbikes = 1 ]</metric>
    <metric>count bicycles with [ color = blue ]</metric>
    <enumeratedValueSet variable="Additional_Bikes">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Shade">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Infrastructure_Build">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial_bicycles">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grid-size-y">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Pathbuilders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Network">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-on-pedestrian">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-on-car">
      <value value="-3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grid-size-x">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Minv">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BicycleSaliency">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial_cars">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Capacity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Growinfrastructure">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Origdest">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialV">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Speed_Cars">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Memoryspan">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Track">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-from-roads">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stray">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RoadSaliency">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="More">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Speed_Bikes">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Maxv">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Drop">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="straycars">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CareAttitude">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Points_of_Interest">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
