(define-module (kada serialize)
  #:use-module ((srfi srfi-1))
  #:use-module (ice-9 match)
  #:use-module (kada types)
  #:use-module (kada db)

  #:export (serialize-to-csv))

(define (serialize-to-csv spans)
  (string-append csv-header-row
                 (fold (lambda (span acc)
                         (string-append acc (span->csv-row span)))
                       ""
                       spans)))

(define (span->csv-row span)
  (format #f "~a;~a;~a\n"
          (ts->string (span-started span))
          (ts->string (span-ended span))
          (span-name span)))

(define csv-header-row
  "Started;Ended;Name\n")

(define (ts->string ts)
  (strftime "%c" (localtime ts)))
