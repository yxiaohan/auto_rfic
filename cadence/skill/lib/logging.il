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

;; Default configuration (will be overridden by config files later)
autoRficLogging['defaultLevel] = 'info
autoRficLogging['currentLevel] = autoRficLogging['defaultLevel]

;; Helper function to format log message
defun(autoRficFormatLogMessage (level message details)
    let((timestamp formattedMessage)
        ;; Get timestamp first since it's just a string
        timestamp = autoRficTimestamp()
        
        ;; Format the base message
        formattedMessage = sprintf(nil "[%s] [%L] %s" timestamp level message)
        
        ;; Add details if provided
        when(boundp('details)
            formattedMessage = sprintf(nil "%s\n  Details: %L" formattedMessage details)
        )
        formattedMessage
    )
)

;; Helper function to safely get log level number
defun(autoRficGetLevelNumber (level)
    let((levelSymbol)
        ;; Convert string to symbol if needed, or use directly if already a symbol
        levelSymbol = cond(
            (symbolp(level) level)
            (stringp(level) car(parseString(strcat("(" level ")"))))
            (t autoRficLogging['defaultLevel])  ; use default level for invalid inputs
        )
        
        ;; Get numeric value from levels table, with fallback to info (1)
        get(autoRficLogging['levels] levelSymbol) || 1
    )
)

;; Core logging functions - define these first so they can be used later
defun(autoRficLog (level message @optional details)
    let((formattedMessage logFile fileId currentLevel configLevel)
        ;; Get level numbers directly
        currentLevel = autoRficGetLevelNumber(level)
        configLevel = if(boundp('autoRficConfig)
            autoRficGetLevelNumber(get(autoRficConfig "logLevel") || 'info)
            1  ; default to INFO level if config not available
        )
        
        ;; Only log if current level is at or above config level
        when(currentLevel >= configLevel
            ;; Format message with timestamp
            formattedMessage = autoRficFormatLogMessage(level message details)
            
            ;; Print to CIW
            printf("%s\n" formattedMessage)
            
            ;; Write to log file if enabled and config exists
            when(boundp('autoRficConfig)
                logFile = get(autoRficConfig "logFile")
                when(stringp(logFile)
                    fileId = outfile(logFile "a")
                    fprintf(fileId "%s\n" formattedMessage)
                    close(fileId)
                )
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
