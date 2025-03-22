Programming Samples
This section includes programming samples for creating forms.

File Form: Creating String Fields
This sample creates a form with a single string field. The user types the name of a file in the File Name field. The callback checks whether the file exists. If the file exists, the form callback displays it in a Show File window.



;;; creating the File Name field
trFileNameField = hiCreateStringField(
   ?name      'trFileNameField
   ?prompt    "File Name"
   ?defValue  ".cshrc"
   ?callback  "trDoFieldCheckCB( hiGetCurrentForm() )"
   ?editable  t
   )

;;; checking if the file exists
procedure( trDoFieldCheckCB( theForm )
   if( isFile( theForm->trFileNameField->value )
      then
         println("File exists")
         t
      else
         println("File Does Not Exist--Try Again")
         nil
      ) ;if
   ) ; procedure

;;; creating the form
trFileForm = hiCreateAppForm(
   ?name          'trFileForm
   ?formTitle     "File Form"
   ?callback      'trFileFormCB
   ?fields        list( trFileNameField )      
   ?unmapAfterCB  t
   )

procedure( trFileFormCB( theForm )
   if( trDoFieldCheckCB( theForm )
      then
         hiSetCallbackStatus( theForm t )
         hiHighlightField( theForm 'trFileNameField 'background )
         view( theForm->trFileNameField->value )
      else
         hiSetCallbackStatus( theForm nil )
         hiHighlightField( theForm 'trFileNameField 'highlight )
      ) ; if
   ) ; procedure

;;; displaying the form
hiDisplayForm( trFileForm )

Form Fields: Creating Fields in a Form
The following sample displays different types of fields in a form.



;;; creating the list of items in the cyclic field
trCyclicList = '(
   "1" "2" "3" "4" "5" "6" "7" "8" "9" "10"
   "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22"
   )

;;; creating the cyclic field
trCyclicField = hiCreateCyclicField(
   ?name       'trCyclicField
   ?prompt     "Cycle Through: "
   ?choices    trCyclicList
   ?value      "3"
   ?defValue   "7"
   ?callback   "println"
   )

;;; creating the boolean button field.
;;; The callback for the trBooleanButton field dynamically retrieves the new value
;;;of the field and embeds it in a message
trBooleanButton = hiCreateBooleanButton(
   ?name        'trBooleanButton
   ?buttonText  "Boolean"
   ?value        t
   ?defValue     nil
   ?callback    "println( hiGetCurrentForm()->trBooleanButton-> value )"
   )

;;; creating the button box field
trButtonBoxField = hiCreateButtonBoxField(
   ?name      'trButtonBoxField
   ?prompt    "Button Box"
   ?choices   '("Do a" "Do b" "Do c")
   ?callback  '("println( 'a )" "println( 'b )" "println( 'c)" )
    )

;;; creating the radio field.
;;; The callback for the trConeRadioField field dynamically retrieves the new value
;;; of the field and imbeds it in a message
trConeRadioField = hiCreateRadioField(
   ?name      'trConeRadioField
   ?prompt    "Cone Size: "
   ?choices   list( "small" "medium" "large" )
   ?value     "small"
   ?defValue  "large"
   ?callback  '( "printf( \"\n%s cone chosen \" hiGetCurrentForm() ->trConeRadioField->value )" )      
   )

 

;;; creating the scale field
trScaleField = hiCreateScaleField(
   ?name      'trScaleField
   ?prompt    "Slide "
   ?value     500
   ?defValue  250
   ?callback  "println(\"scale changed \")"
   ?range     0:750
   )

;;; creating the label field
trLabelField = hiCreateLabel(
   ?name           'trLabelField
   ?labelText      "Label"
   ?justification  CDS_JUSTIFY_RIGHT
   )

;;; creating the form
hiCreateAppForm(
   ?name       'trSampleForm
   ?formTitle   "Sample Form"
   ?callback   "println( 'FormAction )"
   ?fields
      list(
         trCyclicField
         trBooleanButton
         trButtonBoxField
         trConeRadioField
         trScaleField
         trLabelField
         )
   ?unmapAfterCB   t
   ) ; hiCreateAppForm

;;; displaying the form
hiDisplayForm( trSampleForm )

Window Form: Creating an Application
The following sample creates a form that allows the user to change the title or size of a given window.



