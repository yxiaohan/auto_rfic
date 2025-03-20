;; Simple debug script for testing the SKILL server communication

printf("DEBUG_SERVER: Script execution started\n")

;; Define a simple test function
procedure(testFunction()
    let((msg)
        msg = "This is a test message from the server"
        printf("DEBUG_SERVER: %s\n" msg)
        return(msg)
    )
)

;; Run the test function
result = testFunction()

;; Print completion status
printf("DEBUG_SERVER: Script execution completed\n")

;; Return a value that's easy to distinguish
"DEBUG_SERVER_SUCCESS"
