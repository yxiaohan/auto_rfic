;; Debugging script for SKILL Server

;; Enable debug output
abSkillServerDebug = t

;; Test function to verify the server is working
procedure(testServer()
    printf("This is a test function from the SKILL server\n")
    return("SKILL server is responding correctly")
)

;; Simple test function that always returns a fixed value
procedure(testServerConnection()
    printf("Server connection test successful!\n")
    return("CONNECTION_TEST_SUCCESS")
)

;; Initialize the server
if(boundp('abSkillServer) && abSkillServer != nil then
    printf("SKILL server already running\n")
else
    printf("Starting SKILL server for debugging\n")
    startSkillServer("8123")
)

;; Print debug info
printf("Debug information:\n")
printf("  Current directory: %s\n" getCurrentDir())
printf("  CDS_SITE: %s\n" getShellEnvVar("CDS_SITE"))
printf("  Server process: %L\n" abSkillServer)

;; Show how to test from client
printf("\nTo test from client side, run:\n")
printf("echo 'testServer()' | nc localhost 8123\n\n")

;; Print a simple message that can be returned to the client
printf("Debug server test script executed\n")
testServerConnection()
