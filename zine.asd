(asdf:defsystem "zine"
  :description "A place for creativity."
  :author ""
  :license ""
  :version "0.1.0"
  :depends-on ("crisp"
               "lem-ncurses")
  :serial t
  :components ((:file "package")
               (:file "main"))
  :build-operation "program-op"
  :build-pathname "build/zine"
  :entry-point "zine:main")
