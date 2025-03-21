;; templates.il - Schematic templates for auto_rfic
;; This file contains functions for creating and managing schematic templates

;; Initialize the templates namespace
unless(boundp('autoRficTemplates)
    autoRficTemplates = makeTable("templates" nil)
)

;; Initialize the templates registry
unless(boundp('autoRficTemplateRegistry)
    autoRficTemplateRegistry = makeTable("registry" nil)
)

;; Function to register a new template
defun(autoRficRegisterTemplate (templateName templateFunc paramDefs)
    let((templateInfo templateSymbol)
        ;; Ensure templateName is a symbol
        templateSymbol = if(stringp(templateName)
                           car(parseString(strcat("(" templateName ")")))
                           templateName)
        
        ;; Create template info table
        templateInfo = makeTable("templateInfo")
        templateInfo['func] = templateFunc
        templateInfo['params] = paramDefs
        
        ;; Store in registry using symbol key
        autoRficTemplateRegistry[templateSymbol] = templateInfo
        
        autoRficLogInfo(sprintf(nil "Registered template: %L" templateSymbol))
        t
    )
)

;; Function to get a template by name
defun(autoRficGetTemplate (templateName)
    get(autoRficTemplateRegistry templateName)
)

;; Function to list all available templates
defun(autoRficListTemplates ()
    getTableKeys(autoRficTemplateRegistry)
)

;; Function to instantiate a template with parameters
defun(autoRficInstantiateTemplate (templateName params)
    let((template templateFunc)
        template = autoRficGetTemplate(templateName)
        if(template
            prog(()
                templateFunc = template['func]
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
    'autoRficLnaTemplate
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
    'autoRficMixerTemplate
    list(
        list("library" "string" "Required library name")
        list("cell" "string" "Required cell name")
        list("width" "float" "Transistor width in um")
        list("length" "float" "Transistor length in um")
    )
)

;; Add all template functions to the namespace
autoRficTemplates['register] = 'autoRficRegisterTemplate
autoRficTemplates['get] = 'autoRficGetTemplate
autoRficTemplates['list] = 'autoRficListTemplates
autoRficTemplates['instantiate] = 'autoRficInstantiateTemplate

;; Export the templates namespace
autoRficTemplates
