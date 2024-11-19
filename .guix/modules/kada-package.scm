(define-module (kada-package)
  #:use-module (guix)
  #:use-module (guix build-system guile)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages guile))

(define vcs-file?
  (or (git-predicate (dirname (dirname (current-source-directory))))
      (const #t)))

(define-public kada
  (package
   (name "kada")
   (version "0.1.0")
   (source (local-file "../.." "kada-checkout"
                       #:recursive? #t
                       #:select? vcs-file?))
   (build-system guile-build-system)
   (arguments
    '(#:source-directory
      "src"
      #:phases
      (modify-phases %standard-phases
                     (add-after 'build 'install
                                (lambda* (#:key outputs #:allow-other-keys)
                                         (install-file "./bin/kada" (string-append (assoc-ref outputs
                                                                                              "out")
                                                                                   "/bin"))))
                     (add-after 'install 'wrap
                                (lambda* (#:key outputs #:allow-other-keys)
                                         (wrap-program (string-append (assoc-ref outputs
                                                                                 "out")
                                                                      "/bin/kada")))))))
   (propagated-inputs
    (list guile-3.0
          guile-sqlite3
          sqlite
          bash-minimal))

   (synopsis "A CLI application to record and track time spans")
   (description #f)
   (home-page #f)
   (license license:gpl3)))

kada
