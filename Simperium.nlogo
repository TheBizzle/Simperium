globals [attacker defender game-state after-first-invasion-round?]

breed [players player]
breed [units unit]
breed [death-markers death-marker]
breed [damage-markers damage-marker]

players-own [
  defeated?
  influence-bundles
  my-faction
  my-local-pds
  my-units
  startup-cost
  trade-goods
]

units-own [
  damaged?
  destroyed?
  hit-count
  my-player
  unit-type
  upgraded?
]

to setup

  clear-all

  let h1 90
  let h2 270

  let c1 red
  let c2 blue

  set game-state                  "initial"
  set after-first-invasion-round? false

  create-players 1 [

    set my-faction        attacking-faction
    set influence-bundles (read-from-string initial-influence-bundles-1)
    set trade-goods       initial-trade-goods-1

    mk-flagships    flagships-1    upgraded-flagship-1?    h1 c1
    mk-warsuns      warsuns-1      false                   h1 c1
    mk-dreadnoughts dreadnoughts-1 upgraded-dreadnought-1? h1 c1
    mk-carriers     carriers-1     upgraded-carrier-1?     h1 c1
    mk-cruisers     cruisers-1     upgraded-cruiser-1?     h1 c1
    mk-destroyers   destroyers-1   upgraded-destroyer-1?   h1 c1
    mk-fighters     fighters-1     upgraded-fighter-1?     h1 c1
    mk-infantry     infantry-1     upgraded-infantry-1?    h1 c1
    mk-pds          pds-1          upgraded-pds-1?         h1 c1

    set my-units (units with [true])

    set attacker self

    layout true

    set defeated?    false
    set startup-cost total-value

    set hidden? true

  ]

  create-players 1 [

    let w ifelse-value ((count units) > 0) [ (max [who] of units) ] [ -1 ]

    set my-faction        defending-faction
    set influence-bundles (read-from-string initial-influence-bundles-2)
    set trade-goods       initial-trade-goods-2

    mk-flagships    flagships-2    upgraded-flagship-2?    h2 c2
    mk-warsuns      warsuns-2      false                   h2 c2
    mk-dreadnoughts dreadnoughts-2 upgraded-dreadnought-2? h2 c2
    mk-carriers     carriers-2     upgraded-carrier-2?     h2 c2
    mk-cruisers     cruisers-2     upgraded-cruiser-2?     h2 c2
    mk-destroyers   destroyers-2   upgraded-destroyer-2?   h2 c2
    mk-fighters     fighters-2     upgraded-fighter-2?     h2 c2
    mk-infantry     infantry-2     upgraded-infantry-2?    h2 c2
    mk-pds          pds-2          upgraded-pds-2?         h2 c2

    set my-local-pds (units with [who > w and unit-type = "pds"])

    if (upgraded-pds-2?) [
      mk-pds adjacent-pds upgraded-pds-2? h2 c2
    ]

    set my-units (units with [who > w])

    set defender self

    layout false

    set defeated?    false
    set startup-cost total-value

    set hidden? true

  ]

  set game-state "pre-combat"

  reset-ticks

end

to go
  ifelse (([defeated?] of attacker) or ([defeated?] of defender)) [
    cleanup
    set game-state "complete"
    stop
  ] [
    combat
    tick
  ]
end

to layout [attacker?]

  let last-type (turtle-set)

  let types (list my-flagships my-warsuns my-dreadnoughts my-cruisers my-destroyers my-carriers my-fighters my-infantry my-pds)

  foreach types [
    ships ->
      if any? ships [
        layout-type ships last-type attacker?
        set last-type ships
      ]
  ]

end

to layout-type [ the-units last-type attacker? ]

  let top-y (max-pycor - 2)

  let x (nice-layout-x last-type attacker?)
  let y top-y

  foreach (sort-on [who] the-units) [ u ->
    ask u [

      setxy x y

      let down-y (y - size - 1)

      ifelse down-y >= 1 [
        set y down-y
      ] [
        set x (x + ((size + 1) * (ifelse-value attacker? [-1] [1])))
        set y top-y
      ]

    ]
  ]

end

to-report nice-layout-x [ the-units attacker? ]

  let side-coefficient (ifelse-value attacker? [-1] [1])

  ifelse any? the-units [
    let closest-x (ifelse-value attacker? [ min [xcor] of the-units ] [ max [xcor] of the-units ])
    report closest-x + (((one-of [size] of the-units) + 2) * side-coefficient)
  ] [
    report (max-pxcor / 2) + (side-coefficient * 3)
  ]

end

to combat

  ; NOT IMPLEMENTED: Yin "Indoctrination" ability and "Devotion" ability and "Impulse Core" yellow tech and their "Van Hauge" flagship

  ; Turn order, from FFG: https://www.reddit.com/r/twilightimperium/comments/7w7v6r/ti4_rules_question_does_antifighter_barrage/

  if ticks = 0 [
    do-space-cannon-offense
  ]

  if ticks = 1 [
    do-anti-fighter-barrage
  ]

  if ticks >= 2 [
    ifelse ((any? [my-ships] of attacker) and (any? [my-ships] of defender)) [
      do-space-combat
    ] [
      do-invasion
    ]
  ]

end

to do-space-cannon-offense

  set game-state "Tactical Action @2.2: Space Cannon Offense"

  output-print "BEGIN SCO"

  output-print "BEGIN SCO ROLLS"

  let amd1? antimass-deflectors-1?
  let amd2? antimass-deflectors-2?

  let ps1? plasma-scoring-1?
  let ps2? plasma-scoring-2?

  ; Argent flagship "Quetzecoatl" ==> Other players cannot use SPACE CANNON against your ships in this system
  let attacker-hits (ifelse-value (not [my-faction = "argent" and any? my-flagships] of defender) [ [space-cannon-hits amd2? ps1?] of attacker ] [ [] ])
  let defender-hits (ifelse-value (not [my-faction = "argent" and any? my-flagships] of attacker) [ [space-cannon-hits amd1? ps2?] of defender ] [ [] ])

  output-print "END SCO ROLLS"

  output-print "BEGIN SCO HITS"

  let gls1? graviton-lasers-1?
  let gls2? graviton-lasers-2?

  foreach (list (list attacker-hits defender gls1?) (list defender-hits attacker gls2?)) [
    hits-opponent-gls?-triple ->
      ; let [hits opponent gls?] hits-opponent-gls?-triple
      let hits     (item 0 hits-opponent-gls?-triple)
      let opponent (item 1 hits-opponent-gls?-triple)
      let gls?     (item 2 hits-opponent-gls?-triple)
      foreach hits [
        hitter ->
          ask opponent [
            if (any? my-ships) [
              ; Graviton Laser System (yellow tech) ==> You may exhaust this card before 1 or more of your units uses Space Cannon; hits produced by those units must be assigned to non-fighter ships if able
              let targets (ifelse-value (any? my-fleet and gls?) [my-fleet] [my-ships])
              hit hitter (optimal-soaker targets)
            ]
          ]
      ]
  ]

  output-print "END SCO HITS"

  output-print "END SCO"

end

to-report space-cannon-hits [opponent-antimass-deflectors? plasma-scoring?]

  let my-hits []

  let base-triples     my-space-cannon-triples
  let modified-triples (ifelse-value plasma-scoring? [ plasma-scoring-triples base-triples ] [ base-triples ])

  ; Antimass Deflectors (blue tech) ==> When other players’ units use SPACE CANNON against your units, apply -1 to the result of each die roll
  let amd (ifelse-value opponent-antimass-deflectors? [-1] [0])

  foreach modified-triples [
    triple ->
      ;let [cannoneer goal tries] triple
      let cannoneer (item 0 triple)
      let goal      (item 1 triple)
      let tries     (item 2 triple)
      foreach (range tries) [
        let modifiers amd
        if ((non-combat-roll + modifiers) >= goal) [
          set my-hits (fput cannoneer my-hits)
        ]
      ]
  ]

  report my-hits

end

