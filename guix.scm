(use-modules (guix)
             (guix build-system guile)
             (guix git-download)
             ((guix licenses) #:prefix license:)

             (gnu packages version-control)
             (gnu packages base)
             (gnu packages bash)
             (gnu packages sqlite)
             (gnu packages guile))

(define vcs-file?
  (or (git-predicate (current-source-directory))
      (const #t)))
(define-public kada
  (package
   (name "kada")
   (version "0.1.0")
   (source (local-file "." "kada-checkout"
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
   (native-inputs
    (list guile-3.0
          git
          coreutils))
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
