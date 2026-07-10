(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package (elpaca-use-package-mode))
(setq use-package-always-ensure t)

(setq-default
 indent-tabs-mode nil        ; expandtab
 tab-width 2                 ; tabstop
 standard-indent 2
 fill-column 100)

(setq
 tab-always-indent 'complete ; TAB indents or completes
 scroll-conservatively 101   ; no jump-scroll
 scroll-margin 3
 sentence-end-double-space nil
 require-final-newline t      ; ensure EOF newline (format-on-save behavior)
 create-lockfiles nil
 make-backup-files nil
 auto-save-default nil
 use-short-answers t          ; y/n instead of yes/no
 ring-bell-function #'ignore
 echo-keystrokes 0.02
 idle-update-delay 0.25)

(column-number-mode 1)
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type t)
(dolist (h '(term-mode-hook vterm-mode-hook eshell-mode-hook
             dired-mode-hook Info-mode-hook help-mode-hook))
  (add-hook h (lambda () (display-line-numbers-mode -1))))
(global-hl-line-mode 1)
(show-paren-mode 1)
(setq show-paren-delay 0)
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)
(recentf-mode 1)
(setq recentf-max-saved-items 300)
(savehist-mode 1)                       ; command/minibuffer history (mini.visits-ish)
(save-place-mode 1)
(setq history-length 1000)
(pixel-scroll-precision-mode 1)
(setq-default line-spacing 0.15)

(fido-vertical-mode 1)                            ; vertico-style minibuffer (built in)
(when (fboundp 'which-key-mode) (which-key-mode 1)) ; key hints (built in, Emacs 30+)
(electric-pair-mode 1)                            ; auto-close brackets/quotes
(setq inhibit-startup-screen t)                   ; skip the splash

(use-package catppuccin-theme
  :custom
  (catppuccin-flavor 'mocha)   ; latte | frappe | macchiato | mocha
  :config
  (load-theme 'catppuccin :no-confirm))

(use-package evil
  :custom
  (evil-want-keybinding nil)   ; must be nil before evil loads if evil-collection is added later
  (evil-undo-system 'undo-redo) ; wire vim u / C-r to Emacs 28+ native undo-redo
  (evil-want-C-u-scroll t)      ; C-u scrolls up like vim (instead of universal-argument)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))
