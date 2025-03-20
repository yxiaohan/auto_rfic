; init.il - Initialization script for auto_rfic SKILL framework
; This file is loaded automatically when Virtuoso starts via run_virtuoso.sh

; Print initialization message to CIW
printf("Loading auto_rfic SKILL framework...\n")

; Log the start of initialization to both CIW and remote connections
procedure(logMessage(msg)
    printf("%s\n" msg)
    fprintf(poport msg)
    nil
)

; Setup environment for remote CIW access
let((ciw_port)
    ciw_port = outfile("| cat > /tmp/ciw_output")
    poport = ciw_port
    
    ; Log initialization information
    logMessage("====================================================")
    logMessage(sprintf(nil "auto_rfic SKILL Framework - Started: %s" getCurrentTime()))
    logMessage("====================================================")
    logMessage("Remote CIW access is ENABLED")
    logMessage("You can send SKILL commands via the network socket")
    logMessage("====================================================")
)

; Get current time as a formatted string
procedure(getCurrentTime()
    strcat(
        sprintf(nil "%d" getd("date" 'year))
        sprintf(nil "-%02d" getd("date" 'month))
        sprintf(nil "-%02d" getd("date" 'day))
        sprintf(nil " %02d" getd("date" 'hour))
        sprintf(nil ":%02d" getd("date" 'minute))
        sprintf(nil ":%02d" getd("date" 'second))
    )
)

; Load utility functions if they exist
when(isFile("./skill/lib/utils.il")
    load("./skill/lib/utils.il")
    logMessage("Loaded utility functions")
)

; Load GUI components if they exist
when(isFile("./skill/lib/gui.il")
    load("./skill/lib/gui.il")
    logMessage("Loaded GUI components")
)

; Register a CIW command to test remote functionality
procedure(testRemote()
    logMessage("Remote command execution TEST SUCCESSFUL!")
    logMessage(sprintf(nil "Current time: %s" getCurrentTime()))
    t
)

; Print completion message
logMessage("auto_rfic SKILL framework initialization complete.")
logMessage("Type 'testRemote()' to test remote communication.")

; Make sure testRemote function is accessible globally
CCSCreateAlias("testRemote" 'testRemote)
