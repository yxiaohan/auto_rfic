;; gui.il - GUI components for auto_rfic
;; This file contains functions for creating and managing GUI elements

;; Load required packages
load("axlUIBasic")
load("axlForm")

;; Define the GUI namespace
autoRficGui = list(nil)

;; Function to create a simple message dialog
procedure(autoRficShowMessage(title message @optional (type "info"))
  let((icon)
    case(type
      ("info" icon = "information")
      ("warning" icon = "warning")
      ("error" icon = "error")
      (t icon = "information")
    )
    axlUIDisplayDialog(message title icon "OK" nil)
  )
)

;; Function to create a confirmation dialog
procedure(autoRficConfirmDialog(title message @optional (defaultButton "OK"))
  let((result)
    result = axlUIYesNo(message title defaultButton)
    result == t
  )
)

;; Function to create a simple input dialog
procedure(autoRficInputDialog(title prompt @optional defaultValue)
  let((result)
    result = axlEnterString(prompt defaultValue)
    if(stringp(result) && result != "" result nil)
  )
)

;; Function to create a progress bar
procedure(autoRficCreateProgressBar(title maxValue)
  let((form)
    form = axlFormCreate(
      title
      list(
        list("pBar" "progressBar" "Progress" ?max maxValue ?min 0 ?value 0)
        list("status" "text" "Starting..." ?editable nil)
        list("cancel" "button" "Cancel")
      )
      ?buttonLayout "horizontal"
    )
    axlFormDisplay(form)
    form
  )
)

;; Function to update a progress bar
procedure(autoRficUpdateProgressBar(form value @optional statusText)
  let(()
    axlFormSetField(form "pBar" value)
    when(stringp(statusText)
      axlFormSetField(form "status" statusText)
    )
    axlFlushEvents()
  )
)

;; Function to close a progress bar
procedure(autoRficCloseProgressBar(form)
  axlFormClose(form)
)

;; Function to create a parameter input form
procedure(autoRficParameterForm(title paramList @optional (callback nil))
  let((form fields result)
    ;; Create field list from parameter list
    fields = foreach(mapcar param paramList
      list(car(param) "string" cadr(param) ?defValue caddr(param))
    )
    
    ;; Add buttons
    fields = append(fields list(
      list("OK" "button" "OK")
      list("Cancel" "button" "Cancel")
    ))
    
    ;; Create and display form
    form = axlFormCreate(title fields ?buttonLayout "horizontal")
    result = axlFormDisplay(form)
    
    ;; Process result
    if(result == t
      let((values)
        ;; Collect values from form
        values = foreach(mapcar param paramList
          list(car(param) axlFormGetField(form car(param)))
        )
        ;; Call callback if provided
        if(callback callback(values) values)
      )
      nil
    )
  )
)

;; Add all GUI functions to the namespace
autoRficGui = append(autoRficGui list(
  'showMessage autoRficShowMessage
  'confirmDialog autoRficConfirmDialog
  'inputDialog autoRficInputDialog
  'createProgressBar autoRficCreateProgressBar
  'updateProgressBar autoRficUpdateProgressBar
  'closeProgressBar autoRficCloseProgressBar
  'parameterForm autoRficParameterForm
))

;; Export the GUI namespace
autoRficGui
