;; routing.il - Signal routing for auto_rfic
;; This file contains functions for routing signals in RF layouts

;; Define the routing namespace
autoRficRouting = list(nil)

;; Function to route a net between two points
procedure(autoRficRouteNet(layout netName startPoint endPoint @optional (width 1.0) (layer "M1"))
  let((path)
    autoRficLogInfo(sprintf(nil "Routing net %s from %L to %L" netName startPoint endPoint))
    
    ;; Create path points
    path = list(startPoint endPoint)
    
    ;; Create path
    dbCreatePath(
      layout
      list(layer "drawing")
      path
      width
      list("flat" "extend" "truncate")
    )
    
    autoRficLogInfo(sprintf(nil "Routed net %s" netName))
    t
  )
)

;; Function to route a net with multiple segments
procedure(autoRficRouteNetWithSegments(layout netName points @optional (width 1.0) (layer "M1"))
  let(()
    autoRficLogInfo(sprintf(nil "Routing net %s with multiple segments" netName))
    
    ;; Create path
    dbCreatePath(
      layout
      list(layer "drawing")
      points
      width
      list("flat" "extend" "truncate")
    )
    
    autoRficLogInfo(sprintf(nil "Routed net %s with multiple segments" netName))
    t
  )
)

;; Function to route differential signals
procedure(autoRficRouteDifferential(layout posNetName negNetName startPoints endPoints 
                                   @optional (width 1.0) (spacing 2.0) (layer "M1"))
  let((posStart posEnd negStart negEnd)
    autoRficLogInfo(sprintf(nil "Routing differential pair %s/%s" posNetName negNetName))
    
    ;; Extract points
    posStart = car(startPoints)
    posEnd = car(endPoints)
    negStart = cadr(startPoints)
    negEnd = cadr(endPoints)
    
    ;; Check if points are parallel
    unless(and 
           (abs(cadr(posStart) - cadr(negStart)) == spacing)
           (abs(cadr(posEnd) - cadr(negEnd)) == spacing)
      autoRficLogError("Differential pair points are not properly spaced")
      return(nil)
    )
    
    ;; Route positive net
    autoRficRouteNet(layout posNetName posStart posEnd width layer)
    
    ;; Route negative net
    autoRficRouteNet(layout negNetName negStart negEnd width layer)
    
    autoRficLogInfo(sprintf(nil "Routed differential pair %s/%s" posNetName negNetName))
    t
  )
)

;; Function to create a via between two layers
procedure(autoRficCreateVia(layout point @optional (bottomLayer "M1") (topLayer "M2"))
  let(()
    autoRficLogInfo(sprintf(nil "Creating via at %L from %s to %s" point bottomLayer topLayer))
    
    ;; Create via
    dbCreateVia(
      layout
      dbGetViaDefByName(sprintf(nil "%s_%s" bottomLayer topLayer))
      point
      "R0"
      1
      list(t t)
    )
    
    autoRficLogInfo("Created via")
    t
  )
)

;; Function to route a net with layer changes
procedure(autoRficRouteMultiLayer(layout netName points layers @optional (width 1.0))
  let(()
    autoRficLogInfo(sprintf(nil "Routing multi-layer net %s" netName))
    
    ;; Check if points and layers have compatible lengths
    unless(length(points) == (length(layers) + 1)
      autoRficLogError("Number of points must be one more than number of layers")
      return(nil)
    )
    
    ;; Route each segment on its layer
    for(i 1 length(layers)
      let((startPoint endPoint layer)
        startPoint = nth(i points)
        endPoint = nth(i+1 points)
        layer = nth(i layers)
        
        ;; Route segment
        autoRficRouteNet(layout netName startPoint endPoint width layer)
        
        ;; Create via at end point if not the last segment
        when(i < length(layers)
          autoRficCreateVia(layout endPoint layer nth(i+1 layers))
        )
      )
    )
    
    autoRficLogInfo(sprintf(nil "Routed multi-layer net %s" netName))
    t
  )
)

