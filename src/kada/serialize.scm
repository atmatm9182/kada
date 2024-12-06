(define-module (kada serialize)
  #:use-module (ice-9 match)
  #:use-module (kada types)
  #:use-module (kada db)

  #:export (serialize-to-csv-buf))

(define (serialize-to-csv-buf spans)
  (string-append csv-header-row
                 (fold string-append "" span->csv-row)))

(define (span->csv-row span)
  (format #f "%s;%s;%s\n"
          (ts->string (span-start span))
          (ts->string (span-end span))
          (span-name span)))

(define csv-header-row
  "Started;Ended;Name\n")

(define (ts->string ts)
  (strftime "%c" (localtime ts)))
