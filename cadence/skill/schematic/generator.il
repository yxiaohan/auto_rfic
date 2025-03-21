;; generator.il - Schematic generation functions for auto_rfic
;; This file contains functions for generating schematics from templates and specifications

;; Define the generator namespace
autoRficGenerator = list(nil)

;; Function to generate a schematic from a template
procedure(autoRficGenerateSchematic(templateName cellName @optional params)
  let((template paramDefs mergedParams library)
    ;; Get the template
    template = autoRficGetTemplate(templateName)
    unless(template
      autoRficLogError(sprintf(nil "Template not found: %s" templateName))
      return(nil)
    )
    
    ;; Get parameter definitions
    paramDefs = template->params
    
    ;; Use default design library if not specified
    library = autoRficGetParameter('designLibrary "auto_rfic_designs")
    
    ;; Create default parameters
    mergedParams = list(
      'library library
      'cell cellName
    )
    
    ;; Merge with provided parameters
    when(boundp('params)
      foreach(param params
        mergedParams = append(mergedParams list(car(param) cadr(param)))
      )
    )
    
    ;; Instantiate the template
    autoRficLogInfo(sprintf(nil "Generating schematic %s using template %s" cellName templateName))
    autoRficInstantiateTemplate(templateName mergedParams)
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

;; Add all generator functions to the namespace
autoRficGenerator = append(autoRficGenerator list(
  'generateSchematic autoRficGenerateSchematic
  'generateHierarchical autoRficGenerateHierarchicalSchematic
  'createSymbol autoRficCreateSymbolFromSchematic
))

;; Export the generator namespace
autoRficGenerator
