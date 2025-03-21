;; logging.il - Logging system for auto_rfic
;; This file contains functions for logging messages at different severity levels

;; Initialize the logging namespace
unless(boundp('autoRficLogging)
    autoRficLogging = makeTable("logging" nil)
)

;; Define log levels in the namespace
autoRficLogging['levels] = makeTable("levels")
autoRficLogging['levels]['debug] = 0
autoRficLogging['levels]['info] = 1
autoRficLogging['levels]['warning] = 2
autoRficLogging['levels]['error] = 3
autoRficLogging['levels]['none] = 4

;; Helper function to safely get log level number
defun(autoRficGetLevelNumber (level)
    let((levelSymbol levelNum)
        ;; Convert string to symbol if needed, or use directly if already a symbol
        levelSymbol = cond(
            (symbolp(level) level)
            (stringp(level) car(parseString(strcat("(" level ")"))))
            (t 'info)  ; default to info level for invalid inputs
        )
        
        ;; Get numeric value from levels table
        levelNum = get(autoRficLogging['levels] levelSymbol)
        if(numberp(levelNum) levelNum 1)  ; default to info (1) if not found
    )
)

;; Core logging functions - define these first so they can be used later
defun(autoRficLog (level message @optional details)
    let((timestamp logFile fileId formattedMessage currentLevel configLevel)
        ;; Get configured log level first
        configLevel = autoRficGetLevelNumber(autoRficGetParameter('logLevel "info"))
        currentLevel = autoRficGetLevelNumber(level)
        
        ;; Only log if current level is at or above config level
        when(currentLevel >= configLevel
            timestamp = autoRficTimestamp()
            formattedMessage = sprintf(nil "[%s] [%L] %s" timestamp level message)
            
            ;; Add details if provided
            when(boundp('details)
                formattedMessage = sprintf(nil "%s\n  Details: %L" formattedMessage details)
            )
            
            ;; Print to CIW
            printf("%s\n" formattedMessage)
            
            ;; Write to log file if enabled
            logFile = autoRficGetParameter('logFile nil)
            when(stringp(logFile)
                fileId = outfile(logFile "a")
                fprintf(fileId "%s\n" formattedMessage)
                close(fileId)
            )
            
            t
        )
    )
)

defun(autoRficShouldLog (messageLevelNum)
    let((configLevelStr configLevelNum)
        ;; Get configured log level, default to info if not found
        configLevelStr = autoRficGetParameter('logLevel "info")
        configLevelNum = autoRficGetLevelNumber(configLevelStr)
        
        ;; Compare numeric levels, allowing the message if levels are equal or message is more severe
        if(numberp(messageLevelNum) && numberp(configLevelNum)
            messageLevelNum >= configLevelNum
            t  ;; If either level is not a number, allow the message
        )
    )
)

;; Convenience logging functions
defun(autoRficLogDebug (message @optional details)
    autoRficLog('debug message details)
)

defun(autoRficLogInfo (message @optional details)
    autoRficLog('info message details)
)

defun(autoRficLogWarning (message @optional details)
    autoRficLog('warning message details)
)

defun(autoRficLogError (message @optional details)
    autoRficLog('error message details)
)

;; Add all logging functions to the namespace
autoRficLogging['log] = 'autoRficLog
autoRficLogging['debug] = 'autoRficLogDebug
autoRficLogging['info] = 'autoRficLogInfo
autoRficLogging['warning] = 'autoRficLogWarning
autoRficLogging['error] = 'autoRficLogError
autoRficLogging['getLogLevel] = 'autoRficGetLogLevel
autoRficLogging['shouldLog] = 'autoRficShouldLog

;; Export the logging namespace
autoRficLogging
