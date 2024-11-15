(define-module (kada types)
  #:use-module ((srfi srfi-9))
  #:export (make-entry
            entry?
            entry-name
            entry-timestamp
            entry-description))

(define-record-type <entry>
  (make-entry name timestamp description)
  entry?
  (name entry-name)
  (timestamp entry-timestamp)
  (description entry-description))