; Plasma Scoring (red tech) ==> When 1 or more of your units use Bombardment or Space Cannon, 1 of those units may roll 1 additional die
to-report plasma-scoring-triples [triples]
  ifelse (not empty? triples) [

    let best-index 0

    foreach (range length triples) [
      index ->
        ;let [junk1 c1 junk2] (item index      triples)
        ;let [junk3 c2 junk4] (item best-index triples)
        let c1 (item 1 (item index      triples))
        let c2 (item 1 (item best-index triples))
        if (c1 < c2) [
          set best-index index
        ]
    ]

    let bestie  (item best-index triples)
    ;let [s c t] bestie
    let s       (item 0 bestie)
    let c       (item 1 bestie)
    let t       (item 2 bestie)

    report (replace-item best-index triples (list s c (t + 1)))

  ] [
    report []
  ]
end

to do-anti-fighter-barrage

  set game-state "Tactical Action @3.1: Anti-Fighter Barrage"

  output-print "BEGIN PRE-SPACE COMBAT"

  activate-assault-cannon assault-cannon-1? attacker defender
  activate-assault-cannon assault-cannon-2? defender attacker

  activate-dimensional-splicer dimensional-splicer-1? attacker defender
  activate-dimensional-splicer dimensional-splicer-2? defender attacker

  activate-ambush attacker defender
  activate-ambush defender attacker

  output-print "END PRE-SPACE COMBAT"

  output-print "BEGIN AFB"

  let attacker-hit-pairs ([afb-hit-num-pairs] of attacker)
  let defender-hit-pairs ([afb-hit-num-pairs] of defender)


  foreach (list (list attacker-hit-pairs attacker defender) (list defender-hit-pairs defender attacker)) [
    hitpairs-actor-actee-triple ->

      ;let [hitpairs actor actee] hits-actor-actee-triple
      let hit-pairs (item 0 hitpairs-actor-actee-triple)
      let actor     (item 1 hitpairs-actor-actee-triple)
      let actee     (item 2 hitpairs-actor-actee-triple)

      foreach hit-pairs [
        hit-pair ->

          let hitter      (item 0 hit-pair)
          let roll-result (item 1 hit-pair)

          ; Argent upgraded Destroyers ==> When this unit uses ANTI-FIGHTER BARRAGE, each result of 9 or 10 also destroys 1 of your opponent's infantry in the space area of the active system
          if ((([my-faction] of actor) = "argent") and
              ((roll-result = 9) or (roll-result = 10)) and
              ([(unit-type = "destroyer") and upgraded?] of hitter) and
              ((actor = defender) or (([my-faction] of actee) = "nekro"))) [ ; Gotta take Nekro space-infantry into account

            let options ([my-infantry] of actee)

            ifelse (any? options) [
              let soaker (one-of options)
              hit hitter soaker
            ] [
              ask hitter [ output-print (word (ifelse-value (actor = attacker) [ "ATTACKER" ] [ "DEFENDER" ]) " (" unit-type " " who ")'S FREE INFANTRY KILL HAS NO TARGET") ]
            ]

          ]

          let options ([my-fighters] of actee)

          ifelse (any? options) [
            let soaker (one-of options)
            hit hitter soaker
          ] [
            ; Argent ability "Raid Formation" ==> When 1 or more of your units uses ANTI-FIGHTER BARRAGE, for each hit produced in excess of your opponent's Fighters, choose 1 of your opponent's ships that has SUSTAIN DAMAGE to become damaged
            let prey (([my-ships with [hp > 1]]) of actee)
            ifelse ((([my-faction] of actor) = "argent") and (any? prey)) [
              let soaker (one-of prey with-max [cost])
              hit hitter soaker ; Technically, not a hit, but probably should use the same code
            ] [
              ask hitter [ output-print (word (ifelse-value (actor = attacker) [ "ATTACKER" ] [ "DEFENDER" ]) " (" unit-type " " who ")'S HIT HAS NO TARGET") ]
            ]
          ]

      ]

  ]

  output-print "END AFB"

end

; Assault Cannon (red tech) ==> At the start of a space combat in a system that contains 3 or more of your non-fighter ships, your opponent must destroy 1 of their non-fighter ships
to activate-assault-cannon [ac? actor actee]
  if (ac? and (count [my-fleet] of actor) >= 3) [
    ask ([optimal-throwaway my-fleet] of actee) [ go-bye-bye "Assault Cannon tech" ]
  ]
end

; Creuss "Dimensional Splicer" (red tech) ==> At the start of space combat in a system that contains a wormhole and 1 or more of your ships, you may produce 1 hit and assign it to 1 of your opponent's ships.
to activate-dimensional-splicer [ds? actor actee]
  if (ds? and system-has-wormhole? and [my-faction = "creuss"] of actor) [
    spooky-hit actor (optimal-target ([my-ships] of actee) actor) "Dimensional Splicer"
  ]
end

; Mentak "Ambush" ability ==> At the start of a space combat, you may roll 1 die for each of up to 2 of your cruisers or destroyers in the system.
;                             For each result equal to or greater than that ship's combat value, produce 1 hit; your opponent must assign it to 1 of their ships.
to activate-ambush [actor actee]

  ask actor [

    if (my-faction = "mentak") [

      output-print "START MENTAK AMBUSH"

      let sorted    (sort-on [combat-value] (turtle-set my-cruisers my-destroyers))
      let ambushers (up-to-n-of 2 sorted)

      foreach ambushers [
        ambusher ->
          if (any? [my-ships] of actee) and (non-combat-roll >= [combat-value] of ambusher) [
            hit ambusher (optimal-soaker [my-ships] of actee)
          ]
      ]

      output-print "END MENTAK AMBUSH"

    ]

  ]

end

to-report afb-hit-num-pairs

  let my-hits []

  foreach my-afb-triples [
    triple ->
      ;let [ship goal tries] triple
      let ship  (item 0 triple)
      let goal  (item 1 triple)
      let tries (item 2 triple)
      foreach (range tries) [
        ask ship [
          let roll non-combat-roll
          if (kenarified-roll roll goal) [
            set my-hits (fput (list ship roll) my-hits)
          ]
        ]
      ]
  ]

  report my-hits

end

to do-space-combat

  output-print "BEGIN SPACE COMBAT ROUND"

  ; Letnev flagshp "Arc Secundus" ==> At the start of each space combat round, repair this ship
  ask units [
    if (([my-faction] of my-player) = "letnev" and unit-type = "flagship") [
      set damaged? false
    ]
  ]

  set game-state "Tactical Action @3.3: Make Combat Rolls"
  output-print "BEGIN SPACE COMBAT ROLLS"

  let attacker-hits ([space-combat-hits] of attacker)
  let defender-hits ([space-combat-hits] of defender)

  output-print "END SPACE COMBAT ROLLS"

  set game-state "Tactical Action @3.4: Assign Hits"
  output-print "BEGIN SPACE COMBAT HITS"

  let attacker-pre-soaked-soakers (([my-ships] of attacker) with [max-hp > 1 and not damaged?])
  let defender-pre-soaked-soakers (([my-ships] of defender) with [max-hp > 1 and not damaged?])

  let ne-shield-1? non-euclidean-shielding-1?
  let ne-shield-2? non-euclidean-shielding-2?

  assign-space-combat-hits attacker-hits attacker defender ne-shield-2?
  assign-space-combat-hits defender-hits defender attacker ne-shield-1?

  activate-duranium-armor duranium-armor-1? attacker attacker-pre-soaked-soakers
  activate-duranium-armor duranium-armor-2? defender defender-pre-soaked-soakers

  output-print "END SPACE COMBAT HITS"

  output-print "END SPACE COMBAT ROUND"

end

