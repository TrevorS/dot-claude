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
  :config
  (evil-collection-init))

(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1)) ; ys/cs/ds + S in visual (mini.surround keys)

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
;; TREE-SITTER LANGUAGES (parity with nvim's ensure_installed)
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
        (json       "https://github.com/tree-sitter/tree-sitter-json"       "v0.24.8")
        (bash       "https://github.com/tree-sitter/tree-sitter-bash"       "v0.25.1")
        (go         "https://github.com/tree-sitter/tree-sitter-go"         "v0.25.0")
        (gomod      "https://github.com/camdencheek/tree-sitter-go-mod"     "v1.1.0")
        (lua        "https://github.com/tree-sitter-grammars/tree-sitter-lua"  "v0.5.0")
        (python     "https://github.com/tree-sitter/tree-sitter-python"     "v0.25.0")
        (ruby       "https://github.com/tree-sitter/tree-sitter-ruby"       "v0.23.1")
        (rust       "https://github.com/tree-sitter/tree-sitter-rust"       "v0.24.2")
        (toml       "https://github.com/tree-sitter-grammars/tree-sitter-toml" "v0.7.0")
        (yaml       "https://github.com/tree-sitter-grammars/tree-sitter-yaml" "v0.7.2")
        (elixir     "https://github.com/elixir-lang/tree-sitter-elixir"     "v0.3.5")
        (heex       "https://github.com/phoenixframework/tree-sitter-heex"  "v0.9.0")
        (markdown        "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "v0.5.3" "tree-sitter-markdown/src")
        (markdown-inline "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "v0.5.3" "tree-sitter-markdown-inline/src")
        (gleam      "https://github.com/gleam-lang/tree-sitter-gleam"       "v1.1.0")))

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

;; Built-in ts modes that don't register their own file extensions
(add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode))
(add-to-list 'auto-mode-alist '("/go\\.mod\\'" . go-mod-ts-mode))
(add-to-list 'auto-mode-alist '("\\.lua\\'" . lua-ts-mode))
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-ts-mode))
(add-to-list 'auto-mode-alist '("\\.exs?\\'" . elixir-ts-mode))
(add-to-list 'auto-mode-alist '("\\.heex\\'" . heex-ts-mode))
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-ts-mode))
(add-to-list 'major-mode-remap-alist '(sh-mode . bash-ts-mode))
(add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode))
(add-to-list 'major-mode-remap-alist '(ruby-mode . ruby-ts-mode))
(add-to-list 'major-mode-remap-alist '(conf-toml-mode . toml-ts-mode))

;; Languages without a built-in ts mode (nvim also has zig/elm/gleam parsers)
(use-package zig-mode
  :custom (zig-format-on-save nil)) ; no zig LSP/formatter configured in nvim either
(use-package elm-mode)
(use-package gleam-ts-mode
  :mode "\\.gleam\\'")

;; ============================================================================
;; LSP (eglot) -- deliberately stock: default eldoc echo, default flymake.
;; evil-collection binds K to eldoc-doc-buffer in eglot buffers.
;; ============================================================================

