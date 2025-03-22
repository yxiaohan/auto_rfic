;; generator.il - Schematic generation functions for auto_rfic
;; This file contains functions for generating schematics from templates and specifications

;; Initialize the generator namespace
unless(boundp('autoRficGenerator)
    autoRficGenerator = makeTable("generator" nil)
)

;; Function to generate a schematic from a template
procedure(autoRficGenerateSchematic(template params)
    let((templateName templateFunc result)
        ;; Get template function
        when(tablep(template)
            templateFunc = getq(template 'func)
            templateName = getq(template 'name)
            
            if(procedurep(templateFunc) then
                autoRficLogInfo(sprintf(nil "Generating schematic from template: %L" templateName))
                result = apply(templateFunc list(params))
                unless(result
                    autoRficLogError(sprintf(nil "Failed to generate schematic from template: %L" templateName))
                )
            else
                autoRficLogError("Invalid template function")
            )
        else
            autoRficLogError("Invalid template object")
        )
        result
    )
)

;; Function to generate a hierarchical schematic
procedure(autoRficGenerateHierarchicalSchematic(topCellName components connections)
  let((cv library)
    ;; Use default design library if not specified
    library = autoRficGetParameter('designLibrary "auto_rfic_designs")
    
    ;; Create top-level cell view
    cv = dbOpenCellViewByType(
      library
      topCellName
      "schematic"
      "schematic"
      "w"
    )
    
    when(cv
      ;; Create instances for each component
      foreach(comp components
        let((instName template params x y orient)
          instName = comp->name
          template = comp->template
          params = comp->params
          x = comp->x
          y = comp->y
          orient = if(member('orient comp) comp->orient "R0")
          
          ;; Generate the component schematic if it doesn't exist
          unless(ddGetObj(library instName)
            autoRficGenerateSchematic(template instName params)
          )
          
          ;; Create instance of the component
          dbCreateInst(
            cv
            dbOpenCellViewByType(library instName "symbol")
            instName
            list(x:y)
            orient
            1
          )
        )
      )
      
      ;; Create connections
      foreach(conn connections
        let((net fromInst fromPin toInst toPin)
          net = conn->net
          fromInst = conn->from->inst
          fromPin = conn->from->pin
          toInst = conn->to->inst
          toPin = conn->to->pin
          
          ;; Create the net
          dbCreateNet(cv net)
          
          ;; Connect the instances
          schCreateWire(
            cv
            "route"
            "full"
            list(
              dbGetInstPinLoc(cv fromInst fromPin)
              dbGetInstPinLoc(cv toInst toPin)
            )
            0.1
          )
        )
      )
      
      ;; Save and close
      dbSave(cv)
      dbClose(cv)
      
      autoRficLogInfo(sprintf(nil "Created hierarchical schematic: %s" topCellName))
      t
    )
  )
)

;; Function to create a symbol from schematic
procedure(autoRficCreateSymbolFromSchematic(library cellName)
  let((schematic symbol)
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
    
    ;; Create a symbol
    symbol = dbOpenCellViewByType(
      library
      cellName
      "symbol"
      "symbolGen"
      "w"
    )
    
    ;; Generate symbol from schematic
    schSymbolGen(
      schematic
      symbol
      nil
      nil
      nil
      nil
      nil
      "symbolGen"
    )
    
    ;; Save and close
    dbSave(symbol)
    dbClose(symbol)
    dbClose(schematic)
    
    autoRficLogInfo(sprintf(nil "Created symbol for: %s" cellName))
    t
  )
)

;; Add generator functions to namespace with proper symbol handling
when(boundp('autoRficGenerator)
    autoRficGenerator['generateSchematic] = 'autoRficGenerateSchematic
    autoRficGenerator['generateHierarchical] = 'autoRficGenerateHierarchicalSchematic
    autoRficGenerator['createSymbol] = 'autoRficCreateSymbolFromSchematic
)

;; Export the generator namespace
autoRficGenerator
