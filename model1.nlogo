globals
[
  grid-x               ;; the amount of fields of different crops horizontally
  grid-y               ;; the amount of fields of different crops vertically
  grid-h               ;; the amount of plots in each field vertically
  grid-l               ;; the amount of plots in each field horizontally
  alpha

  px ;; plot length
  py ;; plot height
  mx ;; field length
  my ;; field height
  counter_id
  reference ;; patch in road to be a reference to goal
  ticksperday

  ;; patch agentsets
  marketplaces  ;; agentset containing the patches that are marketplaces
  roads         ;; agentset containing the patches that are roads
  days

  ncrops
  crops_color

  counter_preferences
  counter_marketplaces
  total_trades
  total_contact
  total_rounds

]
turtles-own
[
  direction
  partner
  active?
  socialization
  id
  my-plot
  my-plot-reference
  goal
  marketplace-time
  atmarketplace
  crops_quantity
  preferences
  best_marketplace
  next_marketplace
  nround
  satisfied?

]

patches-own
[
  marketplace?
  road?
  my-crop
  main-crop
  alive-time
  my-turtle
  collectable
  dead-bound
  my-field
]

to setup
  clear-all

  setup-globals
  setup-patches

  create-turtles (grid-l * grid-x) * (grid-h * grid-y)
  [
    setup-agents
  ]

  assign_patches

  ask turtles [
    move-to one-of my-plot
    collect
    set next_marketplace my-field
  ]

  reset-ticks
end

to go
  if (ticks > 0 and ticks mod ticksperday = 0)
  [
    stop
    if count turtles = 0 [
      stop
    ]
    set days days + 1
    ask turtles [
      balance
    ]

  ]
  go-turtles
  go-patches

tick
end

to go-turtles
  ask turtles
  [
    if partner = nobody and active? = true
    [
      set partner one-of turtles in-radius marketplace-size with
        [partner = nobody and active? = true and who != [who] of myself] ;; and who != [who] of lastpartner
    ]

    if partner != nobody
    [

      ask partner [
        set partner myself
      ]

      interact

      ask partner [
        set partner nobody
      ]
      set partner nobody
    ]
    ifelse (counttypes >= 3)[ ;; can go home
      set satisfied? true
      set goal "home"
    ]
    [
      set satisfied? false
    ]
    move
  ]

end

to go-patches
  ask patches with [not member? self roads and not member? self marketplaces] [
    ifelse (alive-time >= dead-bound) [
      set alive-time 0
      ifelse random 100 > prevalence [ ;; my crop with prevalence%
        set my-crop random ncrops
      ]
      [
        set my-crop main-crop
      ]
    ]
    [
      set alive-time (alive-time + 1)
    ]

    set pcolor item my-crop crops_color
  ]
end

to setup-globals
  set grid-x nfields-x
  set grid-y nfields-y
  set grid-h plotsperfield-y
  set grid-l plotsperfield-x
  set alpha marketplace-size
  set counter_id 0
  set ticksperday ticks/day
  set days 0
  set counter_marketplaces 0
  set counter_preferences 0
  set total_trades 0
  set total_contact 0
  set total_rounds 0
  set ncrops typesofcrops
  set crops_color [133 123 113 102 97 35 135 131 24 46 1 52 16]


end

to setup-patches
  ask patches
  [
    set marketplace? false
    set road? false
    set road? false
    set pcolor green
    set collectable (50 + random 100)
    set dead-bound collectable + (50 + random 100)
    set alive-time random dead-bound
  ]

  set px (world-width / (grid-l * grid-x))
  set py (world-height / (grid-h * grid-y))
  set mx (world-width / grid-x)
  set my (world-height / grid-y)

  set roads patches with
  [((floor(pxcor mod (px))) = 0 ) or
    ((floor(pycor mod (py))) = 0 )]

  set marketplaces patches with
  [((floor(pxcor mod mx -(1 / 2) * mx)) <= (alpha / 2) and floor(pxcor mod mx -(1 / 2) * mx) >= (- alpha / 2)) and
    (floor(pycor mod my -(1 / 2)* my)) <= (alpha / 2) and floor(pycor mod my -(1 / 2)* my) >= (- alpha / 2)]

  ask roads [set pcolor red]
  ask marketplaces [set pcolor blue]

  set reference one-of roads

