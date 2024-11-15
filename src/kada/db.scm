(define-module (kada db)
  #:use-module (ice-9 match)
  #:use-module (kada types)
  #:use-module (sqlite3)

  #:export (db-insert-entry!
            db-query-entry))

;;; Initialization code
(define db (sqlite-open "kada.db"))

(db-init)

;;; Procedures
(define (db-init)
  (db-create-entries-table!)
  (db-create-spans-table!))

(define (db-create-entries-table!)
  (sqlite-exec db "CREATE TABLE IF NOT EXISTS Entries (
           Id INTEGER PRIMARY KEY AUTOINCREMENT,
           Name TEXT NOT NULL,
           Timestamp INTEGER DEFAULT (unixepoch()) NOT NULL,
           Description TEXT)"))

(define (db-create-spans-table!)
  (sqlite-exec db "CREATE TABLE IF NOT EXISTS Spans (
           Id INTEGER PRIMARY KEY AUTOINCREMENT,
           Name TEXT NOT NULL,
           StartId INTEGER NOT NULL,
           EndId INTEGER,
           FOREIGN KEY(StartId) REFERENCES Entries(Id),
           FOREIGN KEY(EndId) REFERENCES Entries(Id))"))

(define db-prep-insert-entry
  (sqlite-prepare db
                  "INSERT INTO Entries (Name, Timestamp, Description)
                   VALUES (?, ?, ?)"))

(define db-prep-query-entry
  (sqlite-prepare db
                  "SELECT Name, Timestamp, Description FROM Entries
                   WHERE Name = ?"))

(define db-prep-query-latest-entry
  (sqlite-prepare db
                  "SELECT Name, Timestamp, Description from Entries
                   ORDER BY Timestamp DESC LIMIT 1"))

(define (use-prepared stmt . args)
  (apply sqlite-bind-arguments stmt args)
  (define result (sqlite-fold cons '() stmt))
  (sqlite-reset stmt)
  result)

(define (db-insert-entry! entry)
  (use-prepared db-prep-insert-entry
                (entry-name entry)
                (entry-timestamp entry)
                (entry-description entry)))

(define (db-query-entry name)
  (match (use-prepared db-prep-query-entry name)
    (() #f)
    ((#(name timestamp description) ...)
     (map make-entry name timestamp description))))

(define (db-query-latest-entry)
  (match (use-prepared db-prep-query-latest-entry)
    (() #f)
    ((entry) entry)))
