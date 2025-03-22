;; floorplan.il - Floor planning functions for auto_rfic
;; This file contains functions for creating and optimizing layout floorplans

;; Use the floorplan namespace table already defined in main.il
;; (Don't redefine it as a list)

;; Function to create a new layout from schematic
procedure(autoRficCreateLayoutFromSchematic(library cellName)
  let((schematic layout)
    autoRficLogInfo(sprintf(nil "Creating layout for %s" cellName))
    
    ;; Open the schematic
    schematic = dbOpenCellViewByType(
      library
      cellName
      "schematic"
      nil
      "r"
    )
    
    unless(schematic
      autoRficLogError(sprintf(nil "Schematic not found: %s" cellName))
      return(nil)
    )
    
    ;; Create a new layout
    layout = dbOpenCellViewByType(
      library
      cellName
      "layout"
      "maskLayout"
      "w"
    )
    
    ;; Save and close
    dbSave(layout)
    
    autoRficLogInfo(sprintf(nil "Created layout for: %s" cellName))
    layout
  )
)

;; Function to estimate layout dimensions based on schematic
procedure(autoRficEstimateLayoutDimensions(schematic)
  let((instances totalArea width height)
    instances = dbGetInstances(schematic)
    
    ;; Estimate area based on instance count and types
    totalArea = 0
    foreach(inst instances
      let((instMaster instType)
        instMaster = dbGetInstMaster(inst)
        instType = dbGetCellName(instMaster)
        
        case(instType
          ("nmos4" totalArea = totalArea + 100)
          ("pmos4" totalArea = totalArea + 100)
          ("res" totalArea = totalArea + 50)
          ("cap" totalArea = totalArea + 200)
          ("inductor" totalArea = totalArea + 1000)
          (t totalArea = totalArea + 50)
        )
      )
    )
    
    ;; Add 50% for routing and spacing
    totalArea = totalArea * 1.5
    
    ;; Calculate width and height assuming square aspect ratio
    width = sqrt(totalArea)
    height = width
    
    list(
      'width width
      'height height
      'area totalArea
    )
  )
)

;; Function to create a basic floorplan
procedure(autoRficCreateBasicFloorplan(layout width height)
  let((boundary)
    autoRficLogInfo(sprintf(nil "Creating basic floorplan (%g x %g)" width height))
    
    ;; Create boundary
    boundary = list(
      0:0
      width:0
      width:height
      0:height
      0:0
    )
    
    ;; Create boundary shape
    dbCreateRect(
      layout
      list("boundary" "drawing")
      boundary
    )
    
    ;; Create PR boundary
    dbCreateRect(
      layout
      list("prBoundary" "drawing")
      boundary
    )
    
    boundary
  )
)

;; Function to place instances in a layout based on connectivity
procedure(autoRficPlaceInstancesByConnectivity(schematic layout)
  let((instances nets connections graph placed positions)
    autoRficLogInfo("Placing instances based on connectivity")
    
    ;; Get instances from schematic
    instances = dbGetInstances(schematic)
    
    ;; Get nets from schematic
    nets = dbGetNets(schematic)
    
    ;; Build connectivity graph
    graph = list(nil)
    foreach(inst instances
      graph = append(graph list(dbGetInstName(inst) list()))
    )
    
    ;; Add connections to graph
    foreach(net nets
      let((netName connectedInsts)
        netName = dbGetNetName(net)
        connectedInsts = dbGetNetInstances(net)
        
        ;; Add connections between all instances on this net
        for(i 1 length(connectedInsts)
          for(j i+1 length(connectedInsts)
            let((inst1 inst2 idx1 idx2)
              inst1 = dbGetInstName(nth(i connectedInsts))
              inst2 = dbGetInstName(nth(j connectedInsts))
              
              ;; Add to graph
              idx1 = lindex(graph inst1)
              idx2 = lindex(graph inst2)
              
              when(idx1
                graph = replaceItem(
                  append(nth(idx1+1 graph) list(inst2))
                  idx1+1
                  graph
                )
              )
              
              when(idx2
                graph = replaceItem(
                  append(nth(idx2+1 graph) list(inst1))
                  idx2+1
                  graph
                )
              )
            )
          )
        )
      )
    )
    
    ;; Estimate layout dimensions
    dimensions = autoRficEstimateLayoutDimensions(schematic)
    width = dimensions->width
    height = dimensions->height
    
    ;; Create basic floorplan
    autoRficCreateBasicFloorplan(layout width height)
    
    ;; Place instances using a simple force-directed algorithm
    positions = list(nil)
    placed = list()
    
    ;; Initial random placement
    foreach(inst instances
      let((instName x y)
        instName = dbGetInstName(inst)
        x = random(width)
        y = random(height)
        positions = append(positions list(instName list(x y)))
        placed = append(placed list(instName))
      )
    )
    
    ;; Optimize positions (simplified force-directed placement)
    for(iter 1 10
      foreach(inst instances
        let((instName idx connections pos newX newY)
          instName = dbGetInstName(inst)
          idx = lindex(graph instName)
          connections = nth(idx+1 graph)
          
          ;; Calculate forces
          pos = nth(1+lindex(positions instName) positions)
          newX = car(pos)
          newY = cadr(pos)
          
          ;; Attraction to connected instances
          foreach(conn connections
            let((connIdx connPos)
              connIdx = lindex(positions conn)
              when(connIdx
                connPos = nth(connIdx+1 positions)
                newX = newX + 0.1 * (car(connPos) - newX)
                newY = newY + 0.1 * (cadr(connPos) - newY)
              )
            )
          )
          
          ;; Repulsion from all other instances
          foreach(otherInst instances
            let((otherName otherIdx otherPos dx dy dist)
              otherName = dbGetInstName(otherInst)
              unless(otherName == instName
                otherIdx = lindex(positions otherName)
                when(otherIdx
                  otherPos = nth(otherIdx+1 positions)
                  dx = newX - car(otherPos)
                  dy = newY - cadr(otherPos)
                  dist = max(1.0 sqrt(dx*dx + dy*dy))
                  newX = newX + 100.0 * dx / (dist * dist)
                  newY = newY + 100.0 * dy / (dist * dist)
                )
              )
            )
          )
          
          ;; Keep within bounds
          newX = max(10.0 min(width-10.0 newX))
          newY = max(10.0 min(height-10.0 newY))
          
          ;; Update position
          positions = replaceItem(
            list(newX newY)
            1+lindex(positions instName)
            positions
          )
        )
      )
    )
    
    ;; Create instances in layout
    foreach(inst instances
      let((instName instMaster instType idx pos x y)
        instName = dbGetInstName(inst)
        instMaster = dbGetInstMaster(inst)
        instType = dbGetCellName(instMaster)
        
        idx = lindex(positions instName)
        when(idx
          pos = nth(idx+1 positions)
          x = car(pos)
          y = cadr(pos)
          
          ;; Create instance in layout
          dbCreateInst(
            layout
            dbGetLibCellView(instMaster)
            instName
            list(x:y)
            "R0"
            1
          )
        )
      )
    )
    
    autoRficLogInfo("Placed instances based on connectivity")
    t
  )
)

;; Function to optimize a floorplan for RF performance
procedure(autoRficOptimizeFloorplan(layout @optional (strategy "performance"))
  let(()
    autoRficLogInfo(sprintf(nil "Optimizing floorplan using strategy: %s" strategy))
    
    case(strategy
      ("performance"
        ;; Optimize for performance - prioritize signal path symmetry
        autoRficLogInfo("Applying performance optimization strategy")
        ;; Implementation would enforce symmetry, minimize critical path lengths, etc.
      )
      ("density"
        ;; Optimize for density - prioritize compact layout
        autoRficLogInfo("Applying density optimization strategy")
        ;; Implementation would minimize area, allow asymmetry, etc.
      )
      ("balanced"
        ;; Balanced approach
        autoRficLogInfo("Applying balanced optimization strategy")
        ;; Implementation would balance performance and density
      )
      (t
        autoRficLogError(sprintf(nil "Unknown floorplan strategy: %s" strategy))
      )
    )
    
    t
  )
)

;; Function to create a complete layout from schematic
procedure(autoRficGenerateLayout(library cellName)
  let((schematic layout)
    autoRficLogInfo(sprintf(nil "Generating layout for %s" cellName))
    
    ;; Open the schematic
    schematic = dbOpenCellViewByType(
      library
      cellName
      "schematic"
      nil
      "r"
    )
    
    unless(schematic
      autoRficLogError(sprintf(nil "Schematic not found: %s" cellName))
      return(nil)
    )
    
    ;; Create a new layout
    layout = autoRficCreateLayoutFromSchematic(library cellName)
    
    ;; Place instances
    autoRficPlaceInstancesByConnectivity(schematic layout)
    
    ;; Optimize floorplan
    strategy = autoRficGetParameter('defaultFloorplanStrategy "balanced")
    autoRficOptimizeFloorplan(layout strategy)
    
    ;; Save and close
    dbSave(layout)
    dbClose(layout)
    dbClose(schematic)
    
    autoRficLogInfo(sprintf(nil "Layout generation complete for: %s" cellName))
    t
  )
)

;; Add all floorplan functions to the namespace
when(boundp('autoRficFloorplan)
    autoRficFloorplan['createLayout] = 'autoRficCreateLayoutFromSchematic
    autoRficFloorplan['estimateDimensions] = 'autoRficEstimateLayoutDimensions
    autoRficFloorplan['createBasic] = 'autoRficCreateBasicFloorplan
    autoRficFloorplan['placeInstances] = 'autoRficPlaceInstancesByConnectivity
    autoRficFloorplan['optimize] = 'autoRficOptimizeFloorplan
    autoRficFloorplan['generate] = 'autoRficGenerateLayout
)

;; Export the floorplan namespace
autoRficFloorplan
