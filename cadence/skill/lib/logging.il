;; logging.il - Logging system for auto_rfic
;; This file contains functions for logging messages at different severity levels

;; Load required dependencies
load("/home/zhoulong/projects/auto_rfic/cadence/skill/lib/utils.il")

;; Initialize the logging namespace
unless(boundp('autoRficLogging)
    autoRficLogging = makeTable("logging" nil)
)

;; Define log levels in the namespace
autoRficLogging['levels] = makeTable(
    'debug    0
    'info     1
    'warning  2
    'error    3
    'none     4
)

;; Function to get numeric log level from string
defun(autoRficGetLogLevel (levelStr)
    let((level)
        level = get(autoRficLogging['levels] levelStr)
        if(numberp(level) level 1) ; Default to info level if not found
    )
)

;; Function to check if a message should be logged based on current log level
defun(autoRficShouldLog (messageLevel)
    let((configLevelStr configLevel messageLevelNum)
        configLevelStr = autoRficGetParameter('logLevel "info")
        configLevel = autoRficGetLogLevel(configLevelStr)
        messageLevelNum = autoRficGetLogLevel(messageLevel)
        messageLevelNum >= configLevel
    )
)

;; Core logging function
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

;; Convenience functions for different log levels
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
autoRficLogging = makeTable(
    'log        autoRficLog
    'debug      autoRficLogDebug
    'info       autoRficLogInfo
    'warning    autoRficLogWarning
    'error      autoRficLogError
    'getLogLevel autoRficGetLogLevel
    'shouldLog   autoRficShouldLog
)

;; Export the logging namespace
autoRficLogging