;; Format on save in LSP buffers + trim trailing whitespace everywhere
;; (nvim BufWritePre: mini.trailspace.trim + vim.lsp.buf.format).
(add-hook 'before-save-hook #'delete-trailing-whitespace)
(defun my/eglot-format-on-save ()
  (when (and (eglot-managed-p)
             (eglot-server-capable :documentFormattingProvider)
             (not (derived-mode-p 'lua-ts-mode))) ; lua formats with stylua below
    (eglot-format-buffer)))

(defun my/format-buffer-with (cmd &rest args)
  "Filter the whole buffer through CMD ARGS, keeping contents when CMD fails."
  (if (not (executable-find cmd))
      (message "%s not installed" cmd)
    (let ((out (generate-new-buffer (concat " *" cmd "*"))))
      (unwind-protect
          (if (zerop (apply #'call-process-region nil nil cmd nil (list out nil) nil args))
              (replace-buffer-contents out)
            (message "%s: format failed (syntax error?)" cmd))
        (kill-buffer out)))))

;; Lua formats with stylua, not lua-ls (nvim BufWritePre: %!stylua -).
(defun my/stylua-format-buffer ()
  (my/format-buffer-with "stylua" "--stdin-filepath"
                         (or buffer-file-name "stdin.lua") "-"))
(add-hook 'lua-ts-mode-hook
          (lambda () (add-hook 'before-save-hook #'my/stylua-format-buffer nil t)))

;; Eglot: built-in LSP client -> vtsls (same server as the nvim config; it
;; bundles its own tsserver, so it works on typescript >= 7 workspaces where
;; typescript-language-server can't find lib/tsserver.js). Brings
;; completion-at-point, flymake diagnostics, eldoc, xref (gd via evil), rename.
(use-package eglot
  :ensure nil
  :hook ((typescript-ts-mode tsx-ts-mode js-ts-mode
          rust-ts-mode python-ts-mode lua-ts-mode) . eglot-ensure)
  :custom
  (eglot-autoshutdown t)
  (eglot-events-buffer-config '(:size 0)) ; don't accumulate LSP event logs
  :config
  (add-to-list 'eglot-server-programs
               '(((js-ts-mode :language-id "javascript")
                  (tsx-ts-mode :language-id "typescriptreact")
                  (typescript-ts-mode :language-id "typescript"))
                 . ("vtsls" "--stdio")))
  ;; basedpyright over eglot's pylsp/pyright defaults; lua-language-server as in
  ;; nvim (rust-analyzer is already eglot's default for rust-ts-mode)
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) . ("basedpyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((lua-mode lua-ts-mode) . ("lua-language-server")))
  ;; Server settings mirroring nvim's vim.lsp.config blocks
  (setq-default eglot-workspace-configuration
                '(:rust-analyzer (:cargo (:allFeatures t)
                                  :check (:command "clippy"))
                  :basedpyright (:analysis (:autoSearchPaths t
                                            :useLibraryCodeForTypes t
                                            :diagnosticMode "openFilesOnly"))))
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

;; ============================================================================
;; IN-BUFFER COMPLETION (corfu; nvim autocomplete pum + Tab/S-Tab/CR)
;; ============================================================================

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preselect 'prompt) ; nvim noinsert: nothing selected until Tab
  :config
  (define-key corfu-map (kbd "TAB") #'corfu-next)
  (define-key corfu-map [tab] #'corfu-next)
  (define-key corfu-map (kbd "S-TAB") #'corfu-previous)
  (define-key corfu-map [backtab] #'corfu-previous)
  ;; RET accepts only when a candidate is selected, otherwise it falls through
  ;; to the global binding (nvim: pmenu_accept -> minipairs_cr multistep)
  (define-key corfu-map (kbd "RET")
    `(menu-item "" corfu-insert
                :filter ,(lambda (cmd) (when (>= corfu--index 0) cmd))))
  (global-corfu-mode 1))

;; ============================================================================
;; JUMP ANYWHERE (avy ≈ mini.jump2d: RET labels every word start on screen)
;; ============================================================================

(use-package avy
  :custom
  (avy-keys (string-to-list "asdfjkl;ghqwertyuiopzxcvbnm"))
  (avy-background t)
  :config
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global (kbd "RET") #'avy-goto-word-0)))

;; ============================================================================
;; SYSTEM CLIPBOARD (nvim "+ interaction; works in emacs -nw via pbcopy)
;; ============================================================================

(defun my/clipboard-copy (text)
  "Copy TEXT to the system clipboard in GUI and terminal frames alike."
  (if (display-graphic-p)
      (gui-set-selection 'CLIPBOARD text)
    (with-temp-buffer
      (insert text)
      (call-process-region (point-min) (point-max) "pbcopy")))
  (message "Copied %d chars to clipboard" (length text)))

(defun my/yank-to-clipboard (beg end)
  "Yank the visual selection to the system clipboard (nvim <leader>y)."
  (interactive "r")
  (my/clipboard-copy (buffer-substring-no-properties beg end))
  (evil-exit-visual-state))

(defun my/copy-buffer-path ()
  "Copy the current buffer's file path to the clipboard (nvim <leader>xp)."
  (interactive)
  (let ((path (or buffer-file-name default-directory)))
    (my/clipboard-copy path)
    (message "Copied path: %s" path)))

(with-eval-after-load 'evil
  (evil-define-key 'visual 'global (kbd "<leader>y") #'my/yank-to-clipboard)
  (evil-define-key 'normal 'global (kbd "<leader>xp") #'my/copy-buffer-path))

;; ============================================================================
;; SMALL QOL (nvim parity odds and ends)
;; ============================================================================

;; j/k move by screen line (nvim j -> gj, k -> gk)
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    "j" #'evil-next-visual-line
    "k" #'evil-previous-visual-line))

;; < and > keep the visual selection (nvim <gv / >gv)
(defun my/visual-shift-left ()
  (interactive)
  (call-interactively #'evil-shift-left)
  (evil-normal-state)
  (evil-visual-restore))
(defun my/visual-shift-right ()
  (interactive)
  (call-interactively #'evil-shift-right)
  (evil-normal-state)
  (evil-visual-restore))
(with-eval-after-load 'evil
  (evil-define-key 'visual 'global
    "<" #'my/visual-shift-left
    ">" #'my/visual-shift-right))

;; No autopairs in prose (nvim disables mini.pairs in markdown/text/gitcommit)
(add-hook 'text-mode-hook (lambda () (electric-pair-local-mode -1)))

;; On-demand formatters (nvim <leader>jf / <leader>sf)
(defun my/format-json () (interactive) (my/format-buffer-with "jq" "."))
(defun my/format-sql () (interactive) (my/format-buffer-with "sleek"))

;; Markdown preview via glow in a tmux popup/split (nvim <leader>mp / <leader>ms)
(defun my/glow-preview (target)
  (cond
   ((not (executable-find "glow")) (message "glow not installed (brew install glow)"))
   ((not (getenv "TMUX")) (message "Not running inside tmux"))
   (t (let* ((tmp (make-temp-file "glow-" nil ".md"))
             (cmd (format "glow -p %s; rm -f %s"
                          (shell-quote-argument tmp) (shell-quote-argument tmp))))
        (write-region (point-min) (point-max) tmp nil 'silent)
        (if (eq target 'popup)
            (call-process "tmux" nil 0 nil "display-popup" "-E" "-w" "90%" "-h" "90%" cmd)
          (call-process "tmux" nil 0 nil "split-window" "-h" cmd))))))

(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    (kbd "<leader>jf") #'my/format-json
    (kbd "<leader>sf") #'my/format-sql
    (kbd "<leader>mp") (lambda () (interactive) (my/glow-preview 'popup))
    (kbd "<leader>ms") (lambda () (interactive) (my/glow-preview 'split))
    ;; edit config files (nvim <leader>ev/ez/eg)
    (kbd "<leader>ev") (lambda () (interactive) (find-file "~/.config/emacs/init.el"))
    (kbd "<leader>ez") (lambda () (interactive) (find-file "~/.zshrc"))
    (kbd "<leader>eg") (lambda () (interactive)
                         (find-file "~/Library/Application Support/com.mitchellh.ghostty/config"))
    ;; redraw + clear search highlight (nvim <leader>l)
    (kbd "<leader>l") (lambda () (interactive) (redraw-display) (evil-ex-nohighlight))
    ;; trim trailing whitespace on demand (nvim <leader>ts)
    (kbd "<leader>ts") (lambda () (interactive)
                         (delete-trailing-whitespace)
                         (message "Trimmed trailing whitespace"))))

;; Cosmetics: TODO/FIXME highlighting, other-occurrence underline, indent guides
(use-package hl-todo
  :config (global-hl-todo-mode 1))
(use-package highlight-thing
  :hook (prog-mode . highlight-thing-mode)
  :custom
  (highlight-thing-exclude-thing-under-point t) ; only OTHER matches, as in nvim
  (highlight-thing-delay-seconds 0.25)
  :config
  (set-face-attribute 'highlight-thing nil
                      :inherit nil :underline t :background 'unspecified))
(use-package indent-bars
  :hook (prog-mode . indent-bars-mode)
  :custom
  (indent-bars-prefer-character t)) ; works in emacs -nw

;; ============================================================================
;; MAGIT
;; ============================================================================

(use-package magit
  :config
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global (kbd "<leader>gs") #'magit-status)))

;; ============================================================================
;; JJ MODE-LINE (port of the nvim statusline jj segment)
;; ============================================================================

(defvar-local my/jj-info nil
  "Plist with jj info for this buffer's file, or nil when not in a jj repo.")

(defface my/jj-dirty '((t :weight bold)) "jj diamond when the change has edits.")
(defface my/jj-empty '((t)) "jj diamond when the change is empty.")
(with-eval-after-load 'catppuccin-theme
  (set-face-attribute 'my/jj-dirty nil :foreground (catppuccin-get-color 'green))
  (set-face-attribute 'my/jj-empty nil :foreground (catppuccin-get-color 'overlay0)))

(defconst my/jj--template
  (concat "change_id.shortest() ++ \"\\n\""
          " ++ bookmarks.filter(|b| b.remote() == \"\").map(|b| b.name()).join(\" \") ++ \"\\n\""
          " ++ description.first_line() ++ \"\\n\""
          " ++ if(empty, \"empty\", \"dirty\")"))

(defun my/jj--refresh (&optional buffer)
  "Asynchronously refresh `my/jj-info' for BUFFER's file."
  (when-let* ((buf (or buffer (current-buffer)))
              (file (buffer-file-name buf))
              (dir (file-name-directory file))
              ((file-directory-p dir)))
    (let ((proc-buf (generate-new-buffer " *jj-modeline*"))
          (default-directory dir))
      (make-process
       :name "jj-modeline" :buffer proc-buf :noquery t :connection-type 'pipe
       :command (list "jj" "log" "-r" "@" "--no-graph" "-T" my/jj--template
                      "--ignore-working-copy")
       :sentinel
       (lambda (proc _event)
         (when (memq (process-status proc) '(exit signal))
           (let ((ok (zerop (process-exit-status proc)))
                 (out (with-current-buffer proc-buf (buffer-string))))
             (kill-buffer proc-buf)
             (when (buffer-live-p buf)
               (with-current-buffer buf
                 (setq my/jj-info
                       (when (and ok (not (string-empty-p out)))
                         (let ((lines (split-string out "\n")))
                           (list :id (car (split-string (or (nth 0 lines) "")))
                                 :bookmark (car (split-string (or (nth 1 lines) "")))
                                 :desc (string-trim (or (nth 2 lines) ""))
                                 :empty (string-prefix-p "empty" (or (nth 3 lines) ""))))))
                 (force-mode-line-update))))))))))

(add-hook 'find-file-hook #'my/jj--refresh)
(add-hook 'after-save-hook #'my/jj--refresh)

(defun my/jj-modeline ()
  "Render `my/jj-info' as ◆/◇ + change id + bookmark + description."
  (when my/jj-info
    (let* ((desc (or (plist-get my/jj-info :desc) ""))
           (desc (if (> (length desc) 30) (concat (substring desc 0 27) "...") desc))
           (bookmark (or (plist-get my/jj-info :bookmark) "")))
      (concat
       (if (plist-get my/jj-info :empty)
           (propertize "◇" 'face 'my/jj-empty)
         (propertize "◆" 'face 'my/jj-dirty))
       " " (plist-get my/jj-info :id)
       (unless (string-empty-p bookmark) (concat " " bookmark))
       (unless (string-empty-p desc) (concat " " desc))
       " "))))

(add-to-list 'mode-line-misc-info '(:eval (my/jj-modeline)) t)

;; ============================================================================
;; MODELINE (doom-modeline; shows the jj segment via misc-info)
;; ============================================================================

(use-package nerd-icons)
(use-package doom-modeline
  :custom
  (doom-modeline-icon t) ; ghostty runs a nerd font, keep icons in -nw too
  (doom-modeline-buffer-encoding nil)
  :config
  (doom-modeline-mode 1))
