;; rf_structures.il - RF-specific structures for auto_rfic
;; This file contains functions for creating RF-specific layout structures

;; Define the RF structures namespace
autoRficRfStructures = list(nil)

;; Function to create a spiral inductor
procedure(autoRficCreateSpiralInductor(layout centerPoint @optional (inductance 1.0) (numTurns 3.5) (width 5.0) (spacing 2.0))
  let((centerX centerY radius points)
    autoRficLogInfo(sprintf(nil "Creating spiral inductor with L=%g nH" inductance))
    
    ;; Extract center coordinates
    centerX = car(centerPoint)
    centerY = cadr(centerPoint)
    
    ;; Calculate initial radius based on inductance (simplified model)
    ;; In a real implementation, this would use more complex equations
    radius = sqrt(inductance) * 50.0
    
    ;; Create spiral points
    points = list()
    
    ;; Add center connection point
    points = append(points list(centerX:centerY))
    
    ;; Create spiral
    for(turn 0 numTurns 0.1
      let((angle x y)
        angle = turn * 2 * pi
        x = centerX + radius * turn / numTurns * cos(angle)
        y = centerY + radius * turn / numTurns * sin(angle)
        points = append(points list(x:y))
      )
    )
    
    ;; Create path for spiral
    dbCreatePath(
      layout
      list("M5" "drawing")  ;; Use top metal for inductors
      points
      width
      list("flat" "extend" "truncate")
    )
    
    ;; Create underpass for center connection
    ;; This is a simplified approach - real implementation would be more complex
    let((startPoint endPoint)
      startPoint = car(points)
      endPoint = list(centerX + radius + width centerY)
      
      dbCreatePath(
        layout
        list("M4" "drawing")
        list(startPoint endPoint)
        width
        list("flat" "extend" "truncate")
      )
      
      ;; Create vias
      autoRficCreateVia(layout startPoint "M4" "M5")
      autoRficCreateVia(layout endPoint "M4" "M5")
    )
    
    autoRficLogInfo("Created spiral inductor")
    t
  )
)

;; Function to create a symmetric differential inductor
procedure(autoRficCreateDifferentialInductor(layout centerPoint @optional (inductance 1.0) (numTurns 3.5) (width 5.0) (spacing 2.0))
  let((centerX centerY radius points1 points2)
    autoRficLogInfo(sprintf(nil "Creating differential inductor with L=%g nH" inductance))
    
    ;; Extract center coordinates
    centerX = car(centerPoint)
    centerY = cadr(centerPoint)
    
    ;; Calculate initial radius based on inductance (simplified model)
    radius = sqrt(inductance) * 40.0
    
    ;; Create first spiral points
    points1 = list()
    
    ;; Add center connection point for first spiral
    points1 = append(points1 list(centerX-spacing:centerY))
    
    ;; Create first spiral
    for(turn 0 numTurns 0.1
      let((angle x y)
        angle = turn * 2 * pi
        x = centerX - spacing + radius * turn / numTurns * cos(angle)
        y = centerY + radius * turn / numTurns * sin(angle)
        points1 = append(points1 list(x:y))
      )
    )
    
    ;; Create second spiral points
    points2 = list()
    
    ;; Add center connection point for second spiral
    points2 = append(points2 list(centerX+spacing:centerY))
    
    ;; Create second spiral
    for(turn 0 numTurns 0.1
      let((angle x y)
        angle = turn * 2 * pi + pi  ;; Start from opposite side
        x = centerX + spacing + radius * turn / numTurns * cos(angle)
        y = centerY + radius * turn / numTurns * sin(angle)
        points2 = append(points2 list(x:y))
      )
    )
    
    ;; Create paths for spirals
    dbCreatePath(
      layout
      list("M5" "drawing")
      points1
      width
      list("flat" "extend" "truncate")
    )
    
    dbCreatePath(
      layout
      list("M5" "drawing")
      points2
      width
      list("flat" "extend" "truncate")
    )
    
    ;; Create underpasses for center connections
    ;; This is a simplified approach - real implementation would be more complex
    let((startPoint1 endPoint1 startPoint2 endPoint2)
      startPoint1 = car(points1)
      endPoint1 = list(centerX - radius - width - spacing centerY)
      
      startPoint2 = car(points2)
      endPoint2 = list(centerX + radius + width + spacing centerY)
      
      dbCreatePath(
        layout
        list("M4" "drawing")
        list(startPoint1 endPoint1)
        width
        list("flat" "extend" "truncate")
      )
      
      dbCreatePath(
        layout
        list("M4" "drawing")
        list(startPoint2 endPoint2)
        width
        list("flat" "extend" "truncate")
      )
      
      ;; Create vias
      autoRficCreateVia(layout startPoint1 "M4" "M5")
      autoRficCreateVia(layout endPoint1 "M4" "M5")
      autoRficCreateVia(layout startPoint2 "M4" "M5")
      autoRficCreateVia(layout endPoint2 "M4" "M5")
    )
    
    autoRficLogInfo("Created differential inductor")
    t
  )
)