to-report space-combat-hits

  let my-hits []

  foreach my-space-combat-triples [
    triple ->
      ;let [ship goal tries] triple
      let ship  (item 0 triple)
      let goal  (item 1 triple)
      let tries (item 2 triple)
      foreach (range tries) [
        ask ship [

          let base-roll combat-roll

          if (kenarified-roll base-roll goal) [
            set my-hits (fput ship my-hits)
          ]

          ; Jol-Nar flagship "JNS Hylarim" ==> When making a combat roll for this ship, each result of a 9 or 10, before applying modifiers, produces 2 additional hits
          ; Note that `combat-roll` applies the Jol-Nar "Fragile" ability (-1 to combat rolls), so we check 8 and 9 instead of 9 and 10
          if ((([my-faction] of my-player) = "jol-nar") and (unit-type = "flagship") and ((base-roll = 8) or (base-roll = 9))) [
            set my-hits (fput ship (fput ship my-hits))
          ]

        ]
      ]
  ]

  report my-hits

end

; Hacan flagship "Wrath of Kenara" ==> After you roll a die during a space combat in this system, you may spend 1 trade good to apply +1 to the result
; And https://www.tirules.com/F_hacan says that it can only be used once per roll
to-report kenarified-roll [roll-result goal]
  ifelse ([(my-faction = "hacan") and (any? my-flagships) and ((roll-result + 1) = goal) and (trade-goods > 0)] of my-player) [
    ask my-player [ set trade-goods (trade-goods - 1) ]
    report true
  ] [
    report (roll-result >= goal)
  ]
end

to assign-space-combat-hits [hits actor actee nes?]

  let l1z1x-flagship? ([(my-faction = "l1z1x") and any? my-flagships] of actor)
  let ne-shielding?   (([(my-faction = "letnev")] of actee) and nes?)

  ; Non-Euclidean Shielding will chop hits off the end of the list; if it interacts with 0.0.1, you want to be cancelling the "can't hit a fighter" hits, so we put those at the end to prioritize cancelling them
  let sorted-hits (sort-by [ [h1 h2] -> l1z1x-flagship? and member? ([unit-type] of h1) ["flagship" "dreadnought"] ] hits)

  let i 0
  let z (length sorted-hits)

  while [i < z] [

    ; L1Z1X flagship "0.0.1" ==> During a space combat, hits produced by this ship and by your dreadnoughts in this system must be assigned to non-fighter ships if able
    let hitter  (item i sorted-hits)
    let options ([ ifelse-value (l1z1x-flagship? and member? ([unit-type] of hitter) ["flagship" "dreadnought"]) [ my-fleet ] [ my-ships ] ] of actee)

    ifelse (any? options) [

      let soaker (optimal-soaker options)

      hit hitter soaker

      ; Letnev "Non-Euclidean Shielding" (red tech) ==> When 1 of your units uses Sustain Damage, cancel 2 hits instead of 1
      if (((z - i) > 1) and ne-shielding? and (([hp] of soaker) > 1)) [
        ask (item (z - 1) sorted-hits) [ output-print (word (ifelse-value (actor = attacker) [ "ATTACKER" ] [ "DEFENDER" ]) " (" unit-type " " who ")'S HIT CANCELLED BY NON-EUCLIDEAN SHIELDING") ]
        set z (z - 1)
      ]

    ] [
      ask hitter [ output-print (word (ifelse-value (actor = attacker) [ "ATTACKER" ] [ "DEFENDER" ]) " (" unit-type " " who ")'S HIT HAS NO TARGET") ]
    ]

    set i (i + 1)

  ]

end

; Duranium Armor (red tech) ==> During each combat round, after you assign hits to your units, repair 1 of your damaged units that did not use Sustain Damage during this combat round
to activate-duranium-armor [da? actor could-have-soakeds]
  if da? [
    ask actor [
      let just-soaked (could-have-soakeds with [damaged?])
      let options     (my-ships with [damaged? and not destroyed?] who-are-not just-soaked) ; These ones might have soaked at one point, but they didn't use it this round
      let fixer-upper (one-of options with-max [cost])
      if any? fixer-upper [
        ask fixer-upper [
          output-print (word "REMOVING DAMAGE FROM " unit-type " " who " (Duranium Armor)")
          set damaged? false
        ]
      ]
    ]
  ]
end

to do-invasion

  output-print "BEGIN INVASION ROUND"

  if (not after-first-invasion-round?) [
    pre-invasion-cleanup
  ]

  ifelse system-has-planet? [

    ; Magen Defense Grid (red tech) ==> You may exhaust this card at the start of a round of ground combat on a planet that contains 1 or more of your units that have Planetary Shield; your opponent cannot make combat rolls this combat round
    let attack-blocked? ((not after-first-invasion-round?) and magen-defense-grid? and (any? [my-pds] of defender))

    set game-state "Tactical Action @4.1: Bombardment"
    do-bombardment

    do-space-cannon-defense ([my-ground-forces] of attacker)

    while [any? ([my-ground-forces] of attacker) and any? ([my-ground-forces] of defender)] [
      do-ground-combat attack-blocked?
      tick
    ]

    if (not any? ([my-ground-forces] of defender)) [
      ifelse (any? [my-infantry] of attacker) [
        ask defender [
          ask my-local-pds [ go-bye-bye "overrun in invasion" ]
          set defeated? true
        ]
      ] [
        ask players [
          set defeated? true
        ]
      ]
    ]

    if ((not any? ([my-ground-forces] of attacker)) and (not any? [my-ships] of defender)) [
      ask players [
        set defeated? true
      ]
    ]

  ] [
    if (not any? [my-ships] of defender) [
      ask defender [
        set defeated? true
      ]
    ]
  ]

  if (not any? [my-ships] of attacker) [
    ask attacker [
      set defeated? true
    ]
  ]

  output-print "END INVASION ROUND"

  set after-first-invasion-round? true

end

to do-bombardment

  set game-state "Tactical Action @2.2: Space Cannon Offense"

  ask attacker [

    ; Letnev flagship "Arc Secundus" ==> Other players' units in this system lose PLANETARY SHIELD
    let arc-secundus?     ((my-faction = "letnev") and any? my-flagships)
    let shields-disabled? ((any? my-warsuns) or arc-secundus?)

    ifelse (shields-disabled? or (not any? [my-pds] of defender)) [

      output-print "BEGIN BOMBARDMENT"

      output-print "BEGIN BOMBARDMENT ROLLS"

      let hits (bombardment-hits plasma-scoring-1?)

      output-print "END BOMBARDMENT ROLLS"

      output-print "BEGIN BOMBARDMENT HITS"

      foreach hits [
        hitter ->
          ask defender [
            if (any? my-ground-forces) [
              hit hitter (one-of my-ground-forces)
            ]
          ]
      ]

      output-print "END BOMBARDMENT HITS"

      output-print "END BOMBARDMENT"

    ] [
      output-print "SKIPPING BOMBARDMENT"
    ]

  ]

end

to-report bombardment-hits [plasma-scoring?]

  let my-hits []

  let base-triples     my-bombardment-triples
  let modified-triples (ifelse-value plasma-scoring? [ plasma-scoring-triples base-triples ] [ base-triples ])

  foreach modified-triples [
    triple ->
      ;let [bombard goal tries] triple
      let bombard (item 0 triple)
      let goal    (item 1 triple)
      let tries   (item 2 triple)
      foreach (range tries) [
        if (non-combat-roll >= goal) [
          set my-hits (fput bombard my-hits)
        ]
      ]
  ]

  report my-hits

end

to do-space-cannon-defense [attacking-troops]

  ; L4 Disruptors (yellow tech) ==> During an invasion, units cannot use Space Cannon against your units
  ifelse (not l4-disruptors?) [

    set game-state "Tactical Action @4.3: Space Cannon Defense"
    output-print "BEGIN SPACE CANNON DEFENSE"

    let amd? antimass-deflectors-1?
    let ps?  plasma-scoring-2?

    output-print "START SCD ROLLS"

    let hits ([space-cannon-hits amd? ps?] of defender)

    output-print "END SCD ROLLS"

    output-print "BEGIN SCD HITS"

    foreach hits [
      hitter ->
        ask attacker [
          let attackers attacking-troops with [not destroyed?]
          if (any? attackers) [
            hit hitter (optimal-soaker attackers)
          ]
        ]
    ]

    output-print "END SCD HITS"

    output-print "END SPACE CANNON DEFENSE"

  ] [
    output-print "SKIPPING SPACE CANNON DEFENSE"
  ]

end

