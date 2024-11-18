(define-module (kada types)
  #:use-module ((srfi srfi-9))
  #:export (make-mark
            mark?
            mark-name
            mark-timestamp
            mark-description
            mark-enter?))

(define-record-type <mark>
  (make-mark name timestamp description enter?)
  mark?
  (name mark-name)
  (timestamp mark-timestamp)
  (description mark-description)
  (enter? mark-enter?))