;; Function to create an MOM capacitor
procedure(autoRficCreateMomCapacitor(layout centerPoint @optional (capacitance 1.0) (width 10.0) (length 10.0) (numFingers 5))
  let((centerX centerY)
    autoRficLogInfo(sprintf(nil "Creating MOM capacitor with C=%g pF" capacitance))
    
    ;; Extract center coordinates
    centerX = car(centerPoint)
    centerY = cadr(centerPoint)
    
    ;; Calculate dimensions based on capacitance (simplified model)
    ;; In a real implementation, this would use more complex equations
    fingerLength = length
    fingerWidth = width / numFingers
    fingerSpacing = fingerWidth
    
    ;; Create fingers
    for(i 1 numFingers
      let((x y)
        x = centerX - width/2 + (i-1) * (fingerWidth + fingerSpacing)
        y = centerY - length/2
        
        ;; Create finger
        dbCreateRect(
          layout
          list("M4" "drawing")
          list(
            list(x y)
            list(x + fingerWidth y)
            list(x + fingerWidth y + fingerLength)
            list(x y + fingerLength)
          )
        )
        
        ;; Create connection to top plate for even fingers
        when(evenp(i)
          dbCreateRect(
            layout
            list("M5" "drawing")
            list(
              list(x y + fingerLength - fingerWidth)
              list(x + fingerWidth y + fingerLength - fingerWidth)
              list(x + fingerWidth y + fingerLength)
              list(x y + fingerLength)
            )
          )
          
          ;; Create via
          autoRficCreateVia(
            layout
            list(x + fingerWidth/2 y + fingerLength - fingerWidth/2)
            "M4"
            "M5"
          )
        )
        
        ;; Create connection to bottom plate for odd fingers
        when(oddp(i)
          dbCreateRect(
            layout
            list("M3" "drawing")
            list(
              list(x y)
              list(x + fingerWidth y)
              list(x + fingerWidth y + fingerWidth)
              list(x y + fingerWidth)
            )
          )
          
          ;; Create via
          autoRficCreateVia(
            layout
            list(x + fingerWidth/2 y + fingerWidth/2)
            "M3"
            "M4"
          )
        )
      )
    )
    
    ;; Create top plate connection
    dbCreateRect(
      layout
      list("M5" "drawing")
      list(
        list(centerX - width/2 centerY + length/2 + fingerWidth)
        list(centerX + width/2 centerY + length/2 + fingerWidth)
        list(centerX + width/2 centerY + length/2)
        list(centerX - width/2 centerY + length/2)
      )
    )
    
    ;; Create bottom plate connection
    dbCreateRect(
      layout
      list("M3" "drawing")
      list(
        list(centerX - width/2 centerY - length/2)
        list(centerX + width/2 centerY - length/2)
        list(centerX + width/2 centerY - length/2 - fingerWidth)
        list(centerX - width/2 centerY - length/2 - fingerWidth)
      )
    )
    
    autoRficLogInfo("Created MOM capacitor")
    t
  )
)

;; Function to create a transmission line
procedure(autoRficCreateTransmissionLine(layout startPoint endPoint @optional (width 5.0) (groundWidth 10.0))
  let((length)
    autoRficLogInfo("Creating transmission line")
    
    ;; Calculate length
    dx = car(endPoint) - car(startPoint)
    dy = cadr(endPoint) - cadr(startPoint)
    length = sqrt(dx*dx + dy*dy)
    
    ;; Create signal line
    dbCreatePath(
      layout
      list("M5" "drawing")
      list(startPoint endPoint)
      width
      list("flat" "extend" "truncate")
    )
    
    ;; Create ground planes on both sides
    ;; This is a simplified approach - real implementation would be more complex
    let((angle perpX perpY groundPath1 groundPath2)
      angle = atan2(dy dx)
      perpX = groundWidth * sin(angle)
      perpY = -groundWidth * cos(angle)
      
      groundPath1 = list(
        list(car(startPoint) + perpX cadr(startPoint) + perpY)
        list(car(endPoint) + perpX cadr(endPoint) + perpY)
      )
      
      groundPath2 = list(
        list(car(startPoint) - perpX cadr(startPoint) - perpY)
        list(car(endPoint) - perpX cadr(endPoint) - perpY)
      )
      
      dbCreatePath(
        layout
        list("M5" "drawing")
        groundPath1
        groundWidth
        list("flat" "extend" "truncate")
      )
      
      dbCreatePath(
        layout
        list("M5" "drawing")
        groundPath2
        groundWidth
        list("flat" "extend" "truncate")
      )
    )
    
    autoRficLogInfo(sprintf(nil "Created transmission line with length %g" length))
    t
  )
)