to do-ground-combat [attack-blocked?]

  output-print "BEGIN GROUND COMBAT ROUND"

  set game-state "Tactical Action @4.4: Ground Combat"
  output-print "BEGIN GROUND COMBAT ROLLS"

  let init-attacker-hits (ifelse-value (not attack-blocked?) [ ground-combat-hits attacker ] [ [] ])
  let init-defender-hits (                                     ground-combat-hits defender         )

  let vpw1? valkyrie-particle-weave-1?
  let vpw2? valkyrie-particle-weave-2?

  ; Sardakk "Valkyrie Particle Weave" (red tech) ==> After making combat rolls during a round of ground combat, if your opponent produced 1 or more hits, you produce 1 additional hit
  let attacker-hits ([ifelse-value (my-faction = "sardakk" and vpw1? and any? init-defender-hits) [ fput self init-attacker-hits ] [ init-attacker-hits ]] of attacker)
  let defender-hits ([ifelse-value (my-faction = "sardakk" and vpw2? and any? init-attacker-hits) [ fput self init-defender-hits ] [ init-defender-hits ]] of defender)

  output-print "END GROUND COMBAT ROLLS"

  set game-state "Tactical Action @4.4b: Assign Hits"
  output-print "BEGIN GROUND COMBAT HITS"

  assign-ground-combat-hits attacker-hits attacker defender
  assign-ground-combat-hits defender-hits defender attacker

  output-print "END GROUND COMBAT HITS"

  output-print "END GROUND COMBAT ROUND"

  ; L1Z1X ability "Harrow" ==> At the end of each round of ground combat, your ships in the active system may use their Bombardment abilities against your opponent's ground forces on the planet
  if (([my-faction] of attacker) = "l1z1x") [
    output-print "BEGIN L1Z1X HARROW"
    do-bombardment
    output-print "END L1Z1X HARROW"
  ]

end

to-report ground-combat-hits [actor]

  let my-hits []

  let triples ([ (list self combat-value combat-shots) ] of ([my-ground-forces] of actor))

  foreach triples [
    triple ->
      ;let [trooper goal tries] triple
      let trooper (item 0 triple)
      let goal    (item 1 triple)
      let tries   (item 2 triple)
      foreach (range tries) [
        ask trooper [
          if (combat-roll >= goal) [
            set my-hits (fput self my-hits)
          ]
        ]
      ]
  ]

  report my-hits

end

to assign-ground-combat-hits [hits actor actee]
  foreach hits [
    hitter ->
      let options ([my-ground-forces] of actee)
      ifelse (any? options) [
        let soaker (optimal-soaker options)
        ifelse (not is-player? hitter) [
          hit hitter soaker
        ] [
          spooky-hit hitter soaker "Valkyrie Particle Weave"
        ]
      ] [
        ask hitter [ output-print (word (ifelse-value (actor = attacker) [ "ATTACKER" ] [ "DEFENDER" ]) " (" unit-type " " who ")'S HIT HAS NO TARGET") ]
      ]
  ]
end

to pre-invasion-cleanup

  let ps (ifelse-value system-has-planet? [ (turtle-set attacker) ] [ (turtle-set attacker defender) ])

  ask ps [

    let num-unhoused-fighters (count my-fighters)
    if ((my-faction = "naalu") and (any? my-fighters) and ([upgraded?] of one-of my-fighters)) [
      let num-houseable-fighters (max (list 0 ((fleet-limit-1 - (count my-fleet)) * 2)))
      set num-unhoused-fighters  (num-unhoused-fighters - num-houseable-fighters)
    ]

    let fleet-capacity        (sum [capacity] of my-ships)
    let num-dying-fighters    (num-unhoused-fighters - fleet-capacity)
    ask n-of (max (list num-dying-fighters 0)) my-fighters [ go-bye-bye "no capacity" ]

    let num-unhoused-infantry (count my-infantry)
    let capacity-for-infantry (max (list 0 (ifelse-value (num-dying-fighters > 0) [ 0 ] [ (fleet-capacity - num-unhoused-fighters) ])))
    let num-dying-infantry    (num-unhoused-infantry - capacity-for-infantry)
    ask n-of (max (list num-dying-infantry 0)) my-infantry [ go-bye-bye "no capacity" ]

  ]

end

to cleanup

  set game-state "cleanup"

  let winner (ifelse-value (not any? [my-ships] of attacker) [ defender ] [ attacker ])

  ask winner [

    let num-leftover-housing (ifelse-value ((self = defender) or (attacking-faction = "l1z1x")) [ space-dock-capacity ] [ 0 ])

    let num-unhoused-fighters ((count my-fighters) - num-leftover-housing)
    if ((my-faction = "naalu") and (any? my-fighters) and ([upgraded?] of one-of my-fighters)) [
      let limit                  (ifelse-value (self = attacker) [ fleet-limit-1 ] [ fleet-limit-2 ])
      let num-houseable-fighters (max (list 0 ((fleet-limit-1 - (count my-fleet)) * 2)))
      set num-unhoused-fighters  (num-unhoused-fighters - num-houseable-fighters)
    ]

    let fleet-capacity        (sum [capacity] of my-ships)
    let num-dying-fighters    (num-unhoused-fighters - fleet-capacity)
    ask n-of (max (list num-dying-fighters 0)) my-fighters [ go-bye-bye "no capacity" ]

    let num-unhoused-infantry (ifelse-value system-has-planet? [ 0 ] [ count my-infantry ])
    let capacity-for-infantry (max (list 0 (ifelse-value (num-dying-fighters > 0) [ 0 ] [ (fleet-capacity - num-unhoused-fighters) ])))
    let num-dying-infantry    (num-unhoused-infantry - capacity-for-infantry)
    ask n-of (max (list num-dying-infantry 0)) my-infantry [ go-bye-bye "no capacity" ]

  ]

end

to-report optimal-soaker [the-units]

  ifelse ((any? the-units with [unit-type = "infantry"]) and (any? the-units with [unit-type = "fighter"])) [
    let p ([my-player] of one-of the-units)
    ifelse (([my-faction] of p) = "naalu") [ ; #JustNaaluThings
      let fighters (the-units with [unit-type = "fighter"])
      let infantry (the-units with [unit-type = "infantry"])
      ifelse (count infantry >= 2) [
        ifelse (([combat-value] of one-of fighters) <= ([combat-value] of one-of infantry)) [
          report one-of infantry
        ] [
          report one-of fighters ; AKA: if infantry are upgraded and fighters are not, sacrifice a fighter
        ]
      ] [
        report one-of (the-units with [unit-type = "fighter"])
      ]
    ] [ ; #JustNekroThings; I can't think of a realistic scenario where Nekro would get more out of a fighter than an infantry
      report one-of (the-units with [unit-type = "fighter"])
    ]
  ] [
    report one-of (turtle-set the-units) with-max [(hp * 1000) + (20 - cost)]
  ]

end

to-report optimal-target [the-units actor]

  let actor-lacks-fighters? (not any? [my-fighters] of actor)
  let prio-targets          (the-units with [(not member? unit-type (list "carrier" "fighter" "infantry" "pds")) and not (actor-lacks-fighters? and unit-type = "destroyer")])

  ifelse (any? prio-targets) [
    let one-shots (prio-targets with [hp = 1])
    ifelse (any? one-shots) [
      report one-of (one-shots with-max [cost])
    ] [
      report one-of (prio-targets with-max [cost])
    ]
  ] [
    report one-of (the-units with-max [cost])
  ]

end

to-report optimal-throwaway [the-units]
  report one-of (turtle-set the-units) with-max [(50 - (hp * 10)) + (20 - cost)]
end

to-report non-combat-roll
  report roll-d10
end

