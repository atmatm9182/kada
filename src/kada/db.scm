(define-module (kada db)
  #:use-module (ice-9 match)
  #:use-module (kada types)
  #:use-module (sqlite3)

  #:export (db-insert-mark!
            db-create-span!
            db-query-mark
            db-query-last-enter-mark

            db-query-spans))

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

(define (db-init!)
  (db-create-marks-table!)
  (db-create-spans-table!))

(db-init!)

;;; Prepared queries
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

(define db-prep-query-last-enter-mark
  (sqlite-prepare db
                  "SELECT Name, Timestamp, Description, Enter from Marks
                   WHERE Enter = 1
                   ORDER BY Timestamp DESC LIMIT 1"))

(define db-prep-query-last-two-marks
  (sqlite-prepare db
                  "SELECT Name, Timestamp, Description, Enter, Id from Marks
                   WHERE Name = ?
                   ORDER BY Timestamp DESC LIMIT 2"))

(define db-prep-query-insert-span
  (sqlite-prepare db
                  "INSERT INTO Spans(Name, StartId, EndId)
                   VALUES (?, ?, ?)"))

(define db-prep-query-spans
  ;; NOTE: Use ascending order for the `ORDER BY' clause, since we will be
  ;; prepending each row to the accumulator, and we want to have the latest
  ;; spans come first
  (sqlite-prepare db
                  "SELECT s.Name, sm.Timestamp AS StartTs, em.Timestamp AS EndTs
                  FROM Spans AS s
                  JOIN Marks AS sm ON s.StartId = sm.Id
                  JOIN Marks AS em ON s.EndId = em.Id
                  ORDER BY StartTs ASC"))

;;; Procedures
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
         ((#(names timestamps descriptions enters?) ...)
          (map mark-from-row
               names
               timestamps
               descriptions
               enters?))))

(define (db-query-last-two-marks name)
  (match (use-prepared db-prep-query-last-two-marks name)
         (() #f)
         ((single) #f)
         ((rows ...) (map
                       (lambda (row)
                         (let* ((rov (reverse (vector->list row)))
                                (mark (mark-from-row (reverse (cdr rov))))
                                (id (car rov)))
                           (cons id mark)))
                         rows))))

(define (db-create-span! name)
  (let* ((ms (db-query-last-two-marks name))
         (fst (car ms))
         (snd (cadr ms))
         (marks (cond
                  ((and (mark-enter? (cdr fst)) (mark-enter? (cdr snd)))
                   (error "Both '~a' marks are 'enter' marks"))
                  ((mark-enter? (cdr fst)) (cons fst snd))
                  (else (cons snd fst)))))
    (use-prepared db-prep-query-insert-span
                  name
                  (car fst)
                  (car snd))))

(define (db-query-last-enter-mark)
  (match (use-prepared db-prep-query-last-enter-mark)
    (() #f)
    ((row) (mark-from-row row))))

(define (db-query-spans)
  (map (match-lambda
         (#(name started ended)
          (make-span name started ended)))
       (use-prepared db-prep-query-spans)))

;; Utility procedures
(define (bool-to-bit b)
  (if b 1 0))

(define mark-from-row
  (match-lambda
    ((name timestamp description enter?)
     (make-mark name
                timestamp
                description
                (= enter? 1)))
    (#(name timestamp description enter?)
     (make-mark name
                timestamp
                description
                (= enter? 1)))))
