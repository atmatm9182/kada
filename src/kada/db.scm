(define-module (kada db)
  #:use-module (ice-9 match)
  #:use-module (kada types)
  #:use-module (sqlite3)

  #:export (db-insert-mark!
            db-query-mark
            db-query-last-mark))

;;; Initialization code
(define default-data-dir
  (string-append (getenv "HOME") "/.local/share"))

(define db
  (let* ((data-dir (match (getenv "XDG_DATA_DIR")
                     (#f default-data-dir)
                     ("" default-data-dir)
                     (dir dir)))
         (kada-dir (string-append data-dir "/kada")))
    (when (not (file-exists? kada-dir))
      (mkdir kada-dir)) ;; TODO: parent dirs
    (sqlite-open (string-append kada-dir "/kada.db"))))

(db-init!)

;;; Procedures
(define (db-init!)
  (db-create-marks-table!)
  (db-create-spans-table!))

(define (db-create-marks-table!)
  (sqlite-exec db "CREATE TABLE IF NOT EXISTS Marks (
           Id INTEGER PRIMARY KEY AUTOINCREMENT,
           Name TEXT NOT NULL,
           Timestamp INTEGER DEFAULT (unixepoch()) NOT NULL,
           Description TEXT,
           Enter INTEGER NOT NULL)"))

(define (db-create-spans-table!)
  (sqlite-exec db "CREATE TABLE IF NOT EXISTS Spans (
           Id INTEGER PRIMARY KEY AUTOINCREMENT,
           Name TEXT NOT NULL,
           StartId INTEGER NOT NULL,
           EndId INTEGER,
           FOREIGN KEY(StartId) REFERENCES Marks(Id),
           FOREIGN KEY(EndId) REFERENCES Marks(Id))"))

(define db-prep-insert-mark
  (sqlite-prepare db
                  "INSERT INTO Marks (Name, Timestamp, Description, Enter)
                   VALUES (?, ?, ?, ?)"))

(define db-prep-query-mark
  (sqlite-prepare db
                  "SELECT Name, Timestamp, Description, Enter FROM Marks
                   WHERE Name = ?"))

(define db-prep-query-last-mark
  (sqlite-prepare db
                  "SELECT Name, Timestamp, Description, Enter from Marks
                   ORDER BY Timestamp DESC LIMIT 1"))

(define (use-prepared stmt . args)
  (apply sqlite-bind-arguments stmt args)
  (define result (sqlite-fold cons '() stmt))
  (sqlite-reset stmt)
  result)

(define (db-insert-mark! mark)
  (use-prepared db-prep-insert-mark
                (mark-name mark)
                (mark-timestamp mark)
                (mark-description mark)
                (bool-to-bit (mark-enter? mark))))

(define (db-query-mark name)
  (match (use-prepared db-prep-query-mark name)
    (() #f)
    ((#(name timestamp description enter?) ...)
     (map mark-from-row
          name
          timestamp
          description
          enter?))))

(define (db-query-last-mark)
  (match (use-prepared db-prep-query-last-mark)
    (() #f)
    ((row) (mark-from-row row))))

;; Utility procedures
(define (bool-to-bit b)
  (if b 1 0))

(define mark-from-row
  (match-lambda
    (#(name timestamp description enter?)
     (make-mark name
                timestamp
                description
                (= enter? 1)))))
