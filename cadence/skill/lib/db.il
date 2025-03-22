;; db.il - Database access functions for auto_rfic
;; This file contains functions for managing database operations in Virtuoso

;; Initialize the database namespace
unless(boundp('autoRficDb)
    autoRficDb = makeTable("db" nil)
)

;; Database access functions
defun(autoRficLoadDatabase (libName cellName viewName @optional (mode "r"))
    let((cv)
        ;; Check if library exists
        unless(ddGetObj(libName)
            error("Library %s not found" libName))
        
        ;; Try to open the cellview
        cv = dbOpenCellViewByType(libName cellName viewName nil mode)
        unless(cv
            error("Failed to open cellview %s:%s:%s" libName cellName viewName))
        
        cv
    )
)

;; Function to save a cell view
defun(autoRficSaveDatabase (cv)
    let((result)
        when(cv
            result = dbSave(cv)
            when(result
                dbClose(cv)
            )
        )
        result
    )
)

;; Function to close a cell view
defun(autoRficCloseDatabase (cv)
    when(cv
        dbClose(cv)
    )
    t
)

;; Function to check if a cell view is open
defun(autoRficIsDatabaseOpen (cv)
    let((result)
        result = dbFindOpenCellView(cv~>libName cv~>cellName cv~>viewName)
        if(result t nil)
    )
)

;; Database save trigger function
procedure(autoRficDbSaveTrigger(cellView)
  let((cellName viewName libName)
    when(cellView
      cellName = dbGetCellName(cellView)
      viewName = dbGetViewName(cellView)
      libName = dbGetLibName(cellView)
      
      autoRficLogInfo(sprintf(nil "Cell saved: %s %s %s" libName cellName viewName))
      
      ;; Perform any post-save actions here
      ;; For example, run DRC after save
      when(viewName == "layout" && autoRficGetParameter('runDrcAfterSave nil)
        when(boundp('autoRficDrc)
          when(get(autoRficDrc 'runDrc)
            autoRficLogInfo("Running DRC after save")
            funcall(get(autoRficDrc 'runDrc) cellView)
          )
        )
      )
    )
    t
  )
)

;; Add all database functions to the namespace
autoRficDb['loadDatabase] = 'autoRficLoadDatabase
autoRficDb['saveDatabase] = 'autoRficSaveDatabase
autoRficDb['closeDatabase] = 'autoRficCloseDatabase
autoRficDb['isDatabaseOpen] = 'autoRficIsDatabaseOpen

;; Export the database namespace
autoRficDb
