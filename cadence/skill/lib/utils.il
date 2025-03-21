;; utils.il - Utility functions for auto_rfic
;; This file contains general utility functions used throughout the auto_rfic system

;; First define all functions in the global namespace
defun(autoRficGetParameter (paramName @optional defaultValue)
    (let((value)
        ;; Try to get from user config first
        value = autoRficGetConfigValue(autoRficUserConfig paramName)
        
        ;; If not found in user config, try default config
        when(null(value)
            value = autoRficGetConfigValue(autoRficDefaultConfig paramName)
        )
        
        ;; If still not found, use the provided default
        when(and null(value) boundp('defaultValue)
            value = defaultValue
        )
        
        value
    )
)

;; Helper function to extract a value from a config list
defun(autoRficGetConfigValue (configList paramName)
    (let((idx value)
        idx = lindex(configList paramName)
        if(idx
            value = nth(idx+1 configList)
            value = nil
        )
        value
    )
)

;; Function to safely set a configuration parameter
defun(autoRficSetParameter (paramName paramValue)
    (let((idx)
        ;; Check if parameter already exists in user config
        idx = lindex(autoRficUserConfig paramName)
        if(idx
            ;; Update existing parameter
            autoRficUserConfig = replaceItem(paramValue idx+1 autoRficUserConfig)
            ;; Add new parameter
            autoRficUserConfig = append(autoRficUserConfig list(paramName paramValue))
        )
        paramValue
    )
)

;; Function to create a timestamp string
defun(autoRficTimestamp ()
    (let((timestamp)
        timestamp = getCurrentTime()
        sprintf(nil "%d-%02d-%02d %02d:%02d:%02d"
            timestamp->year
            timestamp->month
            timestamp->day
            timestamp->hour
            timestamp->minute
            timestamp->second
        )
    )
)

;; Function to check if a file exists
defun(autoRficFileExists (filePath)
    (isFile(filePath)
)

;; Function to create a directory if it doesn't exist
defun(autoRficEnsureDirectory (dirPath)
    (unless(isDir(dirPath)
        system(sprintf(nil "mkdir -p %s" dirPath))
    )
    isDir(dirPath)
)

;; Function to safely read a file
defun(autoRficReadFile (filePath)
    (let((fileId content line)
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

;; Function to safely write to a file
defun(autoRficWriteFile (filePath content)
    (let((fileId)
        fileId = outfile(filePath)
        fprintf(fileId "%s" content)
        close(fileId)
        t
    )
)

;; Define the utility namespace at the end after all functions are defined
autoRficUtils = makeTable(
    'getParameter        autoRficGetParameter
    'setParameter        autoRficSetParameter
    'timestamp          autoRficTimestamp
    'fileExists         autoRficFileExists
    'ensureDirectory    autoRficEnsureDirectory
    'readFile           autoRficReadFile
    'writeFile          autoRficWriteFile
)

;; Export the utilities namespace
autoRficUtils
