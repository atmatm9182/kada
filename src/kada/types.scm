(define-module (kada types)
  #:use-module ((srfi srfi-9))
  #:export (make-mark
            mark?
            mark-name
            mark-timestamp
            mark-description
            mark-enter?

            make-span
            span-name
            span-started
            span-ended
            span->string))

(define-record-type <mark>
  (make-mark name timestamp description enter?)
  mark?
  (name mark-name)
  (timestamp mark-timestamp)
  (description mark-description)
  (enter? mark-enter?))

(define-record-type <span>
  (make-span name started ended)
  span?
  (name span-name)
  (started span-started)
  (ended span-ended))

(define (span->string span)
  (format #f "~a - ~a : ~a"
          (ts->string (span-started span))
          (ts->string (span-ended span))
          (span-name span)))

(define (ts->string ts)
  (strftime "%c" (localtime ts)))
