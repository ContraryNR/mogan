
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : view-widgets.scm
;; DESCRIPTION : the view widgets
;; COPYRIGHT   : (C) 2013  Joris van der Hoeven
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(texmacs-module (texmacs menus view-widgets))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Retina settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(tm-define (get-retina-preference which)
  (if (cpp-has-preference? which)
    (get-preference which)
    (cond ((== which "retina-scale")
           (cond ((== (get-retina-scale) 1.0) "1")
                 ((== (get-retina-scale) 2.0) "2")
                 (else (number->string (get-retina-scale)))
           ) ;cond
          ) ;
          (else "")
    ) ;cond
  ) ;if
) ;tm-define

(tm-define (set-retina-preference which val) (set-preference which val))

(tm-define (get-retina-boolean-preference which)
  (if (cpp-has-preference? which)
    (preference-on? which)
    (cond ((== which "retina-factor") (== (get-retina-factor) 2))
          ((== which "retina-zoom") (== (get-retina-zoom) 2))
          ((== which "retina-icons") (== (get-retina-icons) 2))
          (else #f)
    ) ;cond
  ) ;if
) ;tm-define

(tm-define (set-retina-boolean-preference which on?)
  (set-retina-preference which (if on? "on" "off"))
) ;tm-define

(tm-define (reset-retina-preferences)
  (reset-preference "retina-factor")
  (reset-preference "retina-zoom")
  (reset-preference "retina-icons")
  (reset-preference "retina-scale")
) ;tm-define

;; 高分屏设置字段表构造（平台分支 + gui theme 条件）。
;; toggle 字段用空串占位 options（field_tree_to_qml 跳过非 compound 的 options）；
;; enum 字段带选项列表。value 统一 string：toggle 为 "on"/"off"，enum 为 "1"/... 。

(define (retina-settings-form-tree)
  (let ((scale-opts '("1" "1.2" "1.5" "2" "")))
    (if (os-macos?)
      `(form (toggle ,(translate "Use retina fonts:")
               ,(pref-retina-factor)
               ,""
               ,(if (get-retina-boolean-preference (pref-retina-factor))
                  "on"
                  "off"))
         ,@(if (!= (get-preference "gui theme") "")
             `((enum ,(translate "Scale graphical interface:")
                 ,(pref-retina-scale)
                 ,scale-opts
                 ,(get-retina-preference (pref-retina-scale))))
             '()))
      `(form (toggle ,(translate "Double the zoom factor for TeXmacs documents:")
               ,(pref-retina-zoom)
               ,""
               ,(if (get-retina-boolean-preference (pref-retina-zoom))
                  "on"
                  "off"))
         (toggle ,(translate "Use high resolution icons:")
           ,(pref-retina-icons)
           ,""
           ,(if (get-retina-boolean-preference (pref-retina-icons)) "on" "off"))
         ,@(if (!= (get-preference "gui theme") "")
             `((enum ,(translate "Scale of the graphical user interface:")
                 ,(pref-retina-scale)
                 ,scale-opts
                 ,(get-retina-preference (pref-retina-scale))))
             '()))
    ) ;if
  ) ;let
) ;define

(tm-define (open-retina-settings-window)
  (:interactive #t)
  (let loop
    ()
    (with result
      (cpp-retina-settings-dialog (stree->tree (retina-settings-form-tree)))
      (with stree
        (tree->stree result)
        (cond ((null? (cdr stree)) (void))
              ((string? (cadr stree)) (reset-retina-preferences) (loop))
              (else (for-each (lambda (kv) (set-retina-preference (cadr kv) (caddr kv)))
                      (cdr stree)
                    ) ;for-each
                (notify-restart)
              ) ;else
        ) ;cond
      ) ;with
    ) ;with
  ) ;let
) ;tm-define

(tm-define (open-retina-settings)
  (:interactive #t)
  (open-retina-settings-window)
) ;tm-define
