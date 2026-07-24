(require "asdf")

(let ((quicklisp-setup (or (uiop:getenv-pathname "QUICKLISP_SETUP")
			   (probe-file (merge-pathnames "quicklisp/setup.lisp"
							(user-homedir-pathname)))
			   (probe-file (merge-pathnames ".quicklisp/setup.lisp"
							(user-homedir-pathname))))))
  (unless quicklisp-setup
    (error "Quicklisp was not found. Set QUICKLISP_SETUP to setup.lisp."))
  (load quicklisp-setup))

(let* ((script (uiop:truename* *load-pathname*))
       (root (uiop:pathname-parent-directory-pathname
              (uiop:pathname-directory-pathname script))))
  (ensure-directories-exist (merge-pathnames "build/" root))
  (asdf:load-asd (merge-pathnames "crisp/crisp.asd" root))
  (asdf:load-asd (merge-pathnames "zine.asd" root))
  (asdf:make "zine"))
