# SKILL UI API Reference

## Form Functions

### hiCreateAppForm
Creates an application form window.
```skill
form = hiCreateAppForm(
  ?name           symbolValue     ; Unique identifier for the form
  ?formTitle      "string"       ; Title displayed in form window
  ?callback       "procName"     ; Callback procedure (optional)
  ?buttonLayout   'OKCancel      ; Button layout ('OK, 'OKCancel, 'OKCancelApply etc)
  ?unmapAfterCB   t/nil         ; Whether to unmap form after callback
)
```

### hiCreateCyclicField
Creates a dropdown selection field.
```skill
field = hiCreateCyclicField(
  ?parent         formObj        ; Parent form object
  ?name           symbolValue    ; Field identifier
  ?prompt         "string"       ; Label text
  ?choices        listOfStrings  ; List of choices to display
  ?value          defaultValue   ; Initial selected value
)
```

### hiCreateStringField
Creates a text input field.
```skill
field = hiCreateStringField(
  ?parent         formObj        ; Parent form object
  ?name           symbolValue    ; Field identifier
  ?prompt         "string"       ; Label text
  ?value          "string"       ; Initial value
  ?editable       t/nil         ; Whether field is editable
)
```

### hiDisplayForm
Displays a form created with hiCreateAppForm.
```skill
hiDisplayForm(formObj)
```

### hiGetCyclicFieldValue
Gets the current value of a cyclic field.
```skill
value = hiGetCyclicFieldValue(formObj fieldName)
```

## Dialog Box Functions

### hiDisplayAppDBox
Creates and displays an application dialog box.
```skill
hiDisplayAppDBox(
  ?name           symbolValue    ; Dialog identifier
  ?title          "string"       ; Dialog window title
  ?prompt         "string"       ; Main message text
  ?info           "string"       ; Additional information text
  ?buttons        buttonList     ; List of button definitions
  ?buttonLayout   'layout       ; Button arrangement ('Vertical, 'Horizontal)
  ?unmapAfterCB   t/nil        ; Whether to unmap after callback
)
```

### hiDisplayListBox
Creates and displays a list selection dialog.
```skill
hiDisplayListBox(
  ?name           symbolValue    ; Dialog identifier
  ?title          "string"       ; Dialog window title
  ?buttonLayout   'layout       ; Button arrangement
  ?choices        listOfItems   ; List of items to display
  ?numVisChoice   number        ; Number of visible items
  ?itemAction     "procName"    ; Procedure called when item selected
)
```

## Common Callbacks and Controls

### hiDBoxCancel
Cancels and closes a dialog box.
```skill
hiDBoxCancel()
```

### hiSetFormCallbacks
Sets callback procedures for form events.
```skill
hiSetFormCallbacks(formObj
  ?okCallBack     "procName"    ; Called when OK clicked
  ?cancelCallBack "procName"    ; Called when Cancel clicked
  ?applyCallBack  "procName"    ; Called when Apply clicked
)
```

## Best Practices

1. Always provide a unique name for forms and dialog boxes to avoid conflicts
2. Use unmapAfterCB for temporary forms that shouldn't persist
3. Include error handling for form creation and display operations
4. Store form references in variables when multiple callbacks need access
5. Use cyclic fields for selection from predefined options
6. Consider using buttonLayout 'Vertical for better spacing in complex forms

## Example Usage

```skill
procedure(createDeviceSelectionForm()
  form = hiCreateAppForm(
    ?name 'deviceForm
    ?formTitle "Select Devices"
    ?buttonLayout 'OKCancel
    ?unmapAfterCB t
  )
  
  hiCreateCyclicField(
    ?parent form
    ?name 'deviceField
    ?prompt "Device:"
    ?choices '("nmos" "pmos" "resistor")
    ?value "nmos"
  )
  
  hiSetFormCallbacks(form
    ?okCallBack "processSelection()"
  )
  
  hiDisplayForm(form)
)
```

## Additional Form Controls

### hiCreateButton
Creates a clickable button in a form.
```skill
button = hiCreateButton(
  ?parent         formObj        ; Parent form object
  ?name           symbolValue    ; Button identifier
  ?buttonText     "string"      ; Text shown on button
  ?callback       "procName"    ; Function called when clicked
)
```

### hiCreateLabel
Creates a static text label in a form.
```skill
label = hiCreateLabel(
  ?parent         formObj        ; Parent form object
  ?name           symbolValue    ; Label identifier
  ?label          "string"      ; Text to display
)
```

### hiCreateFloatField
Creates a field for floating-point number input.
```skill
field = hiCreateFloatField(
  ?parent         formObj        ; Parent form object
  ?name           symbolValue    ; Field identifier
  ?prompt         "string"      ; Label text
  ?value          number        ; Initial value
  ?range          list(min max) ; Optional value range
)
```

## Progress Indicators

### hiDisplayProgressBox
Creates and displays a progress dialog box.
```skill
hiDisplayProgressBox(
  ?title          "string"      ; Dialog title
  ?message        "string"      ; Progress message
  ?totalSteps     number        ; Total number of steps
  ?cancelButton   t/nil         ; Whether to show cancel button
)
```

### hiSetProgress
Updates the progress bar position.
```skill
hiSetProgress(step)             ; Current step number
```

### hiSetProgressText
Updates the progress message.
```skill
hiSetProgressText("string")     ; New progress message
```

## Layout Management

### hiCreateFrameField
Creates a frame container for grouping related fields.
```skill
frame = hiCreateFrameField(
  ?parent         formObj        ; Parent form object
  ?name           symbolValue    ; Frame identifier
  ?title          "string"      ; Frame title
  ?frameForeground "color"      ; Optional frame color
)
```

### hiSetFormPosition
Sets the position of a form on screen.
```skill
hiSetFormPosition(formObj xPos:yPos)
```

## Advanced Dialog Features

### ddHiCreateLibraryComboField
Creates a combo box pre-populated with available libraries.
```skill
field = ddHiCreateLibraryComboField(
  ?parent         formObj        ; Parent form object
  ?name           symbolValue    ; Field identifier
  ?prompt         "string"      ; Label text
  ?callback       "procName"    ; Selection change callback
)
```

### ddHiCreateCellComboField
Creates a combo box for cell selection within a library.
```skill
field = ddHiCreateCellComboField(
  ?parent         formObj        ; Parent form object
  ?name           symbolValue    ; Field identifier
  ?prompt         "string"      ; Label text
  ?library        "libName"     ; Library to list cells from
)
```

## Example Usage of Advanced Controls

```skill
procedure(createDeviceParametersForm()
  form = hiCreateAppForm(
    ?name 'paramForm
    ?formTitle "Device Parameters"
    ?buttonLayout 'OKCancelApply
  )
  
  frame = hiCreateFrameField(
    ?parent form
    ?name 'sizeFrame
    ?title "Device Sizes"
  )
  
  hiCreateFloatField(
    ?parent frame
    ?name 'widthField
    ?prompt "Width (um):"
    ?value 1.0
    ?range '(0.1 100.0)
  )
  
  hiDisplayForm(form)
)
```