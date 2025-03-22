;; gui.il - GUI components for auto_rfic
;; This file contains functions for creating and managing GUI elements

;; Initialize the GUI namespace
unless(boundp('autoRficGui)
    autoRficGui = makeTable("gui" nil)
)

;; Function to create a simple message dialog
defun(autoRficShowMessage (title message @optional (type "info"))
    let((icon)
        case(type
            ("info" icon = "information")
            ("warning" icon = "warning")
            ("error" icon = "error")
            (t icon = "information")
        )
        hiDisplayDialog(message title icon '("OK"))
    )
)

;; Function to create a confirmation dialog
defun(autoRficConfirmDialog (title message @optional (defaultButton "OK"))
    let((result)
        result = hiDisplayDialog(message title "question" '("Yes" "No"))
        result == "Yes"
    )
)

;; Function to create a simple input dialog
defun(autoRficInputDialog (title prompt @optional defaultValue)
    let((result)
        result = hiCreateStringField(
            ?name "inputField"
            ?prompt prompt
            ?value defaultValue
            ?callback nil
        )
        if(stringp(result) && result != "" result nil)
    )
)

;; Function to create a progress bar
defun(autoRficCreateProgressBar (title maxValue)
    let((form)
        form = hiCreateProgressBar(
            ?caption title
            ?totalSteps maxValue
            ?initialStep 0
        )
        form
    )
)

;; Function to update a progress bar
defun(autoRficUpdateProgressBar (form value @optional statusText)
    let(()
        hiSetProgressBarValue(form value)
        when(stringp(statusText)
            hiSetProgressBarStatus(form statusText)
        )
    )
)

;; Function to close a progress bar
defun(autoRficCloseProgressBar (form)
    hiDeleteProgressBar(form)
)

;; Function to create a parameter input form
defun(autoRficParameterForm (title paramList @optional (callback nil))
    let((form fields result)
        ;; Create field list from parameter list
        fields = foreach(mapcar param paramList
            hiCreateStringField(
                ?name car(param)
                ?prompt cadr(param)
                ?value caddr(param)
            )
        )
        
        ;; Create and display form
        form = hiCreateAppForm(
            ?name title
            ?callback callback
            ?fields fields
            ?buttons '("OK" "Cancel")
        )
        
        result = hiDisplayForm(form)
        
        ;; Process result
        if(result == "OK"
            let((values)
                ;; Collect values from form
                values = foreach(mapcar param paramList
                    list(car(param) hiGetFormFieldValue(form car(param)))
                )
                ;; Call callback if provided
                if(callback callback(values) values)
            )
            nil
        )
    )
)

;; GUI refresh trigger function
procedure(autoRficGuiRefreshTrigger(cellView)
  let((cellName viewName libName)
    when(cellView
      cellName = dbGetCellName(cellView)
      viewName = dbGetViewName(cellView)
      libName = dbGetLibName(cellView)
      
      autoRficLogInfo(sprintf(nil "GUI refreshed for: %s %s %s" libName cellName viewName))
      
      ;; Perform any GUI refresh actions here
      ;; For example, update custom overlays or highlighting
    )
    t
  )
)

;; Add all GUI functions to the namespace
autoRficGui['showMessage] = 'autoRficShowMessage
autoRficGui['confirmDialog] = 'autoRficConfirmDialog
autoRficGui['inputDialog] = 'autoRficInputDialog
autoRficGui['createProgressBar] = 'autoRficCreateProgressBar
autoRficGui['updateProgressBar] = 'autoRficUpdateProgressBar
autoRficGui['closeProgressBar] = 'autoRficCloseProgressBar
autoRficGui['parameterForm] = 'autoRficParameterForm

;; Export the GUI namespace
autoRficGui
