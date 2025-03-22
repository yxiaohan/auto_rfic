;; templates.il - Schematic templates for auto_rfic
;; This file contains functions for creating and managing schematic templates

;; Ensure logging module is available
unless(boundp('autoRficLogging)
    error("Logging module not loaded. Please load logging.il before templates.il")
)

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
    let((templateSymbol templateInfo success)
        success = nil
        
        ;; Convert template name to symbol and validate
        templateSymbol = cond(
            (symbolp(templateName) templateName)
            (stringp(templateName) stringToSymbol(templateName))
            (t nil)
        )
        
        unless(templateSymbol
            autoRficLogError(sprintf(nil "Invalid template name type: %L" templateName))
            return(nil)
        )
        
        ;; Create template info table with proper symbol keys
        templateInfo = makeTable("templateInfo" nil)
        when(templateInfo
            templateInfo['func] = templateFunc
            templateInfo['params] = paramDefs
            
            ;; Store in registry using proper symbol handling
            when(and(boundp('autoRficTemplateRegistry) tablep(autoRficTemplateRegistry))
                autoRficTemplateRegistry[templateSymbol] = templateInfo
                autoRficLogInfo(sprintf(nil "Registered template: %L" templateSymbol))
                success = t
            else
                autoRficLogError("Template registry not properly initialized")
            )
        )
        success
    )
)

;; Function to get a template by name
defun(autoRficGetTemplate (templateName)
    let((template templateSymbol)
        ;; Convert string to symbol if needed
        when(stringp(templateName)
            templateSymbol = stringToSymbol(templateName)
        else
            templateSymbol = templateName
        )
        
        unless(symbolp(templateSymbol)
            autoRficLogError(sprintf(nil "Invalid template name: %L - must be symbol or string" templateName))
            return(nil)
        )
        
        ;; In SKILL, when accessing table entries, ensure the table itself exists and is a table
        when(and(boundp('autoRficTemplateRegistry) tablep(autoRficTemplateRegistry))
            template = get(autoRficTemplateRegistry templateSymbol)
            unless(template
                autoRficLogError(sprintf(nil "Template not found: %L" templateSymbol))
            )
        else
            autoRficLogError("Template registry not initialized properly")
            template = nil
        )
        template
    )
)

;; Function to list all available templates
defun(autoRficListTemplates ()
    getTableKeys(autoRficTemplateRegistry)
)

;; Function to instantiate a template with parameters
defun(autoRficInstantiateTemplate (templateName params)
    let((template templateFunc templateSymbol)
        ;; Convert template name to symbol and validate
        templateSymbol = cond(
            (symbolp(templateName) templateName)
            (stringp(templateName) stringToSymbol(templateName))
            (t nil)
        )

        unless(templateSymbol
            autoRficLogError(sprintf(nil "Invalid template name type: %L" templateName))
            return(nil)
        )

        ;; Get template using proper symbol handling
        template = when(and(boundp('autoRficTemplateRegistry) tablep(autoRficTemplateRegistry))
            getq(autoRficTemplateRegistry templateSymbol)
        )

        if(template then
            ;; Get function using proper table access
            if(tablep(template) then
                templateFunc = getq(template 'func)
                if(procedurep(templateFunc) then
                    apply(templateFunc list(params))
                else
                    autoRficLogError(sprintf(nil "Invalid template function for %L" templateSymbol))
                    nil
                )
            else
                autoRficLogError(sprintf(nil "Invalid template data structure for %L" templateSymbol))
                nil
            )
        else
            autoRficLogError(sprintf(nil "Template not found: %L" templateSymbol))
            nil
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
let((result templateInfo)
    ;; First template
    templateInfo = makeTable("LNATemplate" nil)
    templateInfo['func] = 'autoRficLnaTemplate
    templateInfo['params] = list(
        list('library "string" "Required library name")
        list('cell "string" "Required cell name")
        list('width "float" "Transistor width in um")
        list('length "float" "Transistor length in um")
        list('fingers "int" "Number of fingers")
        list('inductance "float" "Load inductance in nH")
    )
    when(tablep(autoRficTemplateRegistry)
        autoRficTemplateRegistry['LNA] = templateInfo
    )

    ;; Second template
    templateInfo = makeTable("MixerTemplate" nil)
    templateInfo['func] = 'autoRficMixerTemplate
    templateInfo['params] = list(
        list('library "string" "Required library name")
        list('cell "string" "Required cell name")
        list('width "float" "Transistor width in um")
        list('length "float" "Transistor length in um")
    )
    when(tablep(autoRficTemplateRegistry)
        autoRficTemplateRegistry['Mixer] = templateInfo
    )
)

;; Add template functions to namespace with proper symbol handling
when(and(boundp('autoRficTemplates) tablep(autoRficTemplates))
    autoRficTemplates['register] = 'autoRficRegisterTemplate
    autoRficTemplates['get] = 'autoRficGetTemplate
    autoRficTemplates['list] = 'autoRficListTemplates
    autoRficTemplates['instantiate] = 'autoRficInstantiateTemplate
)

;; Export the templates namespace
autoRficTemplates
