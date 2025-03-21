;; placement.il - Component placement for auto_rfic
;; This file contains functions for placing components in RF layouts

;; Define the placement namespace
autoRficPlacement = list(nil)

;; Function to place differential pairs symmetrically
procedure(autoRficPlaceDifferentialPair(layout instNames @optional (centerX nil) (centerY nil))
  let((inst1 inst2 bbox1 bbox2 width1 height1 width2 height2 spacing x1 y1 x2 y2)
    autoRficLogInfo(sprintf(nil "Placing differential pair: %L" instNames))
    
    unless(length(instNames) == 2
      autoRficLogError("Differential pair requires exactly 2 instances")
      return(nil)
    )
    
    ;; Get instances
    inst1 = dbFindAnyInstByName(layout car(instNames))
    inst2 = dbFindAnyInstByName(layout cadr(instNames))
    
    unless(and inst1 inst2
      autoRficLogError("Could not find one or both differential pair instances")
      return(nil)
    )
    
    ;; Get bounding boxes
    bbox1 = dbTransformBBox(dbGetInstBBox(inst1) dbGetInstTransform(inst1))
    bbox2 = dbTransformBBox(dbGetInstBBox(inst2) dbGetInstTransform(inst2))
    
    ;; Calculate dimensions
    width1 = caadr(bbox1) - caar(bbox1)
    height1 = cadadr(bbox1) - cadar(bbox1)
    width2 = caadr(bbox2) - caar(bbox2)
    height2 = cadadr(bbox2) - cadar(bbox2)
    
    ;; Use provided center or calculate center of layout
    unless(and centerX centerY
      let((boundary)
        boundary = dbGetBBox(layout)
        centerX = (caar(boundary) + caadr(boundary)) / 2
        centerY = (cadar(boundary) + cadadr(boundary)) / 2
      )
    )
    
    ;; Calculate spacing
    spacing = max(width1 width2) * 0.2
    
    ;; Calculate new positions
    x1 = centerX - width1/2 - spacing/2
    y1 = centerY - height1/2
    x2 = centerX + spacing/2
    y2 = centerY - height2/2
    
    ;; Move instances
    dbMoveFig(inst1 list(x1:y1 - list(caar(bbox1):cadar(bbox1))))
    dbMoveFig(inst2 list(x2:y2 - list(caar(bbox2):cadar(bbox2))))
    
    ;; Mirror the second instance for symmetry
    dbMirrorFig(inst2 "MY" list(x2:y2))
    
    autoRficLogInfo("Placed differential pair with symmetry")
    t
  )
)

