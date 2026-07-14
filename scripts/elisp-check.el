;;; elisp-check.el --- parens + byte-compile lint for config elisp -*- lexical-binding: t -*-

;; Usage: emacs --batch -l scripts/elisp-check.el FILE.el...
;; Fails (exit 1) on unbalanced expressions or byte-compile warnings/errors.
;; free-vars/unresolved/noruntime warnings are suppressed: config files
;; reference package symbols that aren't loadable in batch.

;; Load elpaca's use-package integration when available so `:ensure (:wait t)'
;; parses instead of raising a use-package error. Absent (e.g. CI), those
;; keywords degrade to unresolved warnings, which are suppressed anyway.
(let ((builds (expand-file-name "emacs/elpaca/builds"
                                (or (getenv "XDG_DATA_HOME") "~/.local/share"))))
  (dolist (pkg '("use-package" "elpaca" "elpaca-use-package"))
    (let ((dir (expand-file-name pkg builds)))
      (when (file-directory-p dir)
        (push dir load-path))))
  (when (require 'elpaca-use-package nil t)
    (elpaca-use-package-mode)))
;; use-package's expansion attempts a compile-time `require' of each declared
;; package and prints "Cannot load X" when absent -- harmless (the packages
;; aren't under check), and pre-commit hides hook output on success.

(require 'bytecomp)

(defvar elisp-check--elc (make-temp-file "elisp-check" nil ".elc"))
(setq byte-compile-dest-file-function (lambda (_) elisp-check--elc))
(setq byte-compile-warnings '(not free-vars unresolved noruntime))

(let ((fail nil))
  (dolist (file command-line-args-left)
    (with-temp-buffer
      (insert-file-contents file)
      (emacs-lisp-mode)
      (condition-case err
          (check-parens)
        (error (message "%s: unbalanced expression: %s" file err)
               (setq fail t))))
    (unless (byte-compile-file file)
      (setq fail t)))
  (when-let* ((log (get-buffer byte-compile-log-buffer)))
    (with-current-buffer log
      (goto-char (point-min))
      (while (re-search-forward "^.*:[0-9]+:[0-9]+: \\(?:Warning\\|Error\\).*$" nil t)
        (message "%s" (match-string 0))
        (setq fail t))))
  (delete-file elisp-check--elc)
  (kill-emacs (if fail 1 0)))