;;; retrieving the height of the bounding box
procedure( trGetBBoxHeight( bBox )
      let( ( ll ur lly ury )
      ll = lowerLeft( bBox )
      lly = yCoord( ll )
      ur = upperRight( bBox )
      ury = yCoord( ur )
      ury - lly
      ) ; let
   ) ; procedure

;;; retrieving the width of the bounding box
procedure( trGetBBoxWidth( bBox )
   let( ( ll ur llx urx )
      ll = lowerLeft( bBox )
      llx = xCoord( ll )
      ur = upperRight( bBox )
      urx = xCoord( ur )
      urx - llx
      ) ; let
   ) ; procedure

;;; retrieving the window height
procedure( trGetWindowHeight( wid )
   trGetBBoxHeight(hiGetAbsWindowScreenBBox( wid ) )
   ) ; procedure

;;; retrieving the window width
procedure( trGetWindowWidth( wid )
   trGetBBoxWidth( hiGetAbsWindowScreenBBox( wid ) )
   ) ; procedure

;;; resizing the window to the given bounding box
procedure( trResizeWindow( @key ( id hiGetCurrentWindow() ) ( height nil ) ( width nil ) )
   let( ( bBox ll ur llx lly urx ury urNew )
      bBox = hiGetAbsWindowScreenBBox( id )
      ll = lowerLeft( bBox )
      ur = upperRight( bBox )
      llx = xCoord( ll )
      lly = yCoord( ll )
      urx = xCoord( ur )
      ury = yCoord( ur )

      unless( height height = ury - lly )
      unless( width width = urx - llx )

      urNew = llx + width : lly + height
      
      hiResizeWindow( id list( ll urNew ) )
      
      id
      ) ; let
   ) ; procedure

 