;; Function to route power nets
procedure(autoRficRoutePowerNets(layout)
  let((vddNet gndNet vddInsts gndInsts)
    autoRficLogInfo("Routing power nets")
    
    ;; Find VDD and GND nets
    vddNet = dbFindNetByName(layout "VDD")
    gndNet = dbFindNetByName(layout "GND")
    
    unless(and vddNet gndNet
      autoRficLogError("Could not find VDD or GND nets")
      return(nil)
    )
    
    ;; Find instances connected to VDD and GND
    vddInsts = dbGetNetInstances(vddNet)
    gndInsts = dbGetNetInstances(gndNet)
    
    ;; Route VDD net
    when(vddInsts
      autoRficLogInfo("Routing VDD net")
      
      ;; Create power ring or grid for VDD
      ;; This is a simplified placeholder - real implementation would be more complex
      let((boundary width)
        boundary = dbGetBBox(layout)
        width = 5.0  ;; Wide power trace
        
        ;; Create power ring
        dbCreateRect(
          layout
          list("M1" "drawing")
          list(
            list(caar(boundary) cadar(boundary))
            list(caadr(boundary) cadar(boundary))
            list(caadr(boundary) cadar(boundary) + width)
            list(caar(boundary) cadar(boundary) + width)
          )
        )
      )
    )
    
    ;; Route GND net
    when(gndInsts
      autoRficLogInfo("Routing GND net")
      
      ;; Create ground plane or grid
      ;; This is a simplified placeholder - real implementation would be more complex
      let((boundary width)
        boundary = dbGetBBox(layout)
        width = 5.0  ;; Wide ground trace
        
        ;; Create ground ring
        dbCreateRect(
          layout
          list("M1" "drawing")
          list(
            list(caar(boundary) cadadr(boundary) - width)
            list(caadr(boundary) cadadr(boundary) - width)
            list(caadr(boundary) cadadr(boundary))
            list(caar(boundary) cadadr(boundary))
          )
        )
      )
    )
    
    autoRficLogInfo("Routed power nets")
    t
  )
)

;; Function to route RF signal paths
procedure(autoRficRouteRfSignals(layout)
  let((nets)
    autoRficLogInfo("Routing RF signal paths")
    
    ;; Find all nets
    nets = dbGetNets(layout)
    
    ;; Filter for RF signal nets (simplified approach)
    rfNets = list()
    foreach(net nets
      let((netName)
        netName = dbGetNetName(net)
        when(or (rexMatchp("RF" netName) 
                 rexMatchp("LO" netName)
                 rexMatchp("IF" netName)
                 rexMatchp("IN" netName)
                 rexMatchp("OUT" netName))
          rfNets = append(rfNets list(net))
        )
      )
    )
    
    ;; Route each RF net
    foreach(net rfNets
      let((netName insts pins endpoints)
        netName = dbGetNetName(net)
        autoRficLogInfo(sprintf(nil "Routing RF net: %s" netName))
        
        ;; Get instances and pins connected to this net
        insts = dbGetNetInstances(net)
        pins = dbGetNetTerms(net)
        
        ;; Extract endpoints
        endpoints = list()
        foreach(pin pins
          let((pinFig pinLoc)
            pinFig = dbGetTermFigs(pin)
            when(pinFig
              pinLoc = dbGetFigCenterXY(car(pinFig))
              endpoints = append(endpoints list(pinLoc))
            )
          )
        )
        
        ;; Route between endpoints
        when(length(endpoints) >= 2
          for(i 1 length(endpoints)-1
            autoRficRouteNet(
              layout
              netName
              nth(i endpoints)
              nth(i+1 endpoints)
              2.0  ;; Wider traces for RF signals
              "M2"  ;; Higher metal layer for RF signals
            )
          )
        )
      )
    )
    
    autoRficLogInfo("Routed RF signal paths")
    t
  )
)

