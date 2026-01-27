#lang racket/base

(require ffi/unsafe
         ffi/unsafe/define)

(provide (all-defined-out))

;; Load the tree-sitter library
(define tree-sitter-lib
  (ffi-lib "/opt/homebrew/lib/libtree-sitter.dylib"))

;; Define foreign types
(define-ffi-definer define-ts tree-sitter-lib)

;; Forward declarations for C types
(define _ts-parser-pointer (_cpointer 'TSParser))
(define _ts-tree-pointer (_cpointer 'TSTree))
(define _ts-language-pointer (_cpointer 'TSLanguage))

;; TSPoint structure
(define-cstruct _ts-point
  ([row _uint32]
   [column _uint32]))

;; TSNode structure - 32 bytes on 64-bit systems
(define-cstruct _ts-node
  ([context (_array _uint32 4)]  ;; 16 bytes
   [id _pointer]                 ;; 8 bytes  
   [tree _pointer]))             ;; 8 bytes

;; TSTreeCursor structure
(define-cstruct _ts-tree-cursor
  ([tree _pointer]
   [id _pointer]
   [context (_array _uint32 2)]))

;; Parser functions
(define-ts ts_parser_new
  (_fun -> _ts-parser-pointer))

(define-ts ts_parser_delete
  (_fun _ts-parser-pointer -> _void))

(define-ts ts_parser_set_language
  (_fun _ts-parser-pointer _ts-language-pointer -> _bool))

(define-ts ts_parser_parse
  (_fun _ts-parser-pointer _ts-tree-pointer _pointer -> _ts-tree-pointer))

(define-ts ts_parser_parse_string
  (_fun _ts-parser-pointer (_or-null _ts-tree-pointer) _string _uint32 -> (_or-null _ts-tree-pointer)))

;; Tree functions
(define-ts ts_tree_delete
  (_fun _ts-tree-pointer -> _void))

(define-ts ts_tree_root_node
  (_fun _ts-tree-pointer -> _ts-node))

;; Helper to check if a node is valid
(define (ts-node-valid? node)
  (not (zero? (car (ts-node-context node)))))

(define-ts ts_tree_language
  (_fun _ts-tree-pointer -> _ts-language-pointer))

;; Node functions
(define-ts ts_node_type
  (_fun _ts-node -> _string))

(define-ts ts_node_start_byte
  (_fun _ts-node -> _uint32))

(define-ts ts_node_end_byte
  (_fun _ts-node -> _uint32))

(define-ts ts_node_start_point
  (_fun _ts-node -> _ts-point))

(define-ts ts_node_end_point
  (_fun _ts-node -> _ts-point))

(define-ts ts_node_child_count
  (_fun _ts-node -> _uint32))

(define-ts ts_node_child
  (_fun _ts-node _uint32 -> _ts-node))

(define-ts ts_node_named_child_count
  (_fun _ts-node -> _uint32))

(define-ts ts_node_named_child
  (_fun _ts-node _uint32 -> _ts-node))

(define-ts ts_node_parent
  (_fun _ts-node -> _ts-node))

(define-ts ts_node_next_sibling
  (_fun _ts-node -> _ts-node))

(define-ts ts_node_prev_sibling
  (_fun _ts-node -> _ts-node))

(define-ts ts_node_next_named_sibling
  (_fun _ts-node -> _ts-node))

(define-ts ts_node_prev_named_sibling
  (_fun _ts-node -> _ts-node))

(define-ts ts_node_is_named
  (_fun _ts-node -> _bool))

(define-ts ts_node_is_null
  (_fun _ts-node -> _bool))

(define-ts ts_node_is_missing
  (_fun _ts-node -> _bool))

(define-ts ts_node_is_extra
  (_fun _ts-node -> _bool))

(define-ts ts_node_has_error
  (_fun _ts-node -> _bool))

(define-ts ts_node_string
  (_fun _ts-node -> _string))

;; TreeCursor functions
(define-ts ts_tree_cursor_new
  (_fun _ts-node -> _ts-tree-cursor))

(define-ts ts_tree_cursor_delete
  (_fun _ts-tree-cursor-pointer -> _void))

(define-ts ts_tree_cursor_goto_first_child
  (_fun _ts-tree-cursor-pointer -> _bool))

(define-ts ts_tree_cursor_goto_next_sibling
  (_fun _ts-tree-cursor-pointer -> _bool))

(define-ts ts_tree_cursor_goto_parent
  (_fun _ts-tree-cursor-pointer -> _bool))

(define-ts ts_tree_cursor_current_node
  (_fun _ts-tree-cursor-pointer -> _ts-node))

;; Language functions
(define-ts ts_language_symbol_count
  (_fun _ts-language-pointer -> _uint32))

(define-ts ts_language_symbol_name
  (_fun _ts-language-pointer _uint16 -> _string))

(define-ts ts_language_symbol_type
  (_fun _ts-language-pointer _uint16 -> _int))

;; Helper functions
(define (parse-string parser language source)
  (ts_parser_set_language parser language)
  (ts_parser_parse_string parser #f source (string-length source)))

(define (node-children node)
  (for/list ([i (in-range (ts_node_child_count node))])
    (ts_node_child node i)))

(define (node-named-children node)
  (for/list ([i (in-range (ts_node_named_child_count node))])
    (ts_node_named_child node i)))

(define (walk-tree node [indent 0])
  (unless (ts_node_is_null node)
    (printf "~a~a [~a:~a - ~a:~a]\n" 
            (make-string indent #\space)
            (ts_node_type node)
            (ts-point-row (ts_node_start_point node))
            (ts-point-column (ts_node_start_point node))
            (ts-point-row (ts_node_end_point node))
            (ts-point-column (ts_node_end_point node)))
    (for ([child (node-children node)])
      (walk-tree child (+ indent 2)))))

;; Test creating a parser
(module+ main
  (printf "Testing tree-sitter FFI bindings...\n")
  
  ;; Create a parser
  (define parser (ts_parser_new))
  (printf "Parser created: ~a\n" parser)
  
  ;; Try to parse without a language (should return null)
  (define tree (ts_parser_parse_string parser #f "test code" (string-length "test code")))
  (printf "Tree without language: ~a\n" tree)
  
  ;; Clean up
  (when tree
    (ts_tree_delete tree))
  (ts_parser_delete parser)
  
  (printf "Test complete!\n"))