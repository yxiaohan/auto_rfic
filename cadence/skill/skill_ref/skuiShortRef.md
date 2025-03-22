Okay, here's a summarized API reference based on the provided text, focusing on the core concepts and most commonly used functions. I'll organize it into sections for clarity.

**I. Core Concepts**

*   **Forms:** User interface dialogs to solicit input. Created with `hiCreateAppForm` (recommended) or `hiCreateForm`.
    *   **Standard Forms:** For general data input. Have OK, Cancel, Defaults, Apply, and Help buttons.
    *   **Options Forms:** Used with graphical data entry (`enterFunctions`). Have Hide, Cancel, Defaults, Last, and Help buttons.
*   **Fields:** The individual input elements within a form (text boxes, buttons, lists, etc.). Created with `hiCreate...Field` functions.
*   **Layouts:** Control the arrangement of fields within a form.
    *   **One-Dimensional:** Fields arranged in a single column (default).
    *   **Two-Dimensional:** Fields placed at specific pixel coordinates.  Requires specifying x, y, width, and height for *every* field. No automatic geometry management.
    *   **hiLayout:**  A more advanced layout system using `hiCreateFormLayout`, `hiCreateGridLayout`, `hiCreateHorizontalBoxLayout`, and `hiCreateVerticalBoxLayout`.  Provides features like margins, spacing, alignment, and stretch factors. Recommended for resizable forms.
    *   **Field Attachments:** Used with 2D layouts to make fields resize automatically when the form is resized. Requires specifying `?attachmentList` and `?initialSize` in `hiCreateAppForm`.
*   **Callbacks:** SKILL functions executed when a form button is pressed (OK, Cancel, etc.) or when a field's value changes.
*   **Data Access:** Use the `->` operator to access (read-only) form and field properties.  Use `formHandle->fieldHandle->value = newValue` to set the `value` and `defValue` of a field.
*   **Instantiation:**  `hiInstantiateForm` makes a form ready for interaction (but not visible).  `hiDisplayForm` makes a form visible.

**II. Key Functions (Creation)**

*   **`hiCreateAppForm(?name s_name ?fields l_fieldEntries ...)`:**  Creates a standard or options form.  *This is the primary form creation function.* Key arguments:
    *   `?name`:  A symbol to reference the form.
    *   `?fields`: A list of field descriptors (created by `hiCreate...Field` functions).  For 2D layouts, this is a list of lists: `list(field x:y width:height [promptWidth])`.
    *   `?formTitle`:  The title in the form's banner.
    *   `?callback`: The callback function (or a list of `(OK-callback Cancel-callback)`). Can be a string, symbol, or function object.
    *   `?buttonLayout`:  Specifies which buttons to display (e.g., `'OKCancel`, `'OKCancelApply`, `'HideCancel`).  Can also include custom buttons.
    *   `?formType`: `'nonoptions` (default) or `'options`.
    *   `?dialogStyle`: `'modal` (blocks application) or `'modeless` (default, does not block).
    *   `?help`:  Specifies help information.
    *   `?initialSize`, `?minSize`, `?maxSize`: Control form sizing.
    *    `?attachmentList`: List specifying how the fields should attach with form resizing.

* **hiLayout forms creation**
    *    `hiCreateFormLayout(...)`: Creates a form layout that contains labels, margins, spacing, and alignment.
    * `hiCreateGridLayout(...)`: Creates a grid layout.
    * `hiCreateHorizontalBoxLayout(...)`: Creates a horizontal layout.
    *   `hiCreateVerticalBoxLayout(...)`: Creates a vertical layout.
    *   `hiCreateLayoutForm(s_name t_title r_layout ...)`: Creates the SKILL representation of a layout form.