to-report combat-roll

  let faction ([my-faction] of my-player)

  ; Sardakk flagship "C'Morran N'orr" ==> Apply +1 to the result of each of your other ship's combat rolls in this system
  let cmorran-norr (ifelse-value ((faction = "sardakk") and (any? [my-flagships] of my-player) and (member? unit-type ["destroyer" "fighter" "carrier" "cruiser" "dreadnought" "warsun"])) [1] [0])

  ; Sardakk ability "Unrelenting" ==> Apply +1 to the result of each of your unit's combat rolls
  let unrelenting (ifelse-value (faction = "sardakk") [1] [0])

  ; Jol-Nar ability "Fragile" ==> Apply -1 to the result of each of your unit's combat rolls
  let fragile (ifelse-value (faction = "jol-nar") [-1] [0])

  ; Naaz-Rokha ability "Supercharge" ==> At the start of a combat round, you may exhaust this card to apply +1 to the result of each of your unit's combat rolls during this combat round
  let supercharge (ifelse-value (faction = "naaz-rokha") [1] [0])

  ; Mahact flagship "Arvicon Rex" ==> During combat against an opponent whose command token is not in your fleet pool, apply +2 to the results of this unit's combat rolls
  ; Such tokens are obtained through the Mahact "Edict" ability, after defeating your opponent in any combat
  let arvicon-rex (ifelse-value ((faction = "mahact") and (unit-type = "flagship") and (((my-player = attacker) and have-edict-token-1?) or ((my-player = defender) and have-edict-token-2?))) [2] [0])

  report roll-d10 + (cmorran-norr + unrelenting + fragile + supercharge + arvicon-rex)

end

to-report roll-d10
  report (random 10) + 1
end

to hit [hitter target]

  ask hitter [

    output-print (word "HIT: " (ifelse-value (my-player != attacker) [ "attacker's" ] [ "defender's" ]) " " [unit-type] of target " " [who] of target " (by " unit-type " " who ")")

    create-link-to target [
      set color (one-of base-colors)
    ]

    set hit-count (hit-count + 1)
    set label     hit-count

    ask target [
      ifelse ((hp - 1) <= 0) [
        go-bye-bye (word "hit by " [unit-type] of hitter " " [who] of hitter)
      ] [
        sustain-damage
      ]
    ]

  ]

end

to spooky-hit [p target reason]

  output-print (word "HIT: " (ifelse-value (p != attacker) [ "attacker's" ] [ "defender's" ]) " " [unit-type] of target " " [who] of target " (" reason ")")

  ask target [
    ifelse ((hp - 1) <= 0) [
      go-bye-bye (word "hit by " reason)
    ] [
      sustain-damage
    ]
  ]

end

to sustain-damage

  ; Empyrean flagship "Dynamo" ==> After any player's unit in this system or an adjacent system uses SUSTAIN DAMAGE, you may spend 2 influence to repair that unit
  ifelse ([(my-faction = "empyrean") and (any? my-flagships) and ((sum influence-bundles) >= 2)] of my-player) [

    ; Try to spend their Influence efficiently on this
    ask my-player [

      let sorted (sort influence-bundles)

      ifelse (member? 2 sorted) [
        set influence-bundles (remove-item (position 2 sorted) sorted) ; Without a 2
      ] [

        let num-1s (reduce [ [x y] -> ifelse-value (y = 1) [ x + 1 ] [ x ] ] sorted)

        ifelse (num-1s >= 2) [
          let without-1-1  (remove-item (position 1 sorted) sorted)
          let without-2-1s (remove-item (position 1 without-1-1) without-1-1)
          set influence-bundles without-2-1s ; Without 2 1s
        ] [

          let removed-item? false

          let new-guy []

          foreach (range length sorted) [
            i ->
              let x (item i sorted)
              ifelse ((not removed-item?) and (i >= 3)) [
                set removed-item? true
              ] [
                set new-guy (lput x new-guy)
              ]
          ]

          set influence-bundles new-guy ; Without the smallest number greater than 2

        ]
      ]

    ]

    output-print (word "EMPYREAN DYNAMO REPAIRED A HIT TO " unit-type " " who)

  ] [

    hatch-damage-markers 1 [
      set label ""
      set shape "face sad"
      set color grey
      set size  (size / 3)
    ]

    set damaged? true

  ]

end

to go-bye-bye [reason]

  let marker nobody

  hatch-death-markers 1 [
    set label ""
    set shape "x"
    set color yellow
    stamp
    set marker self
  ]

  ask my-in-links [ stamp die ]

  stamp

  ask damage-markers-here [ die ]

  output-print (word "DEATH: " (ifelse-value (my-player = attacker) [ "attacker's" ] [ "defender's" ]) " " unit-type " " who " (" reason ")")

  set destroyed? true

end

to mk-flagships [num u? h c]
  hatch-units num [
    set my-player myself
    set unit-type "flagship"
    set upgraded? u?
    set damaged? false
    set destroyed? false
    set heading h
    set size 4
    set color c
    set shape "star"
  ]
end

to mk-warsuns [num u? h c]
  hatch-units num [
    set my-player myself
    set unit-type "warsun"
    set upgraded? u?
    set damaged? false
    set destroyed? false
    set heading h
    set size 4
    set color c
    set shape "circle"
  ]
end

to mk-dreadnoughts [num u? h c]
  hatch-units num [
    set my-player myself
    set unit-type "dreadnought"
    set upgraded? u?
    set damaged? false
    set destroyed? false
    set heading h
    set size 3.5
    set color c
    set shape "turtle"
  ]
end

to mk-cruisers [num u? h c]
  hatch-units num [
    set my-player myself
    set unit-type "cruiser"
    set upgraded? u?
    set damaged? false
    set destroyed? false
    set heading h
    set size 3
    set color c
    set shape "default"
  ]
end

to mk-destroyers [num u? h c]
  hatch-units num [
    set my-player myself
    set unit-type "destroyer"
    set upgraded? u?
    set damaged? false
    set destroyed? false
    set heading h
    set size 2.5
    set color c
    set shape "bug"
  ]
end

to mk-carriers [num u? h c]
  hatch-units num [
    set my-player myself
    set unit-type "carrier"
    set upgraded? u?
    set damaged? false
    set destroyed? false
    set heading h
    set size 2.5
    set color c
    set shape "truck"
  ]
end

to mk-fighters [num u? h c]
  hatch-units num [
    set my-player myself
    set unit-type "fighter"
    set upgraded? u?
    set damaged? false
    set destroyed? false
    set heading h
    set size 1.5
    set color c
    set shape "airplane"
  ]
end

to mk-infantry [num u? h c]
  hatch-units num [
    set my-player myself
    set unit-type "infantry"
    set upgraded? u?
    set damaged? false
    set destroyed? false
    set heading h
    set size 1.5
    set color c
    set shape "flag"
  ]
end

to mk-pds [num u? h c]
  hatch-units num [
    set my-player myself
    set unit-type "pds"
    set upgraded? u?
    set damaged? false
    set destroyed? false
    set heading h
    set size 1.5
    set color c
    set shape "box"
  ]
end

to-report power
  let space-cannon-power ((1 - (space-cannon-value / 10)) * space-cannon-shots)
  let space-combat-power ((1 - (combat-value / 10)) * combat-shots)
  report (space-cannon-power / 3) + space-combat-power
end

to-report combat-shots

  if unit-type = "flagship" [

    let f ([my-faction] of my-player)

    if (f = "creuss") [
      report 1
    ]

    ; Winnu flagship "Salai Sai Corian" ==> When this unit makes a combat roll, it rolls a number of dice equal to the number of your opponent's non-fighter ships in this system
    if (f = "winnu") [
      let other-player (ifelse-value (my-player = attacker) [ defender ] [ attacker ])
      report (count [my-fleet] of other-player)
    ]

    report 2

  ]

  if unit-type = "warsun" [
    report 3
  ]

  report 1

end

