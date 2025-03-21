;; db.il - Database functions for auto_rfic
;; This file contains functions for managing persistent data storage

;; Define the database namespace
autoRficDb = list(nil)

;; Define the database file path
autoRficDbFile = strcat(
  getShellEnvVar("HOME")
  "/.auto_rfic/database.dat"
)

;; Initialize the database
autoRficDatabase = nil

;; Function to load the database from disk
procedure(autoRficLoadDatabase()
  let((fileId data)
    ;; Ensure the directory exists
    autoRficEnsureDirectory(strcat(getShellEnvVar("HOME") "/.auto_rfic"))
    
    ;; Check if database file exists
    if(autoRficFileExists(autoRficDbFile)
      ;; Load existing database
      data = infile(autoRficDbFile)
      if(data
        prog(()
          autoRficDatabase = read(data)
          close(data)
          autoRficLogInfo("Database loaded successfully")
          t
        )
        prog(()
          autoRficLogError("Failed to read database file")
          nil
        )
      )
      ;; Create new database
      prog(()
        autoRficDatabase = list(nil)
        autoRficLogInfo("New database initialized")
        t
      )
    )
  )
)

;; Function to save the database to disk
procedure(autoRficSaveDatabase()
  let((fileId)
    fileId = outfile(autoRficDbFile)
    if(fileId
      prog(()
        print(autoRficDatabase fileId)
        close(fileId)
        autoRficLogInfo("Database saved successfully")
        t
      )
      prog(()
        autoRficLogError("Failed to write database file")
        nil
      )
    )
  )
)

;; Function to store a value in the database
procedure(autoRficDbStore(key value)
  let((idx)
    ;; Load database if not already loaded
    unless(boundp('autoRficDatabase)
      autoRficLoadDatabase()
    )
    
    ;; Check if key already exists
    idx = lindex(autoRficDatabase key)
    if(idx
      ;; Update existing key
      autoRficDatabase = replaceItem(value idx+1 autoRficDatabase)
      ;; Add new key-value pair
      autoRficDatabase = append(autoRficDatabase list(key value))
    )
    
    ;; Save the updated database
    autoRficSaveDatabase()
    
    value
  )
)

;; Function to retrieve a value from the database
procedure(autoRficDbRetrieve(key @optional defaultValue)
  let((idx value)
    ;; Load database if not already loaded
    unless(boundp('autoRficDatabase)
      autoRficLoadDatabase()
    )
    
    ;; Look up the key
    idx = lindex(autoRficDatabase key)
    if(idx
      ;; Return the value if found
      value = nth(idx+1 autoRficDatabase)
      ;; Return the default value if provided
      if(boundp('defaultValue) defaultValue nil)
    )
  )
)

;; Function to delete a key from the database
procedure(autoRficDbDelete(key)
  let((idx)
    ;; Load database if not already loaded
    unless(boundp('autoRficDatabase)
      autoRficLoadDatabase()
    )
    
    ;; Check if key exists
    idx = lindex(autoRficDatabase key)
    when(idx
      ;; Remove the key-value pair
      autoRficDatabase = remitem(idx autoRficDatabase)
      autoRficDatabase = remitem(idx autoRficDatabase)
      
      ;; Save the updated database
      autoRficSaveDatabase()
    )
    
    t
  )
)

;; Function to list all keys in the database
procedure(autoRficDbListKeys()
  let((keys i)
    ;; Load database if not already loaded
    unless(boundp('autoRficDatabase)
      autoRficLoadDatabase()
    )
    
    ;; Extract all keys
    keys = list()
    for(i 1 length(autoRficDatabase) 2
      keys = append(keys list(nth(i autoRficDatabase)))
    )
    
    keys
  )
)

;; Add all database functions to the namespace
autoRficDb = append(autoRficDb list(
  'load autoRficLoadDatabase
  'save autoRficSaveDatabase
  'store autoRficDbStore
  'retrieve autoRficDbRetrieve
  'delete autoRficDbDelete
  'listKeys autoRficDbListKeys
))

;; Export the database namespace
autoRficDb