;; Function to create a balun
procedure(autoRficCreateBalun(layout centerPoint @optional (radius 50.0) (width 5.0) (spacing 2.0))
  let((centerX centerY)
    autoRficLogInfo("Creating balun")
    
    ;; Extract center coordinates
    centerX = car(centerPoint)
    centerY = cadr(centerPoint)
    
    ;; Create primary winding (simplified)
    let((points)
      points = list()
      
      ;; Create spiral points for primary
      for(angle 0 4*pi 0.1
        let((x y)
          x = centerX + radius * cos(angle)
          y = centerY + radius * sin(angle)
          points = append(points list(x:y))
        )
      )
      
      dbCreatePath(
        layout
        list("M5" "drawing")
        points
        width
        list("flat" "extend" "truncate")
      )
    )
    
    ;; Create secondary winding (simplified)
    let((points1 points2)
      points1 = list()
      points2 = list()
      
      ;; Create spiral points for first half of secondary
      for(angle 0 2*pi 0.1
        let((x y)
          x = centerX + (radius - spacing - width) * cos(angle)
          y = centerY + (radius - spacing - width) * sin(angle)
          points1 = append(points1 list(x:y))
        )
      )
      
      ;; Create spiral points for second half of secondary
      for(angle 2*pi 4*pi 0.1
        let((x y)
          x = centerX + (radius - spacing - width) * cos(angle)
          y = centerY + (radius - spacing - width) * sin(angle)
          points2 = append(points2 list(x:y))
        )
      )
      
      dbCreatePath(
        layout
        list("M4" "drawing")
        points1
        width
        list("flat" "extend" "truncate")
      )
      
      dbCreatePath(
        layout
        list("M4" "drawing")
        points2
        width
        list("flat" "extend" "truncate")
      )
    )
    
    autoRficLogInfo("Created balun")
    t
  )
)

;; Function to create a guard ring
procedure(autoRficCreateGuardRing(layout region @optional (width 5.0) (layer "M1"))
  let((minX minY maxX maxY)
    autoRficLogInfo("Creating guard ring")
    
    ;; Extract region coordinates
    minX = caar(region)
    minY = cadar(region)
    maxX = caadr(region)
    maxY = cadadr(region)
    
    ;; Create guard ring
    dbCreateRect(
      layout
      list(layer "drawing")
      list(
        list(minX - width minY - width)
        list(maxX + width minY - width)
        list(maxX + width minY)
        list(minX - width minY)
      )
    )
    
    dbCreateRect(
      layout
      list(layer "drawing")
      list(
        list(maxX minY - width)
        list(maxX + width minY - width)
        list(maxX + width maxY + width)
        list(maxX maxY + width)
      )
    )
    
    dbCreateRect(
      layout
      list(layer "drawing")
      list(
        list(minX - width maxY)
        list(maxX + width maxY)
        list(maxX + width maxY + width)
        list(minX - width maxY + width)
      )
    )
    
    dbCreateRect(
      layout
      list(layer "drawing")
      list(
        list(minX - width minY - width)
        list(minX minY - width)
        list(minX maxY + width)
        list(minX - width maxY + width)
      )
    )
    
    autoRficLogInfo("Created guard ring")
    t
  )
)

;; Function to create an RF pad
procedure(autoRficCreateRfPad(layout centerPoint @optional (width 100.0) (height 100.0) (layer "M1"))
  let((centerX centerY)
    autoRficLogInfo("Creating RF pad")
    
    ;; Extract center coordinates
    centerX = car(centerPoint)
    centerY = cadr(centerPoint)
    
    ;; Create pad
    dbCreateRect(
      layout
      list(layer "drawing")
      list(
        list(centerX - width/2 centerY - height/2)
        list(centerX + width/2 centerY - height/2)
        list(centerX + width/2 centerY + height/2)
        list(centerX - width/2 centerY + height/2)
      )
    )
    
    ;; Create vias to connect to lower layers
    for(x centerX - width/4 centerX + width/4 width/2
      for(y centerY - height/4 centerY + height/4 height/2
        autoRficCreateVia(layout list(x y) layer "M2")
      )
    )
    
    autoRficLogInfo("Created RF pad")
    t
  )
)

;; Add all RF structure functions to the namespace
autoRficRfStructures = append(autoRficRfStructures list(
  'createSpiralInductor autoRficCreateSpiralInductor
  'createDifferentialInductor autoRficCreateDifferentialInductor
  'createMomCapacitor autoRficCreateMomCapacitor
  'createTransmissionLine autoRficCreateTransmissionLine
  'createBalun autoRficCreateBalun
  'createGuardRing autoRficCreateGuardRing
  'createRfPad autoRficCreateRfPad
))

;; Export the RF structures namespace
autoRficRfStructures
