;; templates.il - Schematic templates for auto_rfic
;; This file contains functions for creating and managing schematic templates

;; Define the templates namespace
autoRficTemplates = list(nil)

;; Function to register a new template
procedure(autoRficRegisterTemplate(templateName templateFunc paramDefs)
  let(()
    autoRficTemplates = append(autoRficTemplates list(
      templateName list(
        'func templateFunc
        'params paramDefs
      )
    ))
    autoRficLogInfo(sprintf(nil "Registered template: %s" templateName))
    t
  )
)

;; Function to get a template by name
procedure(autoRficGetTemplate(templateName)
  let((idx template)
    idx = lindex(autoRficTemplates templateName)
    if(idx
      template = nth(idx+1 autoRficTemplates)
      nil
    )
  )
)

;; Function to list all available templates
procedure(autoRficListTemplates()
  let((templates i)
    templates = list()
    for(i 1 length(autoRficTemplates) 2
      templates = append(templates list(nth(i autoRficTemplates)))
    )
    templates
  )
)

;; Function to instantiate a template with parameters
procedure(autoRficInstantiateTemplate(templateName params)
  let((template templateFunc)
    template = autoRficGetTemplate(templateName)
    if(template
      prog(()
        templateFunc = template->func
        if(procedurep(templateFunc)
          templateFunc(params)
          autoRficLogError(sprintf(nil "Template function for %s is not a procedure" templateName))
        )
      )
      prog(()
        autoRficLogError(sprintf(nil "Template not found: %s" templateName))
        nil
      )
    )
  )
)

;; Define a simple LNA template
procedure(autoRficLnaTemplate(params)
  let((cv schematic)
    ;; Create a new cell view
    cv = dbOpenCellViewByType(
      params->library
      params->cell
      "schematic"
      "schematic"
      "w"
    )
    
    when(cv
      ;; Create instances based on parameters
      autoRficLogInfo("Creating LNA schematic")
      
      ;; Add transistors
      dbCreateInst(
        cv
        dbOpenCellViewByType("analogLib" "nmos4" "symbol")
        "M1"
        list(0:0)
        "R0"
        1
        list(
          list("w" params->width)
          list("l" params->length)
          list("fingers" params->fingers)
        )
      )
      
      ;; Add passive components based on parameters
      dbCreateInst(
        cv
        dbOpenCellViewByType("analogLib" "inductor" "symbol")
        "L1"
        list(0:100)
        "R0"
        1
        list(list("l" params->inductance))
      )
      
      ;; Add I/O pins
      dbCreatePin(
        cv
        dbCreateNet(cv "IN")
        "IN"
        "inputOutput"
        list(list(-100:0 -90:0))
      )
      
      dbCreatePin(
        cv
        dbCreateNet(cv "OUT")
        "OUT"
        "inputOutput"
        list(list(100:0 110:0))
      )
      
      ;; Save and close
      dbSave(cv)
      dbClose(cv)
      
      autoRficLogInfo(sprintf(nil "Created LNA schematic: %s" params->cell))
      t
    )
  )
)

;; Define a simple mixer template
procedure(autoRficMixerTemplate(params)
  let((cv schematic)
    ;; Create a new cell view
    cv = dbOpenCellViewByType(
      params->library
      params->cell
      "schematic"
      "schematic"
      "w"
    )
    
    when(cv
      ;; Create instances based on parameters
      autoRficLogInfo("Creating mixer schematic")
      
      ;; Add transistors
      dbCreateInst(
        cv
        dbOpenCellViewByType("analogLib" "nmos4" "symbol")
        "M1"
        list(0:0)
        "R0"
        1
        list(
          list("w" params->width)
          list("l" params->length)
        )
      )
      
      dbCreateInst(
        cv
        dbOpenCellViewByType("analogLib" "nmos4" "symbol")
        "M2"
        list(100:0)
        "R0"
        1
        list(
          list("w" params->width)
          list("l" params->length)
        )
      )
      
      ;; Add I/O pins
      dbCreatePin(
        cv
        dbCreateNet(cv "RF")
        "RF"
        "inputOutput"
        list(list(-100:0 -90:0))
      )
      
      dbCreatePin(
        cv
        dbCreateNet(cv "LO")
        "LO"
        "inputOutput"
        list(list(0:100 0:110))
      )
      
      dbCreatePin(
        cv
        dbCreateNet(cv "IF")
        "IF"
        "inputOutput"
        list(list(200:0 210:0))
      )
      
      ;; Save and close
      dbSave(cv)
      dbClose(cv)
      
      autoRficLogInfo(sprintf(nil "Created mixer schematic: %s" params->cell))
      t
    )
  )
)

;; Register the built-in templates
autoRficRegisterTemplate(
  "LNA"
  autoRficLnaTemplate
  list(
    list("library" "string" "Required library name")
    list("cell" "string" "Required cell name")
    list("width" "float" "Transistor width in um")
    list("length" "float" "Transistor length in um")
    list("fingers" "int" "Number of fingers")
    list("inductance" "float" "Load inductance in nH")
  )
)

autoRficRegisterTemplate(
  "Mixer"
  autoRficMixerTemplate
  list(
    list("library" "string" "Required library name")
    list("cell" "string" "Required cell name")
    list("width" "float" "Transistor width in um")
    list("length" "float" "Transistor length in um")
  )
)

;; Add all template functions to the namespace
autoRficTemplates = append(autoRficTemplates list(
  'register autoRficRegisterTemplate
  'get autoRficGetTemplate
  'list autoRficListTemplates
  'instantiate autoRficInstantiateTemplate
))

;; Export the templates namespace
autoRficTemplates
