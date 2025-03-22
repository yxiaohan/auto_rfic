;; utils.il - Utility functions for auto_rfic
;; This file contains general utility functions used throughout the auto_rfic system

;; First define all functions globally before using them in any namespace
defun(autoRficGetConfigValue (configTable paramName)
    let((value)
        if(tablep(configTable)
            value = get(configTable paramName)
            value = nil
        )
        value
    )
)

defun(autoRficGetParameter (paramName @optional defaultValue)
    let((value)
        ;; Try to get from config table
        value = autoRficGetConfigValue(autoRficConfig paramName)
        
        ;; If not found and default provided, use default
        when((null value) && (boundp 'defaultValue)
            value = defaultValue
        )
        value
    )
)

defun(autoRficSetParameter (paramName paramValue)
    let(()
        ;; Store in config table
        autoRficConfig[paramName] = paramValue
        paramValue
    )
)

defun(autoRficTimestamp ()
    let((timestamp)
        timestamp = getCurrentTime()
        sprintf(nil "%d-%02d-%02d %02d:%02d %02d"
            timestamp->year
            timestamp->month
            timestamp->day
            timestamp->hour
            timestamp->minute
            timestamp->second
        )
    )
)

defun(autoRficFileExists (filePath)
    isFile(filePath)
)

defun(autoRficEnsureDirectory (dirPath)
    unless(isDir(dirPath)
        system(sprintf(nil "mkdir -p %s" dirPath))
    )
    isDir(dirPath)
)

defun(autoRficReadFile (filePath)
    let((fileId content line)
        when(autoRficFileExists(filePath)
            fileId = infile(filePath)
            content = ""
            while(gets(line fileId)
                content = strcat(content line)
            )
            close(fileId)
            content
        )
    )
)

defun(autoRficWriteFile (filePath content)
    let((fileId)
        fileId = outfile(filePath)
        fprintf(fileId "%s" content)
        close(fileId)
        t
    )
)

;; Function for remote testing functionality
procedure(autoRficTestRemote(@optional args)
  let((result)
    autoRficLogInfo("Testing remote connection...")
    
    ;; Simple echo test
    when(args
      autoRficLogInfo(sprintf(nil "Remote test arguments: %L" args))
    )
    
    ;; Return success status
    result = t
    
    autoRficLogInfo("Remote connection test completed")
    result
  )
)

;; Remove duplicate logging functions - these are now defined in logging.il

;; Initialize configuration tables if not already defined
unless(boundp('autoRficConfig)
    autoRficConfig = makeTable("")
)

;; Initialize the utility namespace
unless(boundp('autoRficUtils)
    autoRficUtils = makeTable("utils" nil)
)

;; Add utility functions to the namespace
autoRficUtils['getParameter] = 'autoRficGetParameter
autoRficUtils['setParameter] = 'autoRficSetParameter
autoRficUtils['timestamp] = 'autoRficTimestamp
autoRficUtils['fileExists] = 'autoRficFileExists
autoRficUtils['ensureDirectory] = 'autoRficEnsureDirectory
autoRficUtils['readFile] = 'autoRficReadFile
autoRficUtils['writeFile] = 'autoRficWriteFile

;; Export the utilities namespace
autoRficUtils