;;; creating a form that acts upon the window with the
;;; window id (wid)
procedure( trCreateWindowForm( wid )
   let( ( nameField heightField widthField theFormSymbol theForm )
      
      nameField =
        hiCreateStringField(
            ?prompt "Name"
            ?name 'nameField
            ?value hiGetWindowName( wid )
            ?defValue hiGetWindowName( wid )
            ?callback "println( 'nameField )"
            )

      heightField =
         hiCreateScaleField(   
            ?prompt "Height"
            ?name 'heightField
            ?value trGetWindowHeight( wid )
            ?defValue trGetWindowHeight( wid )
            ?range    list( 0 yCoord( hiGetMaxScreenCoords()))
            ?callback "println( 'heightField )"
            )

      widthField =
         hiCreateScaleField(
            ?prompt "Width"
            ?name 'widthField
            ?value trGetWindowWidth( wid )
            ?defValue trGetWindowWidth( wid )
            ?range list( 0 xCoord( hiGetMaxScreenCoords())  )
            ?callback    "println( 'widthField )"
            )

      ;;; specifying a unique symbol to allow multiple
      ;;; instances of the form to be active at a single
      ;;; time
      theFormSymbol = gensym( 'WindowForm )

   ;;; building the form's data structure
theForm =
         hiCreateAppForm(
            ?name theFormSymbol
            ?formTitle sprintf( nil "%L" wid )               
            ?callback "trWindowFormCB( hiGetCurrentForm())"
            ?fields list( nameField heightField widthField)
            ?unmapAfterCB t
            )

      ;;; associating the wid with the form via a user
      ;;; defined slot
      theForm->wid = wid

      theForm ;;; the return value

      ) ; let
   ) ; procedure


;;; The following callback for the form handles the
;;; renaming and resizing of the window.
procedure( trWindowFormCB( theForm )
   let( ( wid newName newHeight newWidth )
      ;;; picking up the current form values
      wid = theForm->wid
      ;;; user specified slot linking the form to the window
      newName = theForm->nameField->value
      ;;; accessing the current hightField
      newHeight = theForm->heightField->value
      ;;; accessing the current widthField
      newWidth = theForm->widthField->value

      ;;; setting the window name
      hiSetWindowName( wid newName )

      ;;; resizing the window
      trResizeWindow(
         ?id wid
         ?height newHeight
         ?width newWidth
         ) ; trResizeWindow

      t      ;;; the return value

      ) ; let
   ) ; procedure

Testing Your Application
To test your application using the CIW, type:

wf1 = trCreateWindowForm( window(1))
hiDisplayForm(wf1)

After the form is displayed, change the values of the Height and Width fields and type a new title for the CIW in the Name field. Select the Apply button to see the changes in the title and size of the CIW.

List Editor: Creating List Box Fields
The following sample shows you how to include a list box in a form. The user can rearrange the items of the list box by selecting the Move Up or Move Down buttons.



;;; The following procedures returns a copy of aList
;;; with elem swapped one position closer to the top
;;; of the list. == aList if elem is already on top
;;; of the list.
procedure( trSwapElementTowardTop( elem aList )
   cond(
( !aList nil )
    ( elem == car( aList )   aList )   ;;; already the first item
      ( elem == cadr( aList )
         `( ,elem ,car( aList ) ,@cddr( aList ))
         )
      ( t
         cons(
            car( aList )
            trSwapElementTowardTop( elem cdr( aList ))
            )
         ) ; t
      ) ; cond
   ) ; procedure

/*
trSwapElementTowardTop( 1 nil )
trSwapElementTowardTop( 1 '( 1 ) )
trSwapElementTowardTop( 1 '( 1 2 ) )
trSwapElementTowardTop( 1 '( 2 1 ) )
trSwapElementTowardTop( 1 '( 2 1 3 4 ) )
trSwapElementTowardTop( 1 '( 2 3 4 1 ) )
trSwapElementTowardTop( 1 '( 2 1 3 4 ) )
*/

;;; The following procedure returns a copy of aList with
;;; elem swapped one position closer to the bottom of
;;; the list.==aList if elem is already on the bottom of
;;; the list.

procedure( trSwapElementTowardBottom( elem aList )
   cond(
      ( !aList nil )
      ( length( aList ) == 1 aList )
      ( elem == car( aList )               ;
         `( ,cadr( aList ) ,elem ,@cddr( aList ))
         )
      ( t
         cons(
            car( aList )
            trSwapElementTowardBottom( elem cdr( aList ))
            )
         ) ; t
      ) ; cond
   ) ; procedure

/*
trSwapElementTowardBottom( 1 nil )
trSwapElementTowardBottom( 1 '( 1 ) )
trSwapElementTowardBottom( 1 '( 1 2 ) )
trSwapElementTowardBottom( 1 '( 2 1 ) )
trSwapElementTowardBottom( 1 '( 2 1 3 4 ) )
trSwapElementTowardBottom( 1 '( 2 3 4 1 ) )
*/

;;; The following procedure returns a list build using the
;;; elements of aList as indices into anAssocList. It looks
;;; up each element of aList in anAssocList to determine the
;;; element to include in the result.
procedure( trReorderList( anAssocList aList )
    foreach( mapcan item aList
      list( cadr( assoc( item anAssocList )) )
      ) ; foreach
   ) ; procedure

 

;;; A list box field can only display text strings.
;;; Since trListEditor should work on any list, the
;;; code should translate back and forth from a data
;;; item X to its print representation returned by
;;; sprintf( nil "%L"X).
procedure( trListEditor_Choices( aList )
   foreach( mapcar item aList
      sprintf( nil "%L" item )
      ) ; foreach
   ) ; procedure

;;; The following procedure recovers the underlying items
;;; from their print representations.
procedure( trListEditor_AssocList( aList )
   foreach( mapcar item aList
      list( sprintf( nil "%L" item ) item )
      ) ; foreach
   ) ; foreach

procedure( trListEditor( aList )
   let( ( listBoxField buttonBoxField aListChoices theForm moveUpButton moveDownButton )
      
      listBoxField = hiCreateListBoxField(
         ?name 'trListBoxField      
         ?prompt "Items"
         ?choices trListEditor_Choices( aList )
         ?numRows min( length( aList ) 10 )
         )

      ;;; creating the Move Up button
      moveUpButton = hiCreateButton(
         ?name 'trMoveUpButton
         ?buttonText "Move Up"
         ?callback "trListEditorCB( hiGetCurrentForm()
'MoveUp )"
         )

      ;;; creating the Move Down button
      moveDownButton = hiCreateButton(
         ?name 'trMoveDownButton
         ?buttonText "Move Down"
         ?callback "trListEditorCB( hiGetCurrentForm() 'MoveDown)"
         )

      ;;; creating the Delete button
      deleteButton = hiCreateButton(
         ?name 'trDeleteButton
         ?buttonText "Delete"
         ?callback "trListEditorCB( hiGetCurrentForm() 'Delete )"
         )
         
      ;;; creating the form
      theForm = hiCreateAppForm(
         ?name gensym( 'trListEditor )
         ?formTitle "List Editor"
         ?fields list( listBoxField moveUpButton moveDownButton deleteButton )
         ?callback "trListEditorCB( hiGetCurrentForm()
'Apply )"
         )

      theForm->trListEditor_AssocList = trListEditor_AssocList( aList )
      ;;; displaying the form
      hiDisplayForm( theForm )
      ) ; let
   ) ; procedure

procedure( trListEditorCB( theForm theAction )
   prog( ( selectedItem choices )
      selectedItem = car( theForm->trListBoxField->value )
      when( !selectedItem
         printf( "You haven't selected an item yet\n" )
         return( nil )
         ) ; when
      choices = theForm->trListBoxField->choices
      case( theAction
         ( MoveUp
            theForm->trListBoxField->choices =
trSwapElementTowardTop(
               selectedItem    ;;; selected element
               choices       ;;; within list of items
               )
            theForm->trListBoxField->value = list(
selectedItem )
            ) ; MoveUp
         ( MoveDown
            theForm->trListBoxField->choices =
trSwapElementTowardBottom(
   selectedItem    ;;; selected element
   choices ;;; within list of items
               )
            theForm->trListBoxField->value = list(
selectedItem )
            ) ; MoveDown
         ( Delete
            theForm->trListBoxField->choices = remove(   
               selectedItem    ;;; selected element
               choices       ;;; from list of items
               ) ; remove
            ;;; no selection
            ) ; Delete
         ( Apply
            println( theForm->trListEditor_result =
trListEditor_ReorderList( theForm ))
            ) ; Apply
         ( t
            error( "Unsupported action: %L" theAction )
            ) ; t
         ) ; case
      ) ; let
   ) ; procedure

procedure( trListEditor_ReorderList( theForm )
   let( ( assocList choices )
      assocList = theForm->trListEditor_AssocList
      choices = theForm->trListBoxField->choices
      trReorderList( assocList choices )
      ) ; let
   ) ; procedure

Testing Your Application
To test your list editor, type:

Z = trListEditor( '( 1 2 3 ))

After the form is displayed, rearrange the list box by moving the items up or down.

File Browser: Creating Multiline Text Fields
The following sample uses a multiline text field to display the contents of a given file.



procedure( trMoreFile( )
   let( ( fileNameField fileContentsField theForm )
;;; creating the File Name string field
      fileNameField = hiCreateStringField(
         ?name 'trFileNameField
         ?prompt "File Name"
         ?defValue ".cshrc"
         ?callback "trMoreFileCB( hiGetCurrentForm() 'trFileNameField )"
         )
   
;;; creating the Contents multiline text field for
;;; viewing the file
       fileContentsField = hiCreateMLTextField(
         ?name 'trMLTextField
         ?prompt "Contents"
         ?defValue ""
         ?editable t ;; so users can edit the file
         )

;;; creating the form
      theForm = hiCreateAppForm(
         ?name gensym( 'trMoreFile   )
         ?formTitle "File Browser"
         ?callback "trMoreFileCB(hiGetCurrentForm() 'apply)"
         ?buttonLayout 'ApplyCancelDef
         ?fields
               list( fileNameField fileContentsField )
         )
      hiDisplayForm( theForm )
      ) ; let
   ) ; procedure

procedure( trMoreFileCB( theForm actionOrField )
   case( actionOrField
      ;;; checking if the file exists
      ( trFileNameField
         if( isFile( theForm->trFileNameField->value )
            then
               println("File exists")
               t
            else
               println("File Does Not Exist--Try Again")
               nil
            ) ;if
         )
      ( apply
         when( trMoreFileCB( theForm 'trFileNameField )
            theForm->trMLTextField->value =
               trReadFileIntoString(
theForm->trFileNameField->value )
            ) ; when
         )
      ( t
         error( "Illegal action or unknown field: %L" actionOrField )
         )
      ) ; case
   ) ; procedure

;;; The following procedure returns a list of the lines
;;; in the file in the correct order
procedure( trReadFile( pathname )
   let( ( inPort nextLine allLines )
      inPort = infile( pathname )
      when( inPort = infile( pathname )
         while( gets( nextLine inPort )
            allLines = cons( nextLine allLines )
            ); while
         close( inPort )
         ) ; when
      reverse( allLines )
      ) ; let
   ) ; procedure

;;; reading the entire file into a single string
procedure( trReadFileIntoString( pathname )
   let( ( allLines )
      allLines = trReadFile( pathname )
      when( allLines apply( 'strcat allLines ) )
      ) ; let
   ) ; procedure