end

to setup-agents ;; turtle procedure
  set id counter_id
  set counter_id counter_id + 1
  set active? true
  set socialization 0
  set partner nobody
  set goal "leave plot"
  set atmarketplace 0
  set crops_quantity n-values ncrops [0]
  set preferences n-values (grid-x * grid-y) [[]]
  set satisfied? false

  let index 0
  foreach preferences  [
    set preferences replace-item index preferences (n-values ncrops [0])
    set index (index + 1)
  ]

  set nround 0

end

to interact

  trade

 ;; ifelse random 2 = 0
 ;; [
 ;;   talk
 ;; ]
 ;; [
 ;;   trade
 ;; ]

end

to talk
  set socialization socialization + 10
  ;;  set [socialization] of partner [socialization] of partner + 10
  ask partner [
    set socialization socialization + 10
  ]

end

to trade
  set total_contact total_contact + 1
  set socialization socialization + 2
  ask partner [
    set socialization socialization + 2
  ]

  let temp 0
  let i -1
  (foreach crops_quantity ([crops_quantity] of partner) [
    [x y] -> if (y = 0 and x > 1) or (x = 0 and y > 1) ;; we should trade
    [
      set i temp
    ]
    set temp temp + 1
  ])

  if i != -1 [
    set total_trades total_trades + 1
    set marketplace-time marketplace-time + 10
    let quantity item i crops_quantity

    ifelse (quantity > 0)[ ;; i'm the one selling
      ;; reduce quantity from my crop
      set crops_quantity replace-item i crops_quantity (quantity - 1)

      ;; add to other's crop
      ask partner[
        set crops_quantity replace-item i crops_quantity 1
        ;; add to other's preference

        let newprefofmarketplace replace-item i (item next_marketplace preferences) (item i (item next_marketplace preferences) + 1)
        if (item i (item next_marketplace preferences) = 10) [
           set newprefofmarketplace replace-item i (item next_marketplace preferences) 20
        ]

        set preferences replace-item next_marketplace preferences newprefofmarketplace
      ]



    ]
    [
      set quantity item i [crops_quantity] of partner
      ;; add one to my crop i
      set crops_quantity replace-item i crops_quantity 1

      ;; add to my preference
      let newprefofmarketplace replace-item i (item next_marketplace preferences) (item i (item next_marketplace preferences) + 1)
      if (item i (item next_marketplace preferences) = 10) [
        set newprefofmarketplace replace-item i (item next_marketplace preferences) 20
      ]

      set preferences replace-item next_marketplace preferences newprefofmarketplace

      ;; reduce quantity from other's crop
      ask partner[
        set crops_quantity replace-item i crops_quantity (quantity - 1)
      ]
    ]
  ]

end

to assign_patches
  let x 0
  let y 0
  let tid 0
  let cid random ncrops

  ask patches with [member? self roads or member? self marketplaces]
  [
    set my-turtle -1
    set my-crop -1
    set main-crop -1
  ]

  ask patches [
    set my-field (2 * (floor (pycor / my)) + (floor (pxcor / mx)))
  ]

  foreach [who] of turtles
  [
    ask patches with [not member? self roads
      and not member? self marketplaces
      and pxcor > x and pxcor < x + px and pycor > y and pycor < y + py]
    [
      set my-turtle tid
      ifelse perfield
      [
        set main-crop ((2 * (floor (pycor / my)) + (floor (pxcor / mx))) mod ncrops)
      ]
      [
        set main-crop cid
      ]
      ifelse random 100 > prevalence [ ;; my crop with 90%
        set my-crop random ncrops
      ]
      [
        set my-crop main-crop
      ]
      set pcolor item my-crop crops_color
    ]

    ask turtles with [id = tid]
    [
      set my-plot patches with [not member? self roads
      and not member? self marketplaces
      and pxcor > x and pxcor < x + px and pycor > y and pycor < y + py]
      set my-plot-reference min-one-of my-plot [distance patch 0 0]
    ]

    set tid tid + 1
    set cid random ncrops

    ifelse x + px < world-width
    [
      set x x + px
    ]
    [
      set x 0
      set y y + py
    ]

  ]

