(define-module (kada db)
  #:use-module (ice-9 match)
  #:use-module (kada types)
  #:use-module (sqlite3)

  #:export (db-init!

            db-insert-mark!
            db-create-span!
            db-query-mark
            db-query-last-enter-mark
            db-query-lone-marks

            db-query-spans))

;;; Initialization code
(define default-data-dir
  (string-append (getenv "HOME") "/.local/share"))

(define (mkdir-rec path)
  (let loop ((parts (string-split path #\/))
             (parent ""))
    (match parts
      (() #t)
      ((dir rest ...)
       (let ((dir (string-append parent "/" dir)))
         (unless (file-exists? dir)
           (display dir)
           (newline)
           (mkdir dir))
         (loop rest dir))))))

(define db
  (with-exception-handler
   (lambda (ex)
     (format (current-error-port)
             "Could not create the database: ~s"
             ex)
     #f)
   (lambda ()
     (let* ((data-dir (match (getenv "XDG_DATA_DIR")
                        (#f default-data-dir)
                        ("" default-data-dir)
                        (dir dir)))
            (kada-dir (string-append data-dir "/kada")))
       (unless (file-exists? kada-dir)
         (mkdir-rec kada-dir))
       (sqlite-open (string-append kada-dir "/kada.db"))))
   #:unwind? #t))

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

(define (db-init!)
  (db-create-marks-table!)
  (db-create-spans-table!))

;;; Prepared queries
(define-syntax define-prepared
  (syntax-rules ()
    ((_ name query)
     (define name
       (delay (sqlite-prepare db query))))))

(define-prepared db-prep-insert-mark
  "INSERT INTO Marks (Name, Timestamp, Description, Enter)
                   VALUES (?, ?, ?, ?)
                   RETURNING Id")

(define-prepared db-prep-query-mark
  "SELECT Id, Name, Timestamp, Description, Enter FROM Marks
                   WHERE Name = ?")

(define-prepared db-prep-query-last-enter-mark
  "SELECT Id, Name, Timestamp, Description, Enter from Marks AS m
                   WHERE Enter = 1
                   AND
                   (SELECT COUNT(*) FROM Spans WHERE StartId = m.Id) = 0
                   ORDER BY Timestamp DESC LIMIT 1")

(define-prepared db-prep-query-insert-span
  "INSERT INTO Spans(Name, StartId, EndId)
                   VALUES (?, ?, ?)")

(define-prepared db-prep-query-spans
  ;; NOTE: Use ascending order for the `ORDER BY' clause, since we will be
  ;; prepending each row to the accumulator, and we want to have the latest
  ;; spans come first
  "SELECT s.Name, sm.Timestamp AS StartTs, em.Timestamp AS EndTs
                  FROM Spans AS s
                  JOIN Marks AS sm ON s.StartId = sm.Id
                  JOIN Marks AS em ON s.EndId = em.Id
                  ORDER BY StartTs ASC")

(define-prepared db-prep-query-lone-marks
  "SELECT Id, Name, Timestamp, Description
                  FROM Marks AS m
                  WHERE Enter = 1
                  AND
                  (SELECT COUNT(*)
                   FROM Spans AS s
                   WHERE m.Id = s.StartId) = 0;")

;;; Procedures
(define (use-prepared stmt . args)
  (let ((stmt (force stmt)))
    (apply sqlite-bind-arguments stmt args)
    (define result (sqlite-fold cons '() stmt))
    (sqlite-reset stmt)
    result))

(define (db-insert-mark! mark)
  (match (use-prepared db-prep-insert-mark
                (mark-name mark)
                (mark-timestamp mark)
                (mark-description mark)
                (bool-to-bit (mark-enter? mark)))
         ((#(id)) id)))

(define (db-query-mark name)
  (match (use-prepared db-prep-query-mark name)
         (() #f)
         ((#(ids names timestamps descriptions enters?) ...)
          (map mark-from-row
               names
               timestamps
               descriptions
               enters?))))

(define (db-create-span! start end)
    (use-prepared db-prep-query-insert-span
                  (mark-name start)
                  (mark-id start)
                  (mark-id end)))

(define (db-query-last-enter-mark)
  (match (use-prepared db-prep-query-last-enter-mark)
    (() #f)
    ((row) (mark-from-row row))))

(define (db-query-spans)
  (map (match-lambda
         (#(name started ended)
          (make-span name started ended)))
       (use-prepared db-prep-query-spans)))

(define (db-query-lone-marks)
  (map (match-lambda
         (#(id name timestamp description)
         (make-mark id name timestamp description #t)))
       (use-prepared db-prep-query-lone-marks)))

;; Utility procedures
(define (bool-to-bit b)
  (if b 1 0))

(define mark-from-row
  (match-lambda
    ((id name timestamp description enter?)
     (make-mark id
                name
                timestamp
                description
                (= enter? 1)))
    (#(id name timestamp description enter?)
     (make-mark id
                name
                timestamp
                description
                (= enter? 1)))))
