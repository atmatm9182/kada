(define-module (kada db)
  #:use-module (kada types)
  #:use-module (sqlite3)

  #:export (db-insert-entry!))

(define (db-init)
   (db-create-entries-table))

(define (db-create-entries-table)
  (sqlite-exec db "CREATE TABLE IF NOT EXISTS Entries (
           Id INTEGER PRIMARY KEY AUTOINCREMENT,
           Name TEXT NOT NULL,
           Timestamp INTEGER DEFAULT (unixepoch()) NOT NULL,
           Description TEXT)"))

(define db (sqlite-open "kada.db"))

(db-init)

(define db-prep-insert-entry
  (sqlite-prepare db
                  "INSERT INTO Entries (Name, Timestamp, Description)
                   VALUES (?, ?, ?)"))

(define (db-insert-entry! entry)
  (sqlite-bind-arguments db-prep-insert-entry
                         (entry-name entry)
                         (entry-timestamp entry)
                         (entry-description entry))
  (sqlite-fold cons '() db-prep-insert-entry))