*   **Field Creation Functions (hiCreate...Field):**  These all return a field descriptor.  Common arguments:
    *   `?name`:  A symbol to reference the field *within* the form.
    *   `?prompt`: The text label for the field.
    *   `?value`:  The initial value of the field.
    *   `?defValue`: The default value (restored by the "Defaults" button).
    *   `?callback`: A callback function executed when the field's value changes.
    *    `?enabled`: enable(t) or disable(nil) a field. Default is t.
    *   `?invisible`: make field visible(nil) or invisible(t). Default is nil.

    Specific field creation functions:
    *   `hiCreateStringField(...)`:  Text input.
    *   `hiCreateIntField(...)`: Integer input.
    *   `hiCreateFloatField(...)`: Floating-point input.
    *   `hiCreateListField(...)`: SKILL list input.
    *   `hiCreatePointField(...)`:  `(x y)` coordinate input.
    *   `hiCreateBBoxField(...)`:  `((x1 y1) (x2 y2))` bounding box input.
    *   `hiCreatePointListField(...)`: List of points input.
    *   `hiCreateToggleField(...)`:  Multiple on/off toggle buttons.
    *   `hiCreateRadioField(...)`: Mutually exclusive radio buttons.
    *   `hiCreateCyclicField(...)`: Drop-down list of choices.
    *   `hiCreateButtonBoxField(...)`:  Row of buttons.
    *   `hiCreateComboField(...)`:  Text field with a drop-down list.
    *   `hiCreateOutputStringField(...)`: Display-only text.
    *   `hiCreateHypertextField(...)`:  Displays rich text with hyperlinks.
    *   `hiCreateSimpleHypertextField(...)`:  Single-line hyperlink.
    *   `hiCreateButton(...)`:  A standalone button.
    *   `hiCreateLabel(...)`:  A text label.
    *   `hiCreateLayerCyclicField(...)`: Cyclic field for layer selection.
    *   `hiCreateBooleanButton(...)`: Single on/off button with text.
    *   `hiCreateScrollRegion(...)`:  Creates a scrollable area within a form.
        *    `hiCreateStackedLayout(...)`: Creates stacked layout, first item defstruct.
    *    `hiCreateTabField`: Creates a tab field with multiple pages.
    *  `hiCreateTreeTable`: Creates a tree table for displaying a tree that can be presented in a table format.
    *   `hiCreateTree`: Creates a tree or a sub-tree.
    *   `hiCreateTreeItem`: Creates tree items.
    * `ddHiCreateLibraryComboField`: Customized Library combo field.
     *`ddHiCreateCellComboField`: Customized Cell combo field.
     * `ddHiCreateViewComboField`: Customized View combo field.

* **Menu creation functions**
     *   `hiCreate2DMenu`: Creates a 2D menu.

**III. Key Functions (Form and Field Manipulation)**

*   **`hiDisplayForm(g_form [l_location])`:** Displays a form.
*   **`hiFormDone(r_form)`:**  Simulates clicking the "OK" button (or "Close"/"Quit").
*   **`hiFormCancel(r_form)`:**  Simulates clicking the "Cancel" button.
*   **`hiFormApply(r_form)`:** Simulates clicking the "Apply" button.
*   **`hiFormDefaults(r_form)`:**  Resets all fields to their default values.
*   **`hiSetFieldValue(r_form s_field g_value)`:** Sets the value of a field.
*   **`hiGetFieldValue(r_form s_field)`:** Gets the value of a field.
* **Accessing layout fields**
  *   `hiAddItemToLayout(...)`: Adds required controls to the layout.
  * `hiAddField`: Adds a field to a form.
  *   `hiAddFields`: Adds fields to a form.
  *    `hiDeleteField`: Deletes a field from a form.
  *   `hiDeleteFields`: Deletes multiple fields from a form.
  *    `hiDeleteItemFromLayout(...)`: Deletes an item from hiLayout.
  *   `hiGetLayoutChildLayouts(...)`: Returns a list of child-hiLayout.
  *   `hiGetLayoutFields(...)`: Returns a list of field items.
  *    `hiGetLayoutItems(...)`: Returns description of all the items.
  *   `hiGetLayoutFrame(...)`: Returns the frame title.
  *   `hiGetLayoutItemIndex(...)`: Returns the index of the item.
  *   `hiGetLayoutMargins(...)`: Returns the margins of the layout.
  *   `hiGetLayoutType(...)`: Returns the type of hiLayout.
  *   `hiGetStackedLayoutCurrentIndex(...)`: Returns index of the current top item.
  * `hiInsertItemToLayout`: Inserts required controls to the layout.
  *   `hiLayoutUTp`: Checks if an argument is an instantiated hiLayout object.
  *   `hiSetFieldMinSize`: Sets the minimum width and height.
  *   `hiSetLayoutFrameTitle`: Sets the title for a frame layout.
  *  `hiSetLayoutMargins(...)`: Sets the margins of the layout.
  *  `hiSetStackedLayoutCurrentIndex(...)`: Sets the index of the current top item.