to-report combat-value

  let f ([my-faction] of my-player)

  if unit-type = "flagship" [

    if member? f (list "naalu" "naaz-rokha" "nekro" "yin") [
      report 9
    ]

    if member? f (list "arborec" "argent" "keleres" "hacan" "mentak" "ui" "winnu" "xxcha") [
      report 7
    ]

    if member? f (list "nomad") [
      ifelse upgraded? [
        report 5
      ] [
        report 7
      ]
    ]

    if member? f (list "sardakk" "jol-nar") [
      report 6
    ]

    if member? f (list "letnev" "saar" "muaat" "empyrean" "sol" "creuss" "l1z1x" "mahact" "vuil'raith" "yssaril") [
      report 5
    ]

  ]

  if unit-type = "warsun" [
    report 3
  ]

  if unit-type = "dreadnought" [
    ifelse f = "l1z1x" [
      report 4
    ] [
      report 5
    ]
  ]

  if unit-type = "carrier" [
    report 9
  ]

  if unit-type = "cruiser" [
    report 6
  ]

  if unit-type = "destroyer" [
    ifelse f = "argent" [
      report 7
    ] [
      report 8
    ]
  ]

  if unit-type = "fighter" [
    ifelse f = "naalu" [
      report 7
    ] [
      report 8
    ]
  ]

  if unit-type = "infantry" [
    ifelse f = "sol" [
      report 6
    ] [
      report 7
    ]
  ]

  if unit-type = "pds" and f = "ui" [
    ifelse upgraded? [
      report 6
    ] [
      report 7
    ]
  ]

  report 0

end

to-report space-cannon-shots

  if unit-type = "flagship" and ([my-faction] of my-player) = "xxcha" [
    report 3
  ]

  if unit-type = "pds" [
    report 1
  ]

  report 0

end

to-report space-cannon-value

  if unit-type = "flagship" and ([my-faction] of my-player) = "xxcha" [
    report 5
  ]

  if unit-type = "pds" [
    ifelse upgraded? [
      report 5
    ] [
      report 6
    ]
  ]

  report 0

end

to-report bombard-shots

  let f ([my-faction] of my-player)

  if ((unit-type = "flagship") and (f = "letnev")) [
    report 3
  ]

  if ((unit-type = "flagship") and (f = "vuil'raith")) [
    report 1
  ]

  if (unit-type = "warsun") [
    report 3
  ]

  if (unit-type = "dreadnought") [
    ifelse (f = "sardakk") [
      report 2
    ] [
      report 1
    ]

  ]

  report 0

end

to-report bombard-value

  let f ([my-faction] of my-player)

  if ((unit-type = "flagship") and (member? f ["letnev" "vuil'raith"])) [
    report 5
  ]

  if (unit-type = "warsun") [
    report 3
  ]

  if (unit-type = "dreadnought") [

    if ((f = "sardakk") or
        (f = "l1z1x" and upgraded?)) [
      report 4
    ]

    report 5

  ]

  report 0

end

to-report hp
  report max-hp - (ifelse-value damaged? [ 1 ] [ 0 ])
end

to-report max-hp

  let f        ([my-faction] of my-player)
  let opponent (ifelse-value (my-player = attacker) [ defender ] [ attacker ])

  if (unit-type = "pds") [
    ifelse (f = "ui") [ ; UI Hel-Titans are not ships, so this needs to come before the Mentak check
      report 2
    ] [
      report 0
    ]
  ]

  ; Mentak flagship "Fourth Moon" ==> Other players' ships in this system cannot use SUSTAIN DAMAGE
  if ([(my-faction = "mentak") and any? my-flagships] of opponent) [
    report 1
  ]

  if ((unit-type = "flagship") or
       (unit-type = "warsun") or
       (unit-type = "dreadnought") or
       (unit-type = "carrier" and (f = "sol")) or
       (unit-type = "cruiser" and upgraded? and (f = "ui"))) [
    report 2
  ]

  report 1

end

to-report cost

  if unit-type = "flagship" [
    report 8
  ]

  if unit-type = "warsun" [
    report 12
  ]

  if unit-type = "dreadnought" [
    report 4
  ]

  if unit-type = "carrier" [
    report 3
  ]

  if unit-type = "cruiser" [
    report 2
  ]

  if unit-type = "destroyer" [
    report 1
  ]

  if unit-type = "fighter" [
    report 0.5
  ]

  if unit-type = "infantry" [
    report 0.5
  ]

  if unit-type = "pds" [
    report 3 ; 1 Prod == 1 Influence (Hegemonic Trade Policy); 3 Influence == 1 Strategy Token (Leadership card secondary); 1 Strategy Token == 1 PDS (Construction card secondary)
  ]

end

to-report capacity

  let faction ([my-faction] of my-player)

  if (unit-type = "flagship") [

    if member? faction (list "nomad") [
      ifelse upgraded? [
        report 6
      ] [
        report 3
      ]
    ]

    if member? faction (list "sol") [
      report 12
    ]

    if member? faction (list "keleres" "naalu") [
      report 6
    ]

    if member? faction (list "arborec" "l1z1x") [
      report 5
    ]

    if member? faction (list "naaz-rokha") [
      report 4
    ]

    if member? faction (list "argent" "creuss" "empyrean" "hacan" "jol-nar" "letnev" "mahact" "mentak" "muaat" "nekro" "saar" "sardakk" "ui" "vuil'raith" "winnu" "xxcha" "yin" "yssaril") [
      report 3
    ]

  ]

  if (unit-type = "carrier" and faction = "sol" and upgraded?) [
    report 8
  ]

  if ((unit-type = "carrier") and (faction = "sol" or upgraded?)) or
       (unit-type = "warsun") [
    report 6
  ]

  if (unit-type = "carrier") [
    report 4
  ]

  if ((unit-type = "cruiser") and (faction = "ui") and upgraded?) or
       ((unit-type = "dreadnought") and (faction = "l1z1x")) [
    report 2
  ]

  if (((unit-type = "cruiser") and ((faction = "ui") or upgraded?)) or
       ((unit-type = "destroyer") and (faction = "argent")) or
       (unit-type = "dreadnought")) [
    report 1
  ]

  report 0

end

to-report my-afb-triples

  let out []

  if my-faction = "saar" [
    ask my-flagships [
      set out (fput (list self 6 4) out)
    ]
  ]

  if my-faction = "nomad" [
    ask my-flagships [
      ifelse upgraded? [
        set out (fput (list self 5 3) out)
      ] [
        set out (fput (list self 8 3) out)
      ]
    ]
  ]

  ask my-destroyers [
    ifelse upgraded? [
      set out (fput (list self 9 2) out)
    ] [
      set out (fput (list self 6 3) out)
    ]
  ]

  report out

end

to-report my-space-cannon-triples
  report [(list self space-cannon-value space-cannon-shots)] of (my-living-units with [space-cannon-value > 0])
end

to-report my-space-combat-triples
  report [(list self combat-value combat-shots)] of my-ships
end

to-report my-bombardment-triples
  report [(list self bombard-value bombard-shots)] of (my-ships with [bombard-value > 0])
end

to-report my-living-units
  report my-units with [not destroyed?]
end

to-report my-fleet
  ; Nekro flagship "The Alastor" ==> At the start of a space combat, choose any number of your ground forces in this system to participate in that combat as if they were ships
  ifelse ((my-faction = "nekro") and any? my-flagships) [
    report my-living-units with [unit-type != "fighter" and unit-type != "pds"]
  ] [
    report my-living-units with [unit-type != "fighter" and unit-type != "infantry" and unit-type != "pds"]
  ]
end

to-report my-ships
  ; Nekro flagship "The Alastor" ==> At the start of a space combat, choose any number of your ground forces in this system to participate in that combat as if they were ships
  ifelse ((my-faction = "nekro") and any? my-flagships) [
    report my-living-units with [unit-type != "pds"]
  ] [
    report my-living-units with [unit-type != "infantry" and unit-type != "pds"]
  ]

end

to-report my-flagships
  report my-living-units with [unit-type = "flagship"]
end

to-report my-warsuns
  report my-living-units with [unit-type = "warsun"]
end

to-report my-dreadnoughts
  report my-living-units with [unit-type = "dreadnought"]
end

to-report my-cruisers
  report my-living-units with [unit-type = "cruiser"]
end

to-report my-destroyers
  report my-living-units with [unit-type = "destroyer"]
end

to-report my-carriers
  report my-living-units with [unit-type = "carrier"]
end

to-report my-fighters
  report my-living-units with [unit-type = "fighter"]
end

