;;; init.el --- Emacs config -*- lexical-binding: t -*-

;; ============================================================================
;; PLUGIN MANAGEMENT (elpaca)
;; ============================================================================

(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory
  (expand-file-name "emacs/elpaca/" (or (getenv "XDG_DATA_HOME") "~/.local/share")))
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
(elpaca-wait) ; use-package integration must be active before any use-package form below

;; Keep ~/.config/emacs clean: savefiles (recentf, history, places, ...) go to
;; ~/.local/share/emacs. Must load before recentf/savehist/save-place start below.
(use-package no-littering
  :ensure (:wait t)
  :demand t
  :init
  (setq no-littering-var-directory
        (expand-file-name "emacs/var/" (or (getenv "XDG_DATA_HOME") "~/.local/share"))
        no-littering-etc-directory
        (expand-file-name "emacs/etc/" (or (getenv "XDG_DATA_HOME") "~/.local/share")))
  :config
  (with-eval-after-load 'recentf
    (add-to-list 'recentf-exclude (regexp-quote no-littering-var-directory))
    (add-to-list 'recentf-exclude (regexp-quote no-littering-etc-directory))))

;; ============================================================================
;; CORE SETTINGS
;; ============================================================================

(setq-default
 indent-tabs-mode nil        ; expandtab
 tab-width 2                 ; tabstop
 standard-indent 2
 fill-column 100
 line-spacing 0.15)

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
 idle-update-delay 0.25
 inhibit-startup-screen t
 history-length 1000
 recentf-max-saved-items 300)

(column-number-mode 1)
(global-hl-line-mode 1)
(show-paren-mode 1)
(setq show-paren-delay 0)
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)
(recentf-mode 1)
(savehist-mode 1)                       ; command/minibuffer history
(save-place-mode 1)
(pixel-scroll-precision-mode 1)
(electric-pair-mode 1)                  ; auto-close brackets/quotes
(which-key-mode 1)                      ; key hints (built in, Emacs 30+)
(add-hook 'prog-mode-hook #'completion-preview-mode) ; inline ghost-text completion

(global-display-line-numbers-mode 1)
(dolist (h '(term-mode-hook vterm-mode-hook eshell-mode-hook
             dired-mode-hook Info-mode-hook help-mode-hook))
  (add-hook h (lambda () (display-line-numbers-mode -1))))

;; ============================================================================
;; THEME
;; ============================================================================

(use-package catppuccin-theme
  :custom
  (catppuccin-flavor 'mocha)   ; latte | frappe | macchiato | mocha
  :config
  (load-theme 'catppuccin :no-confirm))

;; ============================================================================
;; EVIL
;; ============================================================================

(use-package evil
  :custom
  (evil-want-keybinding nil)   ; must be nil before evil loads (evil-collection)
  (evil-undo-system 'undo-redo) ; wire vim u / C-r to native undo-redo
  (evil-want-C-u-scroll t)      ; C-u scrolls up like vim
  :config
  (evil-set-leader '(normal visual) (kbd "SPC")) ; leader = Space, as in nvim
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :custom
  ;; evil-collection's eglot module rebinds K to eldoc-doc-buffer in managed
  ;; buffers, shadowing evil-lookup (our hover popup). Keep K ours everywhere.
  (evil-collection-key-blacklist '("K"))
  :config
  (evil-collection-init))

;; ============================================================================
;; DIRED (vinegar style, nvim oil.nvim's -)
;; ============================================================================

;; Replace the dired buffer when navigating (oil/netrw don't accumulate buffers)
(setq dired-kill-when-opening-new-dired-buffer t)

(with-eval-after-load 'evil
  ;; - in a file buffer: dired on its directory, point on the file
  (evil-define-key 'normal 'global (kbd "-") #'dired-jump))
(with-eval-after-load 'dired
  ;; - in dired: up a directory
  (evil-define-key 'normal dired-mode-map (kbd "-") #'dired-up-directory))

;; ============================================================================
;; TMUX NAVIGATION (smart-splits.nvim protocol)
;; ============================================================================
;; tmux.conf checks the @pane-is-vim pane flag: when set it passes C-hjkl
;; through; we move between Emacs windows and hop to the tmux pane at an edge.

(defun my/tmux--set-pane-is-vim (val)
  (when (getenv "TMUX_PANE")
    (call-process "tmux" nil nil nil "set-option" "-p"
                  "-t" (getenv "TMUX_PANE") "@pane-is-vim" val)))

(my/tmux--set-pane-is-vim "1")
(add-hook 'kill-emacs-hook (lambda () (my/tmux--set-pane-is-vim "0")))
(add-hook 'suspend-hook (lambda () (my/tmux--set-pane-is-vim "0")))
(add-hook 'suspend-resume-hook (lambda () (my/tmux--set-pane-is-vim "1")))

(defun my/window-nav (move-fn tmux-flag)
  "Call MOVE-FN, or select the tmux pane toward TMUX-FLAG when at the edge."
  (condition-case nil
      (funcall move-fn)
    ;; user-error = no window in that direction (windmove is autoloaded)
    (user-error (when (getenv "TMUX_PANE")
                  (call-process "tmux" nil nil nil "select-pane" tmux-flag)))))

(defun my/window-left ()  (interactive) (my/window-nav #'windmove-left  "-L"))
(defun my/window-down ()  (interactive) (my/window-nav #'windmove-down  "-D"))
(defun my/window-up ()    (interactive) (my/window-nav #'windmove-up    "-U"))
(defun my/window-right () (interactive) (my/window-nav #'windmove-right "-R"))

(with-eval-after-load 'evil
  (evil-define-key '(normal visual motion) 'global
    (kbd "C-h") #'my/window-left
    (kbd "C-j") #'my/window-down
    (kbd "C-k") #'my/window-up
    (kbd "C-l") #'my/window-right))

;; ============================================================================
;; MINIBUFFER COMPLETION (vertico + orderless + consult)
;; ============================================================================
;; Vertico is a thin UI over native completing-read; Orderless adds
;; space-separated fuzzy matching; Consult provides mini.pick-style pickers.

(use-package vertico
  :custom
  (vertico-cycle t)
  :config
  (vertico-mode 1)
  (add-hook 'minibuffer-setup-hook #'vertico-repeat-save)) ; for <leader>P resume

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package consult
  :custom
  (consult-async-min-input 2)
  ;; search hidden paths too (dotfile repos live under .config/ etc.), skip .git
  (consult-fd-args '("fd" "--full-path" "--color=never" "--hidden" "--exclude" ".git"))
  (consult-ripgrep-args
   "rg --null --line-buffered --color=never --max-columns=1000 --path-separator /\
   --smart-case --no-heading --with-filename --line-number --search-zip\
   --hidden --glob=!.git/"))

(defun my/consult-ripgrep-cword ()
  "Ripgrep for the symbol at point (nvim <leader>*)."
  (interactive)
  (consult-ripgrep nil (thing-at-point 'symbol)))

;; Picker keymaps mirroring nvim mini.pick binds.
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    (kbd "<leader>p")  #'consult-fd            ; find files
    (kbd "<leader>b")  #'consult-buffer        ; buffers (+ recent files)
    (kbd "<leader>gg") #'consult-ripgrep       ; live grep
    (kbd "<leader>*")  #'my/consult-ripgrep-cword
    (kbd "<leader>P")  #'vertico-repeat        ; resume last picker
    (kbd "<leader>r")  #'consult-recent-file)) ; recent files (visits-ish)

;; ============================================================================
;; TREE-SITTER (TypeScript & friends)
;; ============================================================================

;; Grammars compile once into ~/.local/share/emacs/tree-sitter (needs a C compiler).
(defvar my/treesit-grammar-directory
  (expand-file-name "emacs/tree-sitter/" (or (getenv "XDG_DATA_HOME") "~/.local/share")))
(add-to-list 'treesit-extra-load-path my/treesit-grammar-directory)

(setq treesit-language-source-alist
      '((typescript "https://github.com/tree-sitter/tree-sitter-typescript" "v0.23.2" "typescript/src")
        (tsx        "https://github.com/tree-sitter/tree-sitter-typescript" "v0.23.2" "tsx/src")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "v0.23.1")
        (jsdoc      "https://github.com/tree-sitter/tree-sitter-jsdoc"      "v0.23.2")
        (json       "https://github.com/tree-sitter/tree-sitter-json"       "v0.24.8")))

(dolist (lang (mapcar #'car treesit-language-source-alist))
  (unless (treesit-language-available-p lang)
    (treesit-install-language-grammar lang my/treesit-grammar-directory)))

(setq treesit-font-lock-level 4)        ; richest tree-sitter highlighting

(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.[cm]ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.[jt]sx\\'" . tsx-ts-mode))
(add-to-list 'major-mode-remap-alist '(js-mode . js-ts-mode))
(add-to-list 'major-mode-remap-alist '(javascript-mode . js-ts-mode))
(add-to-list 'major-mode-remap-alist '(js-json-mode . json-ts-mode))

;; ============================================================================
;; ELDOC & HOVER (nvim K)
;; ============================================================================

;; Diagnostics/signatures surface after 250ms idle (nvim updatetime=250).
;; Echo area stays one line -- full docs live in the K float.
(setq eldoc-idle-delay 0.25
      eldoc-echo-area-use-multiline-p nil)

;; Default eldoc-display-in-buffer pops an *eldoc* window split on interactive
;; requests. Swap it for format-only so the buffer stays silently current for
;; the K float, K K, and M-x eldoc-doc-buffer.
(defun my/eldoc-format-doc-buffer (docs _interactive)
  "Keep the *eldoc* buffer up to date without displaying it."
  (eldoc--format-doc-buffer docs))
(remove-hook 'eldoc-display-functions #'eldoc-display-in-buffer)
(add-hook 'eldoc-display-functions #'my/eldoc-format-doc-buffer)

;; Hover docs in a floating child frame at point. Emacs 31+ supports child
;; frames on ttys, so this works inside tmux; a child-frame-less Emacs
;; (e.g. brew 30.2 fallback) gets the *eldoc* buffer in a window instead.
(use-package eldoc-box
  :commands (eldoc-box-help-at-point)
  :config
  (with-eval-after-load 'catppuccin-theme
    (set-face-background 'eldoc-box-border (catppuccin-get-color 'surface1))))

(defun my/hover-doc ()
  "Show hover docs at point in a floating frame (nvim K); K K focuses the full doc."
  (interactive)
  (cond
   ;; second consecutive K: promote the float to the *eldoc* buffer (nvim K K)
   ((and (eq last-command #'evil-lookup)
         (buffer-live-p eldoc--doc-buffer))
    (eldoc-doc-buffer t)
    (when-let* ((win (get-buffer-window eldoc--doc-buffer)))
      (select-window win)))
   ((not eldoc-mode)
    (message "No documentation here (eldoc inactive)"))
   ((or (display-graphic-p) (featurep 'tty-child-frames))
    (eldoc-box-help-at-point))
   (t (eldoc-doc-buffer t))))

(with-eval-after-load 'evil
  (setq evil-lookup-func #'my/hover-doc)) ; evil's K

;; ============================================================================
;; LSP (eglot)
;; ============================================================================

;; Format on save in LSP buffers + trim trailing whitespace everywhere
;; (nvim BufWritePre: mini.trailspace.trim + vim.lsp.buf.format).
(add-hook 'before-save-hook #'delete-trailing-whitespace)
(defun my/eglot-format-on-save ()
  (when (and (eglot-managed-p)
             (eglot-server-capable :documentFormattingProvider))
    (eglot-format-buffer)))

;; Eglot: built-in LSP client -> vtsls (same server as the nvim config; it
;; bundles its own tsserver, so it works on typescript >= 7 workspaces where
;; typescript-language-server can't find lib/tsserver.js). Brings
;; completion-at-point, flymake diagnostics, eldoc, xref (gd via evil), rename.
(use-package eglot
  :ensure nil
  :hook ((typescript-ts-mode tsx-ts-mode js-ts-mode) . eglot-ensure)
  :custom
  (eglot-autoshutdown t)
  (eglot-events-buffer-config '(:size 0)) ; don't accumulate LSP event logs
  :config
  (add-to-list 'eglot-server-programs
               '(((js-ts-mode :language-id "javascript")
                  (tsx-ts-mode :language-id "typescriptreact")
                  (typescript-ts-mode :language-id "typescript"))
                 . ("vtsls" "--stdio")))
  (add-hook 'eglot-managed-mode-hook
            (lambda () (add-hook 'before-save-hook #'my/eglot-format-on-save nil t)))
  ;; nvim 0.12 LSP defaults: gd/K come from evil; the rest bound here.
  (with-eval-after-load 'evil
    (evil-define-key 'normal eglot-mode-map
      (kbd "g r a") #'eglot-code-actions
      (kbd "g r n") #'eglot-rename
      (kbd "g r r") #'xref-find-references
      (kbd "g r i") #'eglot-find-implementation
      (kbd "g r t") #'eglot-find-typeDefinition
      (kbd "g O")   #'imenu                          ; document symbols
      (kbd "<leader>f")  #'eglot-format-buffer
      (kbd "<leader>xx") #'consult-flymake
      (kbd "<leader>ih") #'eglot-inlay-hints-mode)))