*   **`hiChangeFormCallback(r_form g_newCallback)`:** Changes the callback function of a form.
*   **`hiChangeFormTitle(r_form t_newTitle)`:** Changes the title of a form.
*   **`hiMoveField(r_form s_field l_location)`:** Moves a field (2D forms only, no attachments).
*   **`hiResizeField(r_form s_field l_resizeDescription)`:** Resizes a field (2D forms only, no attachments).
*   **`hiOffsetField(r_2DFormOr2DMenu s_field l_offsets)`:** Offsets field (2D form or 2D menu) from current position.
*    **`hiReattachField(...)`:** Reattaches a field in a 2D form with field attachments.
*   **`hiSetFieldEditable(r_field g_editable)`:**  Makes a field editable or read-only.
*   **`hiSetFieldEnabled(g_field g_enabled)`:** Enables or disables a field.
*   **`hiSetFormButtonEnabled(r_form s_buttonSym g_enabled)`:** Enables or disables a form button.
*   **`hiSetFormMinMaxSize(r_form g_minSize g_maxSize)`:**  Sets the minimum and maximum size of a form.
* **`hiSetCurrentField(form, field)`**: Sets input focus to a type-in field.
*  **`hiMoveToFormField(...)`**: Sets input focus, scrolls, and warps pointer.
* **`hiSetKeyboardFocusField(...)`**: Sets keyboard focus.
*   **`hiGetFieldInfo(r_2DFormOr2DMenu s_field)`:**  Gets the dimensions of a field (2D forms only).
*    **`hiGetFieldOverlaps(...)`:**  Generates warnings if the form specified contains any fields whose bounding boxes overlap with other fields.
*   **`hiGetFormLocation(r_form)`:** Gets the location of the form.
* **`hiGetFormSize(r_form)`:** Gets the size of the form.
* **`hiIsFormDisplayed(r_form)`:** Check form visibility.
* **`hiIsForm(g_FormOrMenu)`:** Checks form validity.
* **`hiIsInstantiated(g_formRegionOrMenu)`:** Check if the form is already instantiated.
*  **`hiDeleteForm(r_form)`:**  Deletes the specified form.
*   **`hiGetCurrentForm()`:**  Returns the last active form.
* **`hiGetCurrentField(form)`:** Returns symbol of the field with focus.
*   **`hiFormList()`:** Returns a list of defined form symbols.
* **`hiSetFormBlock(form, block, unmanage)`:** Temporarily prevents form updates.
* **`hiUpdateFormBlock(form)`:** Re-enables form updates after `hiSetFormBlock`.
*  **`hiGetInsertionPosition(...)`**:  Gets the current position of the insertion cursor in a type-in field.
* **`hiSetInsertionPosition(...)`:** Sets the current position of the insertion cursor in a type-in field.
*   **Tree Table Specific Functions:**
    *   `hiTreeAppendItem(g_tree g_item)`:  Adds an item to the end of a tree.
    *  `hiTreeAppendItems(...)`: Adds items to the end of a tree.
    *   `hiTreePrependItem(g_tree g_item)`: Adds an item to the beginning of a tree.
    *   `hiTreePrependItems(...)`: Adds items to the beginning of a tree.
    *  `hiTreeRemoveItem(...)`: Removes an item from a tree.
    *  `hiTreeRemoveItems(...)`: Removes multiple items from a tree.
    *   `hiTreeRemoveAllItems(g_tree)`: Removes all items from a tree.
    *   `hiCollapseTreeItem(g_item [g_notify])`:  Collapses a tree item.
    *   `hiExpandTreeItem(g_item [g_notify])`: Expands a tree item.
    *   `hiGetTreeItems(g_tree)`: Gets a list of all items in a tree.
    *   `hiGetTreeItemDescription(g_item)`: Gets the description of an item.
    *   `hiSetTreeItemDescription(g_item g_description)`:  Sets the description of an item.
     *   `hiGetTreeItemIcons(...)`:  Gets the icons associated with a tree item
    *   `hiSetTreeItemIcons(...)`:  Sets the icons for a tree item.
    *    `hiItemInsertTree(...)`: Creates a sub-tree.
    *   `hiItemRemoveTree(g_item)`:  Removes the sub-tree from an item.
    *   `hiGetTreeItemParent(...)`:  Gets the parent tree of an item.
    *   `hiGetTreeParent(...)`:  Gets the parent of a tree.
    *   `hiTreeTableDeselectItem(...)`:  Deselects an item in a tree table field
    *  `hiTreeTableDeselectItems(...)`: Deselects multiple items in a tree table field.
    *   `hiTreeTableDeselectAllItems(...)`:  Deselects all items in a tree table field.
     *  `hiTreeTableGetExpandedItems(...)`: Gets a list of all the items that are currently expanded in a tree table field.
     *  `hiTreeTableGetExpandedItemCount(...)`: Returns the number of items that are currently expanded.
     *  `hiTreeTableGetItems(...)`: Gets all the items in a tree table field.
     * `hiTreeTableGetItemCount(...)`: Returns the number of items in a tree table field.
      * `hiTreeTableGetSelectedItems(...)`: Gets a list of all the items that are currently selected in a tree table field.
      *  `hiTreeTableGetSelectedItemCount(...)`: Returns the number of items that are currently selected.
      * `hiTreeTableSelectItem(...)`: Selects an item in a tree table field.
     *  `hiTreeTableSelectItems(...)`:  Selects items in a tree table field
      * `hiTreeTableSelectAllItems(...)`:  Selects all items in a tree table field.
      * `hiSwapTreeItemSelectionIcons(...)`: Swaps item icon and expanded icon with the selection icon and expanded selection icon.