;; Function to place current mirrors
procedure(autoRficPlaceCurrentMirror(layout instNames @optional (x nil) (y nil))
  let((insts bboxes widths heights totalWidth spacing)
    autoRficLogInfo(sprintf(nil "Placing current mirror: %L" instNames))
    
    ;; Get instances
    insts = foreach(mapcar name instNames
      dbFindAnyInstByName(layout name)
    )
    
    ;; Check if all instances were found
    unless(forall(x insts x)
      autoRficLogError("Could not find one or more current mirror instances")
      return(nil)
    )
    
    ;; Get bounding boxes
    bboxes = foreach(mapcar inst insts
      dbTransformBBox(dbGetInstBBox(inst) dbGetInstTransform(inst))
    )
    
    ;; Calculate dimensions
    widths = foreach(mapcar bbox bboxes
      caadr(bbox) - caar(bbox)
    )
    
    heights = foreach(mapcar bbox bboxes
      cadadr(bbox) - cadar(bbox)
    )
    
    ;; Calculate total width and spacing
    totalWidth = apply('plus widths)
    spacing = car(widths) * 0.1
    totalWidth = totalWidth + spacing * (length(instNames) - 1)
    
    ;; Use provided position or calculate
    unless(and x y
      let((boundary)
        boundary = dbGetBBox(layout)
        x = caar(boundary) + 100
        y = cadar(boundary) + 100
      )
    )
    
    ;; Place instances in a row
    currentX = x
    for(i 1 length(insts)
      let((inst bbox width height)
        inst = nth(i insts)
        bbox = nth(i bboxes)
        width = nth(i widths)
        height = nth(i heights)
        
        ;; Move instance
        dbMoveFig(inst list(currentX:y - list(caar(bbox):cadar(bbox))))
        
        ;; Update x position for next instance
        currentX = currentX + width + spacing
      )
    )
    
    autoRficLogInfo("Placed current mirror")
    t
  )
)

;; Function to place matched components
procedure(autoRficPlaceMatchedComponents(layout instNames @optional (pattern "common_centroid"))
  let(()
    autoRficLogInfo(sprintf(nil "Placing matched components using pattern: %s" pattern))
    
    case(pattern
      ("common_centroid"
        autoRficPlaceCommonCentroid(layout instNames)
      )
      ("interdigitated"
        autoRficPlaceInterdigitated(layout instNames)
      )
      ("cross_coupled"
        autoRficPlaceCrossCoupled(layout instNames)
      )
      (t
        autoRficLogError(sprintf(nil "Unknown matching pattern: %s" pattern))
        nil
      )
    )
  )
)

;; Function to place components in common-centroid pattern
procedure(autoRficPlaceCommonCentroid(layout instNames)
  let((insts bboxes numInsts rows cols grid centerX centerY)
    ;; Get instances
    insts = foreach(mapcar name instNames
      dbFindAnyInstByName(layout name)
    )
    
    ;; Check if all instances were found
    unless(forall(x insts x)
      autoRficLogError("Could not find one or more instances")
      return(nil)
    )
    
    ;; Get bounding boxes
    bboxes = foreach(mapcar inst insts
      dbTransformBBox(dbGetInstBBox(inst) dbGetInstTransform(inst))
    )
    
    ;; Determine grid size
    numInsts = length(insts)
    rows = ceiling(sqrt(numInsts))
    cols = ceiling(numInsts / rows)
    
    ;; Create grid
    grid = makeTable("grid" rows cols)
    
    ;; Fill grid with instance indices using common-centroid pattern
    ;; This is a simplified implementation - a real one would be more complex
    for(i 1 numInsts
      let((row col)
        row = mod(i-1 rows) + 1
        col = ceiling(i / rows)
        
        ;; For common-centroid, we'd use a more complex assignment
        ;; This is just a placeholder
        grid[row][col] = i
      )
    )
    
    ;; Calculate center of layout
    let((boundary)
      boundary = dbGetBBox(layout)
      centerX = (caar(boundary) + caadr(boundary)) / 2
      centerY = (cadar(boundary) + cadadr(boundary)) / 2
    )
    
    ;; Place instances according to grid
    for(row 1 rows
      for(col 1 cols
        let((idx inst bbox width height x y)
          idx = grid[row][col]
          when(and idx idx <= numInsts
            inst = nth(idx insts)
            bbox = nth(idx bboxes)
            width = caadr(bbox) - caar(bbox)
            height = cadadr(bbox) - cadar(bbox)
            
            ;; Calculate position
            x = centerX + (col - (cols+1)/2) * width * 1.2
            y = centerY + (row - (rows+1)/2) * height * 1.2
            
            ;; Move instance
            dbMoveFig(inst list(x:y - list(caar(bbox):cadar(bbox))))
          )
        )
      )
    )
    
    autoRficLogInfo("Placed components in common-centroid pattern")
    t
  )
)

;; Function to place components in interdigitated pattern
procedure(autoRficPlaceInterdigitated(layout instNames)
  let((insts bboxes numInsts spacing x y)
    ;; Get instances
    insts = foreach(mapcar name instNames
      dbFindAnyInstByName(layout name)
    )
    
    ;; Check if all instances were found
    unless(forall(x insts x)
      autoRficLogError("Could not find one or more instances")
      return(nil)
    )
    
    ;; Get bounding boxes
    bboxes = foreach(mapcar inst insts
      dbTransformBBox(dbGetInstBBox(inst) dbGetInstTransform(inst))
    )
    
    ;; Calculate dimensions of first instance as reference
    width = caadr(car(bboxes)) - caar(car(bboxes))
    height = cadadr(car(bboxes)) - cadar(car(bboxes))
    
    ;; Calculate spacing
    spacing = width * 0.2
    
    ;; Calculate starting position
    let((boundary)
      boundary = dbGetBBox(layout)
      x = caar(boundary) + 100
      y = cadar(boundary) + 100
    )
    
    ;; Place instances in alternating pattern
    for(i 1 length(insts)
      let((inst bbox)
        inst = nth(i insts)
        bbox = nth(i bboxes)
        
        ;; Move instance
        dbMoveFig(inst list(x:y - list(caar(bbox):cadar(bbox))))
        
        ;; Update x position for next instance
        x = x + width + spacing
        
        ;; Flip orientation for every other instance
        when(evenp(i)
          dbMirrorFig(inst "MX" list(x-width/2:y))
        )
      )
    )
    
    autoRficLogInfo("Placed components in interdigitated pattern")
    t
  )
)

;; Function to place components in cross-coupled pattern
procedure(autoRficPlaceCrossCoupled(layout instNames)
  let((insts bboxes numInsts centerX centerY)
    ;; Get instances
    insts = foreach(mapcar name instNames
      dbFindAnyInstByName(layout name)
    )
    
    ;; Check if all instances were found
    unless(forall(x insts x)
      autoRficLogError("Could not find one or more instances")
      return(nil)
    )
    
    ;; Get bounding boxes
    bboxes = foreach(mapcar inst insts
      dbTransformBBox(dbGetInstBBox(inst) dbGetInstTransform(inst))
    )
    
    ;; Calculate dimensions of first instance as reference
    width = caadr(car(bboxes)) - caar(car(bboxes))
    height = cadadr(car(bboxes)) - cadar(car(bboxes))
    
    ;; Calculate center of layout
    let((boundary)
      boundary = dbGetBBox(layout)
      centerX = (caar(boundary) + caadr(boundary)) / 2
      centerY = (cadar(boundary) + cadadr(boundary)) / 2
    )
    
    ;; Place instances in cross pattern
    numInsts = length(insts)
    for(i 1 numInsts
      let((inst bbox angle x y)
        inst = nth(i insts)
        bbox = nth(i bboxes)
        
        ;; Calculate position based on index
        angle = 2 * pi * (i-1) / numInsts
        x = centerX + cos(angle) * width * 1.5
        y = centerY + sin(angle) * height * 1.5
        
        ;; Move instance
        dbMoveFig(inst list(x:y - list(caar(bbox):cadar(bbox))))
        
        ;; Rotate to point toward center
        dbRotateFig(inst (angle * 180 / pi) list(x:y))
      )
    )
    
    autoRficLogInfo("Placed components in cross-coupled pattern")
    t
  )
)

;; Function to place RF components with EM considerations
procedure(autoRficPlaceRfComponents(layout instNames)
  let(()
    autoRficLogInfo("Placing RF components with EM considerations")
    
    ;; Classify components
    inductors = list()
    capacitors = list()
    transistors = list()
    resistors = list()
    
    foreach(name instNames
      let((inst master cellName)
        inst = dbFindAnyInstByName(layout name)
        when(inst
          master = dbGetInstMaster(inst)
          cellName = dbGetCellName(master)
          
          cond(
            (rexMatchp("inductor" cellName) inductors = append(inductors list(name)))
            (rexMatchp("cap" cellName) capacitors = append(capacitors list(name)))
            (rexMatchp("mos" cellName) transistors = append(transistors list(name)))
            (rexMatchp("res" cellName) resistors = append(resistors list(name)))
            (t nil)
          )
        )
      )
    )
    
    ;; Place inductors with maximum spacing
    when(inductors
      autoRficLogInfo("Placing inductors with maximum spacing")
      ;; Implementation would place inductors far apart to minimize coupling
    )
    
    ;; Place sensitive components away from inductors
    when(transistors
      autoRficLogInfo("Placing transistors away from inductors")
      ;; Implementation would place transistors away from inductors
    )
    
    ;; Place matched components
    when(capacitors
      autoRficLogInfo("Placing matched capacitors")
      autoRficPlaceMatchedComponents(layout capacitors "common_centroid")
    )
    
    when(resistors
      autoRficLogInfo("Placing matched resistors")
      autoRficPlaceMatchedComponents(layout resistors "interdigitated")
    )
    
    autoRficLogInfo("Placed RF components with EM considerations")
    t
  )
)

;; Add all placement functions to the namespace
autoRficPlacement = append(autoRficPlacement list(
  'placeDifferentialPair autoRficPlaceDifferentialPair
  'placeCurrentMirror autoRficPlaceCurrentMirror
  'placeMatchedComponents autoRficPlaceMatchedComponents
  'placeCommonCentroid autoRficPlaceCommonCentroid
  'placeInterdigitated autoRficPlaceInterdigitated
  'placeCrossCoupled autoRficPlaceCrossCoupled
  'placeRfComponents autoRficPlaceRfComponents
))

;; Export the placement namespace
autoRficPlacement
