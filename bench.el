;;; bench.el --- Completion style benchmark  -*- lexical-binding: t; -*-

(setq gc-cons-threshold 16777216
      load-path (cons "." load-path)
      package-user-dir (expand-file-name ".elpa"
                                         (file-name-directory load-file-name)))
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

(package-initialize)

(package-install 'quelpa)
(package-install 'hotfuzz)
(package-install 'fussy)
(package-install 'liquidmetal)
(package-install 'orderless)

(quelpa '(flx-rs
          :fetcher github :repo "jcs-elpa/flx-rs"
          :files (:defaults "bin")))
(quelpa '(fzf-native
          :fetcher github :repo "dangduc/fzf-native"
          :files (:defaults "bin")))
(quelpa '(fuz-bin
          :fetcher github :repo "jcs-elpa/fuz-bin"
          :files (:defaults "bin")))
(quelpa '(sublime-fuzzy
          :fetcher github :repo "jcs-elpa/sublime-fuzzy"
          :files (:defaults "bin")))

(setq fussy-compare-same-score-fn nil
      fussy-use-cache nil
      fussy-filter-fn #'fussy-filter-default
      fussy-score-threshold-to-filter-alist nil)

(require 'fussy)
(require 'hotfuzz-module) ; Ensure that the hotfuzz module is available
(flx-rs-load-dyn)
(fzf-native-load-dyn)
(fuz-bin-load-dyn)
(sublime-fuzzy-load-dyn)

(defun do-complete (s table)
  (let* ((meta (completion-metadata s table nil))
         (candidates (completion-all-completions s table nil (length s) meta))
         (sortfun (alist-get 'display-sort-function meta))
         (last (last candidates)))
    (when (numberp (cdr last)) (setcdr last nil))
    (when sortfun (setq candidates (funcall sortfun candidates)))
    candidates))

(let ((completions (with-temp-buffer
                     (insert-file-contents "completions")
                     (split-string (buffer-string) "\n" t)))
      (needles '("f" "cldbi" "emacs" "nixemacsnix"))
      (completion-ignore-case t)
      (styles `(basic
                hotfuzz
                flex
                (fussy . flx-score)
                ;; (fussy . flx-rs-score) ; Panics!
                (fussy . ,#'fussy-fzf-native-score)
                (fussy . ,#'fussy-fuz-bin-score)
                ;; (fussy . ,#'fussy-liquidmetal-score) ; Signals error!
                ;; (fussy . ,#'fussy-sublime-fuzzy-score) ; Panics!
                (fussy . ,#'fussy-hotfuzz-score)
                orderless)))
  (message "Benchmarking on list of %s possible completions\n\twith median length %s."
           (length completions)
           (/ (cl-loop for s in completions sum (length s)) (length completions)))

  ;; Warmup, also sources required Lisp files
  (mapc (lambda (style) 
          (let ((completion-styles (list (if (consp style) (car style) style)))
                (fussy-score-fn (cdr-safe style)))
            (do-complete "x" completions)))
        styles)

  (mapc
   (lambda (style)
     (let ((completion-styles (list (if (consp style) (car style) style)))
           (fussy-score-fn (cdr-safe style)))
       (garbage-collect)
       (message
        "style %s: %s" style
        (benchmark-run 5
          (mapc (lambda (s) (do-complete s completions)) needles)))))
     styles))