;; Function to add shielding to sensitive nets
procedure(autoRficAddShielding(layout netName @optional (shieldLayer "M1"))
  let((net paths)
    autoRficLogInfo(sprintf(nil "Adding shielding to net: %s" netName))
    
    ;; Find the net
    net = dbFindNetByName(layout netName)
    unless(net
      autoRficLogError(sprintf(nil "Net not found: %s" netName))
      return(nil)
    )
    
    ;; Find paths for this net
    paths = dbGetNetShapes(net)
    
    ;; Add shielding around each path
    foreach(path paths
      let((bbox width)
        bbox = dbGetBBox(path)
        width = 2.0  ;; Shield width
        
        ;; Create shield on both sides of the path
        ;; This is a simplified approach - real implementation would be more complex
        dbCreateRect(
          layout
          list(shieldLayer "drawing")
          list(
            list(caar(bbox) - width cadar(bbox) - width)
            list(caar(bbox) - width cadadr(bbox) + width)
            list(caar(bbox) cadadr(bbox) + width)
            list(caar(bbox) cadar(bbox) - width)
          )
        )
        
        dbCreateRect(
          layout
          list(shieldLayer "drawing")
          list(
            list(caadr(bbox) cadar(bbox) - width)
            list(caadr(bbox) cadadr(bbox) + width)
            list(caadr(bbox) + width cadadr(bbox) + width)
            list(caadr(bbox) + width cadar(bbox) - width)
          )
        )
      )
    )
    
    autoRficLogInfo(sprintf(nil "Added shielding to net: %s" netName))
    t
  )
)

;; Function to route all nets in a layout
procedure(autoRficRouteAllNets(layout @optional (strategy "performance"))
  let(()
    autoRficLogInfo(sprintf(nil "Routing all nets using strategy: %s" strategy))
    
    ;; Route power nets first
    autoRficRoutePowerNets(layout)
    
    ;; Route RF signals
    autoRficRouteRfSignals(layout)
    
    ;; Route remaining nets
    nets = dbGetNets(layout)
    foreach(net nets
      let((netName)
        netName = dbGetNetName(net)
        
        ;; Skip already routed nets
        unless(or (netName == "VDD")
                  (netName == "GND")
                  (rexMatchp("RF" netName) 
                   rexMatchp("LO" netName)
                   rexMatchp("IF" netName)
                   rexMatchp("IN" netName)
                   rexMatchp("OUT" netName)))
          
          autoRficLogInfo(sprintf(nil "Routing net: %s" netName))
          
          ;; Get instances and pins connected to this net
          insts = dbGetNetInstances(net)
          pins = dbGetNetTerms(net)
          
          ;; Extract endpoints
          endpoints = list()
          foreach(pin pins
            let((pinFig pinLoc)
              pinFig = dbGetTermFigs(pin)
              when(pinFig
                pinLoc = dbGetFigCenterXY(car(pinFig))
                endpoints = append(endpoints list(pinLoc))
              )
            )
          )
          
          ;; Route between endpoints
          when(length(endpoints) >= 2
            for(i 1 length(endpoints)-1
              autoRficRouteNet(
                layout
                netName
                nth(i endpoints)
                nth(i+1 endpoints)
              )
            )
          )
        )
      )
    )
    
    ;; Add shielding if enabled
    when(autoRficGetParameter('shieldingEnabled t)
      ;; Shield sensitive nets
      autoRficAddShielding(layout "RF_IN")
      autoRficAddShielding(layout "LO")
    )
    
    autoRficLogInfo("Completed routing all nets")
    t
  )
)

;; Add all routing functions to the namespace
autoRficRouting = append(autoRficRouting list(
  'routeNet autoRficRouteNet
  'routeNetWithSegments autoRficRouteNetWithSegments
  'routeDifferential autoRficRouteDifferential
  'createVia autoRficCreateVia
  'routeMultiLayer autoRficRouteMultiLayer
  'routePowerNets autoRficRoutePowerNets
  'routeRfSignals autoRficRouteRfSignals
  'addShielding autoRficAddShielding
  'routeAllNets autoRficRouteAllNets
))

;; Export the routing namespace
autoRficRouting