end

to-report counttypes
  let types 0
  foreach crops_quantity [ x -> if x != 0 [set types types + 1] ]
  report types
end

to consume-crop ;;eats everything
  set crops_quantity n-values ncrops [0]
end

to balance
;;  set partner nobody
;;  set lastpartner self
;;  set goal "leave plot"

  ;; check whether agent has two different types of crop

  ;; TODO have this magic number as global
  if (counttypes < 2)[
    die
  ]
end

to collect
  let collected n-values ncrops [0]
  ;;replace-item index list value
  ;;item i crops_quantity

  ask my-plot [
    if alive-time >= collectable and alive-time < dead-bound
    [
      set collected replace-item my-crop collected (item my-crop collected + 1)
      set alive-time dead-bound
    ]
  ]

  let index 0
  (foreach crops_quantity collected [ [old new] ->
    set crops_quantity replace-item index crops_quantity (old + new)
    set index index + 1
  ])
end

to-report preference ;; finds preferable marketplace
  set counter_marketplaces counter_marketplaces + 1
  let index 0
  let j 0

  foreach crops_quantity [ [crop] ->
    if crop = 0 [
      foreach preferences [ [marketplace] ->
        if item index (item j preferences) >= 10 [
          set counter_preferences counter_preferences + 1
          report j
        ]
        set j j + 1
      ]
      set j 0
    ]
    set index index + 1
  ]

  report -1

end

to move
  ifelse goal = "nothing" [
  ]
  [
    let thisturtle [id] of self
    let objectthisturtle self
    set active? false

    ;; wants to go home
    if goal = "home" [
      ifelse (member? patch-here my-plot) [ ;; is home already
        consume-crop
        collect
        set next_marketplace preference
        if (next_marketplace = -1)[
          set next_marketplace [my-field] of patch-here
        ]

        set goal "leave plot"
        set nround nround + 1
        set total_rounds total_rounds + 1
      ]
      [

        ifelse (any? neighbors with [my-turtle = [id] of myself]) [ ;; is near home
          move-to min-one-of neighbors with [my-turtle = [id] of objectthisturtle] [distance myself]
          face one-of neighbors with [my-turtle = [id] of myself]
        ]
        [
          if (member? patch-here marketplaces and not member? patch-here roads)[ ;; is at a marketplace

            move-to min-one-of roads [distance myself] ;; go to road
            set atmarketplace 0
          ]

          if (member? patch-here roads) [ ;; is on a road
            let choices neighbors with [member? self roads]
            face min-one-of choices [distance [my-plot-reference] of myself]
          ]
        ]
      ]
    ]

    ;; wants to leave home
    if goal = "leave plot" [
      move-to min-one-of roads [distance  myself]
      set goal "marketplace"
      face min-one-of neighbors with [member? self roads] [distance one-of marketplaces with [member? self roads and my-field = [next_marketplace] of objectthisturtle]]
    ]


    if goal = "marketplace"[ ;; wants to go to a marketplace
      ifelse (member? patch-here marketplaces and [my-field] of patch-here = next_marketplace)[

        set atmarketplace 0
        set goal "socialize"
      ]
      [
        ifelse ((one-of neighbors with [pcolor = blue and my-field = [next_marketplace] of objectthisturtle]) != NOBODY)[ ;;is near the target marketplace
          move-to one-of neighbors with [pcolor = blue and my-field = [next_marketplace] of objectthisturtle]

          set atmarketplace 0
          set goal "socialize"
          face min-one-of neighbors with [member? self marketplaces] [distance myself]
        ]
        [

          let choices neighbors with [member? self roads]
          if count choices = 0 [
            move-to min-one-of (roads) [distance myself] ;; go to road
            set choices neighbors

          ]

          face min-one-of choices [distance one-of roads with [pcolor = blue and my-field = ([next_marketplace] of objectthisturtle)]]
        ]
      ]
    ]

    if goal = "socialize" and (not member? patch-here my-plot)[
      ifelse member? patch-here marketplaces
      [ ;; in marketplace
        set active? true
        if atmarketplace = 0 [ ;; just arrived and must stay
          set atmarketplace 1
          set marketplace-time 10
        ]
        ifelse marketplace-time > 0 [

          set marketplace-time marketplace-time - 1
          let choices neighbors with [pcolor = blue]
          ifelse (count choices = 0)[
            bk 1
          ]
          [
            face one-of choices
          ]
        ]
        [ ;; should leave and find a road

          ;;reduce preferences
          let i 0

          foreach crops_quantity [ crop ->
            if crop = 0 [
              let newprefofmarketplace item next_marketplace preferences

              if item i (item next_marketplace preferences) > 0
              [
                set newprefofmarketplace replace-item i (item next_marketplace preferences) (item i (item next_marketplace preferences) - 1)
              ]

              if item i (item next_marketplace preferences) <= 10
              [
                set newprefofmarketplace replace-item i (item next_marketplace preferences) 0
              ]

              set preferences replace-item next_marketplace preferences newprefofmarketplace
            ]
            set i (i + 1)
          ]

          move-to min-one-of (roads with [pcolor = red]) [distance min-one-of (roads with [pcolor = red]) [distance myself]] ;; go to road
          let choices neighbors with [pcolor = red]

          face min-one-of choices [distance myself]
          set atmarketplace 0

          let p preference

          ifelse p = -1
          [
            set next_marketplace ((next_marketplace + 1) mod (grid-x * grid-y))
          ]
          [
            set next_marketplace p
          ]

          set goal "marketplace"
        ]

      ]
      [
        if (floor(pxcor mod (px)) = 0 ) and (floor(pycor mod (py)) = 0 )[
          set heading (heading + one-of [0 90 270] mod 360)
        ]
      ]
    ]


    fd 1

  ]