* **hiLaunchBrowser**: Starts a Web browser, if needed, and opens the URL you specify.

*   **List Box Specific Functions:**
    *  `hiGetListBoxValue(o_listBox)`: Returns the value of the list box field as a list of strings.
    *   `hiGetNumVisibleItems(...)`:  Returns the number of visible items for a list box field.
    *    `hiGetTopListItem(...)`:  Returns the top item position of a listbox field.
    *    `hiSetListItemVisible(...)`:  Brings the specified list box item into view in the list box
    *    `hiSetListItemCenter(...)`:  Brings the specified list box item into view in the center of the list box.

*   **Cyclic Field Specific Functions:**
    *    `hiGetChoiceStrings(...)`:  Returns strings of all choices.
    *  `hiGetCyclicValueString(o_cyclic)`: Gets the cyclic field's value as a string.
     *    `hiAddCyclicChoice(...)`:  Adds the new entry to the end of the list of choices.
    * `hiLayerMatchCyclicStr`: Returns the layer cyclic value associated with the specified string.

*    **Layer Cyclic Field Specific Functions**
    *    `hiGetLayerCyclicValue(...)`:  Returns the layer object associated with the current value.
    *    `hiLayerStringToLPP(...)`:  Returns the layer object in the specified techfile.

* **String specific functions**
 * `hiEscapeStringChars(...)`: Escapes backslash and double quotes.
 * `hiEscapeHTMLTags`: Replaces HTML tags with character directives.

*  **Button Specific Functions:**
     *    `hiSetButtonIcon(...)`:  Changes a button's icon.
    *    `hiSetButtonLabel(...)`: Changes a button's label.

* **Utility functions**
    *  `hiGetScrollBarInfo`: Provides horizontal and vertical scroll bar information.
     * `hiSetScrollBarValue(...)`:  Sets the horizontal and vertical scroll bars.
      *  `hiStoreFormLocation(...)`:  Stores a form's location coordinates.
      * `hiIsScrollRegion`: Checks if an item is a scroll region field.

**IV.  Important Notes**

*   **Read-Only Properties:**  Most form and field properties are read-only after the form is created.  You can *only* reliably set `value` and `defValue` directly.
*   **Field Naming:** Avoid using reserved property names for your fields (e.g., `value`, `prompt`, `choices`).  This will cause conflicts.
*   **Callbacks and `hiGetCurrentForm()`:**  Within a callback, use `hiGetCurrentForm()` to get a handle to the form that triggered the callback.  This is more reliable than using the global form variable.
*   **Error Handling:** Many functions return `nil` on failure. Check return values.
* **Video demonstration available**: Check out the "How to use the hi*.Layout Functions to Create Modular and Re-sizable Forms" video.

This abbreviation provides a much more concise and usable reference than the original, full documentation. It covers the essential elements needed to build and manage forms effectively. Remember to consult the full documentation for complete details on specific functions and arguments.