to-report my-infantry
  report my-living-units with [unit-type = "infantry"]
end

to-report my-pds
  report my-living-units with [unit-type = "pds"]
end

to-report my-ground-forces

  ; Naalu flagship "Matriarch" ==> During an invasion in this system, you may commit fighters to planets as if they were ground forces. When combat ends, return those units to the space area.
  if (self = attacker and my-faction = "naalu" and any? my-flagships) [
    report my-living-units with [unit-type = "fighter" or unit-type = "infantry"]
  ]

  ; Hel-Titans
  if (self = defender and my-faction = "ui") [
    report (turtle-set my-local-pds my-infantry)
  ]

  report my-infantry

end

to-report anti-fighter-units
  report (turtle-set my-destroyers)
end

to-report total-value
  report sum [cost] of my-living-units
end

to-report production-lost
  report startup-cost - total-value
end

to-report outcome
  ifelse (attacker != 0) [

    if ([defeated?] of defender and system-has-planet? and (not any? [my-infantry] of attacker)) [
      report "Weird attack"
    ]

    ifelse ([defeated?] of defender) [
      ifelse ([defeated?] of attacker) [
        report "Stalemate"
      ] [
        report "Successful attack"
      ]
    ] [
      ifelse ([defeated?] of attacker) [
        report "Successful defense"
      ] [
        report "Ongoing"
      ]
    ]

  ] [
    report "Uninitialized"
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
10
10
1712
453
-1
-1
14.0
1
10
1
1
1
0
0
0
1
0
120
0
30
0
0
1
ticks
30.0

CHOOSER
510
490
635
535
attacking-faction
attacking-faction
"arborec" "argent" "creuss" "empyrean" "hacan" "jol-nar" "keleres" "l1z1x" "letnev" "mahact" "mentak" "muaat" "naalu" "naaz-rokha" "nekro" "nomad" "saar" "sardakk" "sol" "ui" "vuil'raith" "winnu" "xxcha" "yssaril"
12

CHOOSER
1190
490
1315
535
defending-faction
defending-faction
"arborec" "argent" "creuss" "empyrean" "hacan" "jol-nar" "keleres" "l1z1x" "letnev" "mahact" "mentak" "muaat" "naalu" "naaz-rokha" "nekro" "nomad" "saar" "sardakk" "sol" "ui" "vuil'raith" "winnu" "xxcha" "yssaril"
7

SWITCH
22
710
222
743
upgraded-fighter-1?
upgraded-fighter-1?
0
1
-1000

SWITCH
22
750
222
783
upgraded-infantry-1?
upgraded-infantry-1?
1
1
-1000

SWITCH
25
630
225
663
upgraded-destroyer-1?
upgraded-destroyer-1?
1
1
-1000

SWITCH
22
790
222
823
upgraded-pds-1?
upgraded-pds-1?
1
1
-1000

SWITCH
25
670
225
703
upgraded-carrier-1?
upgraded-carrier-1?
0
1
-1000

SWITCH
25
590
225
623
upgraded-cruiser-1?
upgraded-cruiser-1?
1
1
-1000

SWITCH
22
550
224
583
upgraded-dreadnought-1?
upgraded-dreadnought-1?
1
1
-1000

SLIDER
232
470
502
503
flagships-1
flagships-1
0
1
1.0
1
1
NIL
HORIZONTAL

SLIDER
232
510
502
543
warsuns-1
warsuns-1
0
2
0.0
1
1
NIL
HORIZONTAL

SLIDER
232
550
502
583
dreadnoughts-1
dreadnoughts-1
0
5
4.0
1
1
NIL
HORIZONTAL

SLIDER
230
670
500
703
carriers-1
carriers-1
0
4
2.0
1
1
NIL
HORIZONTAL

SLIDER
230
710
500
743
fighters-1
fighters-1
0
60
16.0
1
1
NIL
HORIZONTAL

SLIDER
230
590
500
623
cruisers-1
cruisers-1
0
8
0.0
1
1
NIL
HORIZONTAL

SLIDER
230
630
500
663
destroyers-1
destroyers-1
0
8
0.0
1
1
NIL
HORIZONTAL

SLIDER
230
750
500
783
infantry-1
infantry-1
0
20
2.0
1
1
NIL
HORIZONTAL

SLIDER
232
790
502
823
pds-1
pds-1
0
6
0.0
1
1
NIL
HORIZONTAL

SWITCH
1600
715
1800
748
upgraded-fighter-2?
upgraded-fighter-2?
1
1
-1000

SWITCH
1600
755
1800
788
upgraded-infantry-2?
upgraded-infantry-2?
1
1
-1000

SWITCH
1600
635
1800
668
upgraded-destroyer-2?
upgraded-destroyer-2?
1
1
-1000

SWITCH
1600
795
1800
828
upgraded-pds-2?
upgraded-pds-2?
1
1
-1000

SWITCH
1600
675
1800
708
upgraded-carrier-2?
upgraded-carrier-2?
1
1
-1000

SWITCH
1600
595
1800
628
upgraded-cruiser-2?
upgraded-cruiser-2?
1
1
-1000

SWITCH
1600
555
1802
588
upgraded-dreadnought-2?
upgraded-dreadnought-2?
1
1
-1000

SLIDER
1322
475
1592
508
flagships-2
flagships-2
0
1
1.0
1
1
NIL
HORIZONTAL

SLIDER
1322
515
1592
548
warsuns-2
warsuns-2
0
2
0.0
1
1
NIL
HORIZONTAL

SLIDER
1320
555
1590
588
dreadnoughts-2
dreadnoughts-2
0
5
4.0
1
1
NIL
HORIZONTAL

SLIDER
1320
675
1590
708
carriers-2
carriers-2
0
4
1.0
1
1
NIL
HORIZONTAL

SLIDER
1320
715
1590
748
fighters-2
fighters-2
0
60
5.0
1
1
NIL
HORIZONTAL

SLIDER
1320
595
1590
628
cruisers-2
cruisers-2
0
8
0.0
1
1
NIL
HORIZONTAL

SLIDER
1320
635
1590
668
destroyers-2
destroyers-2
0
8
0.0
1
1
NIL
HORIZONTAL

SLIDER
1320
755
1590
788
infantry-2
infantry-2
0
20
3.0
1
1
NIL
HORIZONTAL

SLIDER
1322
795
1592
828
pds-2
pds-2
0
6
2.0
1
1
NIL
HORIZONTAL

BUTTON
685
465
900
530
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
910
465
1120
530
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

PLOT
545
775
900
955
Power
Ticks
Likely Hits
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"attacker" 1.0 0 -2674135 true "" "plot sum [power] of [my-living-units] of attacker"
"defender" 1.0 0 -13345367 true "" "plot sum [power] of [my-living-units] of defender"

PLOT
910
775
1275
955
Survivability
Ticks
Hits
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"attacker" 1.0 0 -2674135 true "" "plot sum [hp] of [my-living-units] of attacker"
"defender" 1.0 0 -13345367 true "" "plot sum [hp] of [my-living-units] of defender"

PLOT
545
960
900
1150
Value
Ticks
Production
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"attacker" 1.0 0 -2674135 true "" "plot [total-value] of attacker"
"defender" 1.0 0 -13345367 true "" "plot [total-value] of defender"

PLOT
910
960
1275
1150
Number of Ships
Ticks
Ships
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"attacker" 1.0 0 -2674135 true "" "plot count [my-living-units] of attacker"
"defender" 1.0 0 -13345367 true "" "plot count [my-living-units] of defender"

OUTPUT
545
1155
1275
1325
16

SLIDER
660
540
1145
573
space-dock-capacity
space-dock-capacity
0
20
0.0
1
1
NIL
HORIZONTAL

SWITCH
660
580
1145
613
system-has-planet?
system-has-planet?
0
1
-1000

SLIDER
20
845
220
878
fleet-limit-1
fleet-limit-1
0
15
6.0
1
1
NIL
HORIZONTAL

SLIDER
1600
850
1800
883
fleet-limit-2
fleet-limit-2
0
15
5.0
1
1
NIL
HORIZONTAL

SWITCH
230
845
500
878
antimass-deflectors-1?
antimass-deflectors-1?
0
1
-1000

SWITCH
1322
850
1592
883
antimass-deflectors-2?
antimass-deflectors-2?
1
1
-1000

SWITCH
230
885
500
918
plasma-scoring-1?
plasma-scoring-1?
0
1
-1000

SWITCH
1320
890
1590
923
plasma-scoring-2?
plasma-scoring-2?
0
1
-1000

SWITCH
230
925
500
958
graviton-lasers-1?
graviton-lasers-1?
1
1
-1000

SWITCH
1320
930
1590
963
graviton-lasers-2?
graviton-lasers-2?
1
1
-1000

SWITCH
230
965
500
998
assault-cannon-1?
assault-cannon-1?
1
1
-1000

SWITCH
1320
970
1590
1003
assault-cannon-2?
assault-cannon-2?
1
1
-1000

SWITCH
230
1005
500
1038
dimensional-splicer-1?
dimensional-splicer-1?
1
1
-1000

SWITCH
1320
1010
1590
1043
dimensional-splicer-2?
dimensional-splicer-2?
1
1
-1000

SWITCH
660
620
1145
653
system-has-wormhole?
system-has-wormhole?
0
1
-1000

SWITCH
230
1045
500
1078
duranium-armor-1?
duranium-armor-1?
1
1
-1000

SWITCH
1320
1050
1590
1083
duranium-armor-2?
duranium-armor-2?
1
1
-1000

SWITCH
230
1085
500
1118
non-euclidean-shielding-1?
non-euclidean-shielding-1?
1
1
-1000

SWITCH
1320
1090
1590
1123
non-euclidean-shielding-2?
non-euclidean-shielding-2?
1
1
-1000

SWITCH
1600
1130
1800
1163
magen-defense-grid?
magen-defense-grid?
1
1
-1000

SWITCH
20
1125
220
1158
l4-disruptors?
l4-disruptors?
1
1
-1000

MONITOR
660
660
1145
757
Outcome
outcome
17
1
24

SWITCH
230
1125
500
1158
valkyrie-particle-weave-1?
valkyrie-particle-weave-1?
1
1
-1000

SWITCH
1320
1130
1590
1163
valkyrie-particle-weave-2?
valkyrie-particle-weave-2?
1
1
-1000

SLIDER
1600
1090
1800
1123
adjacent-pds
adjacent-pds
0
6
0.0
1
1
NIL
HORIZONTAL

SLIDER
20
885
220
918
initial-trade-goods-1
initial-trade-goods-1
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
1600
890
1800
923
initial-trade-goods-2
initial-trade-goods-2
0
100
0.0
1
1
NIL
HORIZONTAL

SWITCH
17
1005
222
1038
have-edict-token-1?
have-edict-token-1?
1
1
-1000

SWITCH
1600
1010
1800
1043
have-edict-token-2?
have-edict-token-2?
1
1
-1000

INPUTBOX
1600
930
1800
1000
initial-influence-bundles-2
[]
1
0
String (reporter)

INPUTBOX
20
925
220
995
initial-influence-bundles-1
[]
1
0
String (reporter)

SWITCH
27
470
227
503
upgraded-flagship-1?
upgraded-flagship-1?
1
1
-1000

SWITCH
1600
475
1800
508
upgraded-flagship-2?
upgraded-flagship-2?
1
1
-1000

MONITOR
510
555
650
600
Attacker Production Lost
[production-lost] of attacker
17
1
11

MONITOR
1160
555
1312
600
Defender Production Lost
[production-lost] of defender
17
1
11

MONITOR
510
600
650
645
Attacker Unit Value
[total-value] of attacker
17
1
11

MONITOR
1160
600
1310
645
Defender Unit Value
[total-value] of defender
17
1
11

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

### Unimplemented features (will probably never happen)

  * Action cards
  * Promissory notes
  * Yin faction
    * Flagship: When destroyed, destroy all ships in the system
    * Indoctrination: Spend 2 Influence to replace an enemy infantry with one of my own
    * Devotion: Destroy one of my cruisers or destroyers to give 1 hit to enemy fleet
    * Impulse Core (tech): Destroy one of my cruisers or destroyers to give 1 hit to enemy fleet (non-fighter, if possible)

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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="naalu-l1z1x faceoff" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>([defeated?] of attacker) or ([defeated?] of defender)</exitCondition>
    <metric>sum [cost] of [my-living-units] of attacker</metric>
    <metric>sum [cost] of [my-living-units] of defender</metric>
    <metric>sum [power] of [my-living-units] of attacker</metric>
    <metric>sum [power] of [my-living-units] of defender</metric>
    <metric>sum [hp] of [my-living-units] of attacker</metric>
    <metric>sum [hp] of [my-living-units] of defender</metric>
    <metric>count [my-living-units] of attacker</metric>
    <metric>count [my-living-units] of defender</metric>
    <metric>count [my-flagships] of attacker</metric>
    <metric>count [my-warsuns] of attacker</metric>
    <metric>count [my-dreadnoughts] of attacker</metric>
    <metric>count [my-cruisers] of attacker</metric>
    <metric>count [my-destroyers] of attacker</metric>
    <metric>count [my-carriers] of attacker</metric>
    <metric>count [my-fighters] of attacker</metric>
    <metric>count [my-infantry] of attacker</metric>
    <metric>count [my-pds] of attacker</metric>
    <metric>outcome</metric>
    <enumeratedValueSet variable="dreadnoughts-2">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plasma-scoring-2?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-cruiser-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="warsuns-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-pds-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non-euclidean-shielding-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duranium-armor-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non-euclidean-shielding-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fleet-limit-2">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graviton-lasers-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="system-has-wormhole?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carriers-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-destroyer-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dimensional-splicer-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-carrier-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-cruiser-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-pds-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duranium-armor-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pds-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infantry-1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-destroyer-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fighters-2">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="magen-defense-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="system-has-planet?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dimensional-splicer-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-carrier-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-fighter-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flagships-2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attacking-faction">
      <value value="&quot;naalu&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruisers-1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dreadnoughts-1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="destroyers-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="valkyrie-particle-weave-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="space-dock-capacity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-fighter-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="antimass-deflectors-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carriers-1">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="valkyrie-particle-weave-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assault-cannon-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="antimass-deflectors-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="warsuns-1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="l4-disruptors?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-infantry-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fleet-limit-1">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-infantry-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fighters-1">
      <value value="13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-dreadnought-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infantry-2">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="defending-faction">
      <value value="&quot;l1z1x&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assault-cannon-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flagships-1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pds-1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="graviton-lasers-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="destroyers-1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cruisers-2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upgraded-dreadnought-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plasma-scoring-1?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1v1" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>([defeated?] of attacker) or ([defeated?] of defender)</exitCondition>
    <metric>outcome</metric>
  </experiment>
  <experiment name="naalu-l1z1x faceoff 2" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>([defeated?] of attacker) or ([defeated?] of defender)</exitCondition>
    <metric>sum [cost] of [my-living-units] of attacker</metric>
    <metric>sum [cost] of [my-living-units] of defender</metric>
    <metric>sum [power] of [my-living-units] of attacker</metric>
    <metric>sum [power] of [my-living-units] of defender</metric>
    <metric>sum [hp] of [my-living-units] of attacker</metric>
    <metric>sum [hp] of [my-living-units] of defender</metric>
    <metric>count [my-living-units] of attacker</metric>
    <metric>count [my-living-units] of defender</metric>
    <metric>count [my-flagships] of attacker</metric>
    <metric>count [my-warsuns] of attacker</metric>
    <metric>count [my-dreadnoughts] of attacker</metric>
    <metric>count [my-cruisers] of attacker</metric>
    <metric>count [my-destroyers] of attacker</metric>
    <metric>count [my-carriers] of attacker</metric>
    <metric>count [my-fighters] of attacker</metric>
    <metric>count [my-infantry] of attacker</metric>
    <metric>count [my-pds] of attacker</metric>
    <metric>outcome</metric>
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
1
@#$#@#$#@
