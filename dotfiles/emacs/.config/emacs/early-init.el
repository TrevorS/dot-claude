;;; early-init.el --- Pre-GUI init -*- lexical-binding: t -*-

;; macOS 26+ (Darwin 25+): bundled libgccjit derives -mmacosx-version-min as
;; "darwin major - 9" (e.g. 18.0 on Darwin 27), a version Apple clang rejects
;; since the 15 -> 26 jump. Pin a real version so native comp can compile.
(when (and (eq system-type 'darwin)
           (>= (string-to-number operating-system-release) 25))
  (setq native-comp-driver-options '("-mmacosx-version-min=26.0")))

;; GC: the 800KB default causes constant collections. Generous during startup,
;; dialed back (but still far above default) once running.
(setq gc-cons-threshold (* 100 1024 1024))
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024)
                  gc-cons-percentage 0.2)))

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
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
