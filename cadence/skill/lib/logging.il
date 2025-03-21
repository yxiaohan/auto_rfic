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

;; Core logging functions - define these first so they can be used later
defun(autoRficLog (level message @optional details)
    let((timestamp logFile fileId formattedMessage)
        when(autoRficShouldLog(level)
            timestamp = autoRficTimestamp()
            formattedMessage = sprintf(nil "[%s] [%s] %s" timestamp level message)
            
            ;; Add details if provided
            when(boundp('details)
                formattedMessage = sprintf(nil "%s\n  Details: %L" formattedMessage details)
            )
            
            ;; Print to CIW
            printf("%s\n" formattedMessage)
            
            ;; Write to log file if enabled
            logFile = autoRficGetParameter('logFile)
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
        level = get(autoRficLogging['levels] levelStr)
        if(numberp(level) level 1) ; Default to info level if not found
    )
)

defun(autoRficShouldLog (messageLevel)
    let((configLevelStr configLevel messageLevelNum)
        configLevelStr = autoRficGetParameter('logLevel "info")
        configLevel = autoRficGetLogLevel(configLevelStr)
        messageLevelNum = autoRficGetLogLevel(messageLevel)
        messageLevelNum >= configLevel
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
