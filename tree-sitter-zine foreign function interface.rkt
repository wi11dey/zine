#lang racket/base

(require ffi/unsafe
         ffi/unsafe/define
         (file "tree-sitter foreign function interface.rkt"))

(provide tree_sitter_zine
         parse-zine-string)

;; Load the tree-sitter-zine library
(define zine-lib
  (ffi-lib "/Users/wdey/zine/formal language/tree-sitter-zine/libtree-sitter-zine.dylib"))

;; Define the zine language function
(define-ffi-definer define-zine zine-lib)

(define-zine tree_sitter_zine
  (_fun -> _ts-language-pointer))

;; Helper function to parse Zine code
(define (parse-zine-string source)
  (define parser (ts_parser_new))
  (define language (tree_sitter_zine))
  (ts_parser_set_language parser language)
  
  (define tree (ts_parser_parse_string parser #f source (string-length source)))
  
  (values tree parser)) ;; Return both so caller can clean up

;; Test module
(module+ main
  (printf "Testing tree-sitter-zine FFI bindings...\n")
  
  ;; Get the Zine language
  (define lang (tree_sitter_zine))
  (printf "Zine language loaded: ~a\n" lang)
  
  ;; Create a parser and set the language
  (define parser (ts_parser_new))
  (define lang-set? (ts_parser_set_language parser lang))
  (printf "Language set successfully: ~a\n" lang-set?)
  
  ;; Parse some Zine code
  (define test-code "Hello, world!")
  (define tree (ts_parser_parse_string parser #f test-code (string-length test-code)))
  (printf "Tree created: ~a\n" tree)
  
  ;; Get the root node and inspect it
  (when tree
    (with-handlers ([exn:fail? (lambda (e)
                                 (printf "Error getting root node: ~a\n" (exn-message e)))])
      (define root (ts_tree_root_node tree))
      (printf "Root node obtained\n")
      
      ;; Check if node is valid
      (printf "Node context: ~a\n" (ts-node-context root))
      
      (with-handlers ([exn:fail? (lambda (e)
                                   (printf "Error getting node type: ~a\n" (exn-message e)))])
        (define node-type (ts_node_type root))
        (printf "Root node type: ~a\n" node-type))
      
      (with-handlers ([exn:fail? (lambda (e)
                                   (printf "Error getting node string: ~a\n" (exn-message e)))])
        (define node-str (ts_node_string root))
        (printf "Root node string representation:\n~a\n" node-str))
      
      ;; Walk the tree
      (printf "\nTree structure:\n")
      (with-handlers ([exn:fail? (lambda (e)
                                   (printf "Error walking tree: ~a\n" (exn-message e)))])
        (walk-tree root)))
    
    ;; Clean up
    (ts_tree_delete tree))
  
  (ts_parser_delete parser)
  (printf "\nTest complete!\n"))