(define-module (kada db)
  #:use-module (ice-9 match)
  #:use-module (kada types)
  #:use-module (sqlite3)

  #:export (db-insert-mark!
            db-create-span!
            db-query-mark
            db-query-last-enter-mark
            db-query-lone-marks

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
    (unless (file-exists? kada-dir)
      (mkdir-rec kada-dir))
    (sqlite-open (string-append kada-dir "/kada.db"))))

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

(db-init!)

;;; Prepared queries
(define db-prep-insert-mark
  (sqlite-prepare db
                  "INSERT INTO Marks (Name, Timestamp, Description, Enter)
                   VALUES (?, ?, ?, ?)
                   RETURNING Id"))

(define db-prep-query-mark
  (sqlite-prepare db
                  "SELECT Id, Name, Timestamp, Description, Enter FROM Marks
                   WHERE Name = ?"))

(define db-prep-query-last-enter-mark
  (sqlite-prepare db
                  "SELECT Id, Name, Timestamp, Description, Enter from Marks AS m
                   WHERE Enter = 1
                   AND
                   (SELECT COUNT(*) FROM Spans WHERE StartId = m.Id) = 0
                   ORDER BY Timestamp DESC LIMIT 1"))

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

(define db-prep-query-lone-marks
  (sqlite-prepare db
                  "SELECT Id, Name, Timestamp, Description
                  FROM Marks AS m
                  WHERE Enter = 1
                  AND
                  (SELECT COUNT(*)
                   FROM Spans AS s
                   WHERE m.Id = s.StartId) = 0;"))

;;; Procedures
(define (use-prepared stmt . args)
  (apply sqlite-bind-arguments stmt args)
  (define result (sqlite-fold cons '() stmt))
  (sqlite-reset stmt)
  result)

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

(define (mkdir-rec path)
  (let loop ((parts (string-split path #\/))
             (parent ""))
    (match parts
           (() #t)
           ((dir rest ...)
            (let ((dir (string-append parent "/" dir)))
              (unless (file-exists? dir)
                (mkdir dir))
              (loop rest dir))))))