end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
608
409
-1
-1
6.0
1
10
1
1
1
0
1
1
1
0
64
0
64
1
1
1
ticks
30.0

BUTTON
120
55
192
88
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
120
90
183
123
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
1

SLIDER
15
150
187
183
nfields-x
nfields-x
1
4
2.0
1
1
NIL
HORIZONTAL

SLIDER
15
200
187
233
nfields-y
nfields-y
1
4
3.0
1
1
NIL
HORIZONTAL

SLIDER
15
250
185
283
marketplace-size
marketplace-size
0
8
2.0
2
1
NIL
HORIZONTAL

SLIDER
15
295
107
328
plotsperfield-x
plotsperfield-x
2
4
4.0
2
1
NIL
HORIZONTAL

SLIDER
15
345
107
378
plotsperfield-y
plotsperfield-y
2
4
2.0
2
1
NIL
HORIZONTAL

PLOT
620
10
780
160
Turtles alive
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"
"preferences" 1.0 0 -7500403 true "" "plot counter_preferences"
"pen-2" 1.0 0 -2674135 true "" "plot counter_marketplaces"

INPUTBOX
20
65
80
125
ticks/day
20000.0
1
0
Number

SLIDER
20
10
192
43
typesofcrops
typesofcrops
1
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
15
390
187
423
prevalence
prevalence
1
100
100.0
1
1
NIL
HORIZONTAL

SWITCH
645
340
748
373
perfield
perfield
0
1
-1000

PLOT
620
170
820
320
choosing marketplace by preference
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"turtles" 1.0 0 -16777216 true "" "plot count turtles"
"rounds" 1.0 0 -2674135 true "" "plot total_rounds / count turtles"
"trades" 1.0 0 -955883 true "" "plot total_trades / count turtles"
"pen-5" 1.0 0 -1184463 true "" "plot count turtles with [satisfied? = true]"

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

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

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
1
@#$#@#$#@
