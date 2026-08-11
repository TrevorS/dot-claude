;;; early-init.el --- Pre-GUI init -*- lexical-binding: t -*-

;; The macOS 26+ native-comp toolchain fix lives at the top of init.el, not
;; here: `emacs --batch -l init.el' (make emacs-plugins) never loads this file.

;; GC: the 800KB default causes constant collections. Generous during startup,
;; dialed back (but still far above default) once running.
(setq gc-cons-threshold (* 100 1024 1024))

;; Every load/require during init regexp-matches this alist; empty it until
;; startup ends (elpaca activates dozens of packages -- tens of ms saved).
(defvar my/saved-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024)
                  gc-cons-percentage 0.2
                  file-name-handler-alist my/saved-file-name-handler-alist)))

(setq package-enable-at-startup nil)
(setq auto-save-list-file-prefix nil) ; no auto-save-list/ dir (auto-save is off in init)

(setq frame-inhibit-implicit-resize t
      inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil)

(setq default-frame-alist
      '((tool-bar-lines . 0)
        (menu-bar-lines . 0)
        (vertical-scroll-bars . nil)
        (horizontal-scroll-bars . nil)
        (internal-border-width . 10)
        (ns-transparent-titlebar . t)
        (ns-appearance . dark)))
