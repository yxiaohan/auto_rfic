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

;; Helper function to format log messages
defun(autoRficFormatLogMessage (timestamp level message @optional details)
    let((formattedMessage)
        ;; Format the basic message with timestamp and level
        formattedMessage = sprintf(nil "[%s] [%L] %s" timestamp level message)
        
        ;; Add details if provided
        when(boundp('details)
            formattedMessage = sprintf(nil "%s\n  Details: %L" formattedMessage details)
        )
        formattedMessage
    )
)

;; Core logging functions - define these first so they can be used later
defun(autoRficLog (level message @optional details)
    let((timestamp logFile fileId formattedMessage levelSymbol)
        ;; Convert level to symbol if it's a string
        levelSymbol = if(stringp(level) 
                        ;; Proper string to symbol conversion in SKILL
                        car(parseString(strcat("(" level ")")))
                        level)
        
        when(autoRficShouldLog(levelSymbol)
            timestamp = autoRficTimestamp()
            ;; Use the helper function to format the message
            formattedMessage = autoRficFormatLogMessage(timestamp levelSymbol message details)
            
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

defun(autoRficGetLogLevel (levelStr)
    let((level)
        ;; Make sure we only try to look up valid symbol keys
        ;; If levelStr is not a symbol (like a timestamp string), return default info level
        if(symbolp(levelStr)
            prog(()
                level = get(autoRficLogging['levels] levelStr)
                if(numberp(level) level 1) ; Default to info level if not found
            )
            1 ; Default to info level for non-symbol inputs
        )
    )
)

defun(autoRficShouldLog (messageLevel)
    let((configLevelStr configLevel messageLevelNum)
        ;; Get log level, default to info if not found
        configLevelStr = autoRficGetParameter('logLevel "info")
        
        ;; Make sure we're working with symbols, not strings
        configLevel = if(stringp(configLevelStr) 
                         autoRficGetLogLevel(car(parseString(strcat("(" configLevelStr ")"))))
                         autoRficGetLogLevel(configLevelStr))
        
        messageLevelNum = autoRficGetLogLevel(messageLevel)
        
        ;; Make sure both values are numbers before comparison
        ;; Default to displaying the message if there's any uncertainty
        if(numberp(messageLevelNum) && numberp(configLevel)
            messageLevelNum >= configLevel
            t  ;; If either value is nil or not numeric, allow the log message
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
