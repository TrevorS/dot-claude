;;; init.el --- Emacs config -*- lexical-binding: t -*-

;; ============================================================================
;; PLUGIN MANAGEMENT (elpaca)
;; ============================================================================

;; Machine-local data root shared by elpaca, no-littering, and tree-sitter.
(defconst my/data-dir
  (expand-file-name "emacs/" (or (getenv "XDG_DATA_HOME") "~/.local/share")))

(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" my/data-dir))
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
  (setq no-littering-var-directory (expand-file-name "var/" my/data-dir)
        no-littering-etc-directory (expand-file-name "etc/" my/data-dir))
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
 history-length 1000
 recentf-max-saved-items 300)

;; vim scrolloff semantics: the margin stops at the last line instead of
;; scrolling blank space into view (emacs applies scroll-margin past EOB).
;; Clamp it per command to the lines actually remaining below point.
(defun my/clamp-scroll-margin ()
  (setq-local scroll-margin
              (min (default-value 'scroll-margin)
                   (- (default-value 'scroll-margin)
                      (save-excursion
                        (forward-line (default-value 'scroll-margin)))))))
(add-hook 'post-command-hook #'my/clamp-scroll-margin)

;; vim also never rests the cursor on the phantom line after the final newline
;; (emacs buffers really contain that line; vim hides it). evil-adjust-cursor
;; is evil's "may the cursor sit here?" chokepoint -- it already pulls point
;; off line ends after every motion and on normal-state entry, so teach it the
;; last-line rule too. Insert state is untouched (evil doesn't adjust there).
(with-eval-after-load 'evil
  (define-advice evil-adjust-cursor (:before (&optional _) my/no-phantom-line)
    (when (and (eobp) (bolp) (not (bobp)))
      (backward-char)
      ;; evil restores the motion's goal column before adjusting, i.e. onto
      ;; the phantom line -- re-apply it here on the real last line (the
      ;; advised body then handles the end-of-line rule as usual)
      (when (memq this-command '(next-line previous-line))
        (let ((col (if (consp temporary-goal-column)
                       (+ (car temporary-goal-column)
                          (cdr temporary-goal-column))
                     temporary-goal-column)))
          (unless (>= col most-positive-fixnum)
            (move-to-column (truncate col))))))))

;; Redisplay performance (benched: j/k cost is ~all redisplay, not commands)
(setq redisplay-skip-fontification-on-input t ; don't fontify under held keys
      fast-but-imprecise-scrolling t
      auto-window-vscroll nil
      inhibit-compacting-font-caches t
      bidi-inhibit-bpa t
      jit-lock-stealth-time 1.0)  ; pre-fontify off-screen while idle
(setq-default bidi-paragraph-direction 'left-to-right)

(column-number-mode 1)
(global-hl-line-mode 1)
(show-paren-mode 1)
(setq auto-revert-avoid-polling t)      ; kqueue notifies; don't stat every 5s
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)
(setq recentf-auto-cleanup 300)         ; stat the list when idle, not at startup
(recentf-mode 1)
(savehist-mode 1)                       ; command/minibuffer history
(save-place-mode 1)
(pixel-scroll-precision-mode 1)
(electric-pair-mode 1)                  ; auto-close brackets/quotes
(which-key-mode 1)                      ; key hints (built in, Emacs 30+)

(setq-default display-line-numbers-width 4)    ; nvim numberwidth; avoids
(setq display-line-numbers-grow-only t)        ; per-scroll width recompute
;; Numbers only where nvim has them (file/edit buffers); special-mode buffers
;; (dired, help, magit, term, ...) stay clean without a per-mode blacklist.
(dolist (h '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook h #'display-line-numbers-mode))

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
  ;; Synchronous, like no-littering: evil loads eagerly anyway, and having it
  ;; active here lets every evil-define-key below be a plain top-level form
  ;; instead of a with-eval-after-load wrapper.
  :ensure (:wait t)
  :demand t
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

;; - in a file buffer: dired on its directory, point on the file
;; (- in dired itself is dired-up-directory via evil-collection)
(evil-define-key 'normal 'global (kbd "-") #'dired-jump)

;; ============================================================================
;; TMUX NAVIGATION (smart-splits.nvim protocol)
;; ============================================================================
;; tmux.conf checks the @pane-is-vim pane flag: when set it passes C-hjkl
;; through; we move between Emacs windows and hop to the tmux pane at an edge.

(defun my/tmux--set-pane-is-vim (val &optional wait)
  "Set the tmux @pane-is-vim flag; fire-and-forget unless WAIT.
Clearing must WAIT: on kill/suspend the async child could die before tmux acts."
  (when (getenv "TMUX_PANE")
    (call-process "tmux" nil (unless wait 0) nil "set-option" "-p"
                  "-t" (getenv "TMUX_PANE") "@pane-is-vim" val)))

(my/tmux--set-pane-is-vim "1") ; async: don't block startup on a tmux round-trip
(add-hook 'kill-emacs-hook (lambda () (my/tmux--set-pane-is-vim "0" t)))
(add-hook 'suspend-hook (lambda () (my/tmux--set-pane-is-vim "0" t)))
(add-hook 'suspend-resume-hook (lambda () (my/tmux--set-pane-is-vim "1")))

(defun my/window-nav (move-fn tmux-flag)
  "Call MOVE-FN, or select the tmux pane toward TMUX-FLAG when at the edge."
  (condition-case nil
      (funcall move-fn)
    ;; user-error = no window in that direction (windmove is autoloaded)
    (user-error (when (getenv "TMUX_PANE")
                  ;; destination 0 = fire-and-forget; no ~10ms edge-hit stall
                  (call-process "tmux" nil 0 nil "select-pane" tmux-flag)))))

(defun my/window-left ()  (interactive) (my/window-nav #'windmove-left  "-L"))
(defun my/window-down ()  (interactive) (my/window-nav #'windmove-down  "-D"))
(defun my/window-up ()    (interactive) (my/window-nav #'windmove-up    "-U"))
(defun my/window-right () (interactive) (my/window-nav #'windmove-right "-R"))

(evil-define-key '(normal visual motion) 'global
  (kbd "C-h") #'my/window-left
  (kbd "C-j") #'my/window-down
  (kbd "C-k") #'my/window-up
  (kbd "C-l") #'my/window-right)

;; ============================================================================
;; MINIBUFFER COMPLETION (vertico + orderless + consult)
;; ============================================================================
;; Vertico is a thin UI over native completing-read; Orderless adds
;; space-separated fuzzy matching; Consult provides mini.pick-style pickers.

(use-package vertico
  :custom
  (vertico-cycle t)
  (vertico-count 15) ; taller miniwindow pickers (buffer-mode ones size from window)
  ;; telescope layout for the file/grep pickers: candidates in a window on the
  ;; left, live preview in the original window on the right
  (vertico-buffer-display-action
   '(display-buffer-in-direction (direction . left) (window-width . 0.5)))
  ;; grep pickers key on their completion category so wrappers like
  ;; <leader>* are covered automatically; consult-fd must stay command-keyed
  ;; (its category is plain `file', shared with every find-file prompt)
  (vertico-multiform-categories '((consult-grep buffer)))
  (vertico-multiform-commands '((consult-fd buffer)))
  :config
  (vertico-mode 1)
  (vertico-multiform-mode 1)
  (add-hook 'minibuffer-setup-hook #'vertico-repeat-save)) ; for <leader>P resume

;; On tty the hardware cursor always sits in the selected window -- the
;; minibuffer -- so vertico-buffer's GUI trick of hiding the minibuffer prompt
;; (pixel-scroll, a tty no-op) leaves a duplicated input line and a cursor
;; blinking at the bottom. Do the telescope thing instead: keep prompt, input,
;; and the real cursor in the minibuffer, and hide the prompt copy at the top
;; of the picker window with a window-scoped overlay.
(defvar my/vertico-tty-prompt-ov nil)
(defun my/vertico-tty-prompt-ov-cleanup ()
  (when my/vertico-tty-prompt-ov
    (delete-overlay my/vertico-tty-prompt-ov)
    (setq my/vertico-tty-prompt-ov nil))
  (remove-hook 'minibuffer-exit-hook #'my/vertico-tty-prompt-ov-cleanup))
(with-eval-after-load 'vertico-buffer
  (setq vertico-buffer-hide-prompt nil) ; prompt + real cursor stay in minibuffer
  (define-advice vertico-buffer--setup (:after () my/tty-prompt-at-bottom)
    (unless (display-graphic-p)
      (setq my/vertico-tty-prompt-ov (make-overlay (point-min) (point-max) nil nil t))
      (overlay-put my/vertico-tty-prompt-ov 'window
                   (overlay-get vertico--candidates-ov 'window))
      ;; show the picker's base directory in place of the hidden prompt copy
      (overlay-put my/vertico-tty-prompt-ov 'display
                   (propertize (abbreviate-file-name default-directory)
                               'face 'shadow))
      ;; the count belongs to the minibuffer line; scope it out of the picker
      (when vertico--count-ov
        (overlay-put vertico--count-ov 'window (active-minibuffer-window)))
      (add-hook 'minibuffer-exit-hook #'my/vertico-tty-prompt-ov-cleanup))))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package consult
  :defer t ; all entry points autoloaded
  :custom
  (consult-async-min-input 2)
  ;; files only; search hidden paths too (dotfiles live under .config/), skip .git
  (consult-fd-args
   '("fd" "--type" "f" "--full-path" "--color=never" "--hidden" "--exclude" ".git"))
  :config
  ;; extend consult's default rg flags rather than forking the whole string
  (unless (string-match-p "--hidden" consult-ripgrep-args)
    (setq consult-ripgrep-args
          (concat consult-ripgrep-args " --hidden --glob=!.git/")))
  ;; start populated like telescope find_files: allow empty input through
  ;; (grep pickers keep the global 2-char minimum) ...
  (defvar consult-async-min-input) ; declare special so the let binds dynamically
  (define-advice consult-fd (:around (fn &rest args) my/start-populated)
    (let ((consult-async-min-input 0))
      (apply fn args)))
  ;; ... and run a pattern-less fd for it (the stock builder bails on "").
  ;; Return shape must be (cmd . nil): the highlight stage funcalls the cdr.
  (define-advice consult--fd-make-builder (:around (fn paths) my/match-all-on-empty)
    (let ((builder (funcall fn paths)))
      (lambda (input)
        (or (funcall builder input)
            (list (append (consult--build-args consult-fd-args)
                          (mapcan (lambda (x) (list "--search-path" x)) paths)))))))
  ;; telescope-style live preview: consult-fd ships without a :state, so the
  ;; selected file never previews; inject the stock file preview (debounced so
  ;; holding C-n doesn't open every candidate)
  (consult-customize consult-fd
                     :state (consult--file-preview)
                     :preview-key '(:debounce 0.2 any)))

(defun my/consult-ripgrep-cword ()
  "Ripgrep for the symbol at point (nvim <leader>*)."
  (interactive)
  (consult-ripgrep nil (thing-at-point 'symbol)))

;; Picker keymaps mirroring nvim mini.pick binds.
(evil-define-key 'normal 'global
  (kbd "<leader>p")  #'consult-fd            ; find files
  (kbd "<leader>b")  #'consult-buffer        ; buffers (+ recent files)
  (kbd "<leader>gg") #'consult-ripgrep       ; live grep
  (kbd "<leader>*")  #'my/consult-ripgrep-cword
  (kbd "<leader>P")  #'vertico-repeat        ; resume last picker
  (kbd "<leader>r")  #'consult-recent-file)  ; recent files (visits-ish)

;; ============================================================================
;; TREE-SITTER LANGUAGES (parity with nvim's ensure_installed)
;; ============================================================================

;; Grammars compile once into ~/.local/share/emacs/tree-sitter (needs a C compiler).
(defvar my/treesit-grammar-directory (expand-file-name "tree-sitter/" my/data-dir))
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

;; Availability probes dlopen every grammar (~65ms) -- run off the critical
;; path. Fresh machines get grammars a moment after startup.
(run-with-idle-timer
 2 nil
 (lambda ()
   (dolist (lang (mapcar #'car treesit-language-source-alist))
     (unless (treesit-language-available-p lang)
       (treesit-install-language-grammar lang my/treesit-grammar-directory)))))

;; Level 4 costs ~2.3ms/keystroke of redisplay for marginal extra color
(setq treesit-font-lock-level 3)

;; Emacs 31: every built-in ts mode autoload-registers a `-maybe' dispatcher in
;; auto-mode-alist; this custom's :set turns them all on and merges the ts
;; entries into major-mode-remap-alist. Only extensions the built-ins don't
;; claim need listing by hand.
(setopt treesit-enabled-modes t)
(add-to-list 'auto-mode-alist '("\\.[cm]ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . tsx-ts-mode))

;; Languages without a built-in ts mode (nvim also has zig/elm/gleam parsers).
;; All defer; their autoloads register the file extensions.
(use-package zig-mode
  :defer t
  :custom (zig-format-on-save nil)) ; no zig LSP/formatter configured in nvim either
(use-package elm-mode
  :defer t)
(use-package gleam-ts-mode
  :mode "\\.gleam\\'")
(use-package markdown-mode
  :defer t
  :mode ("\\.md\\'" . gfm-mode) ; GitHub-flavored for .md; .markdown etc. get plain markdown-mode
  :custom (markdown-fontify-code-blocks-natively t))

;; ============================================================================
;; LSP (eglot) -- deliberately stock: default eldoc echo, default flymake.
;; evil-collection binds K to eldoc-doc-buffer in eglot buffers.
;; ============================================================================

;; Format on save + trim trailing whitespace everywhere (nvim BufWritePre:
;; mini.trailspace.trim + vim.lsp.buf.format). One buffer-local formatter
;; drives both save and <leader>f, so on-save and on-demand can't diverge;
;; eglot attach sets it, mode hooks override it (lua -> stylua).
(add-hook 'before-save-hook #'delete-trailing-whitespace)

(defvar-local my/format-buffer-function nil
  "Formatter for this buffer, or nil for none.")

(defun my/format-buffer ()
  "Format the buffer with `my/format-buffer-function' (nvim <leader>f)."
  (interactive)
  (when my/format-buffer-function
    (funcall my/format-buffer-function)))
(add-hook 'before-save-hook #'my/format-buffer)

(defun my/eglot-format-when-capable ()
  (when (and (eglot-managed-p)
             (eglot-server-capable :documentFormattingProvider))
    (eglot-format-buffer)))

(defun my/format-buffer-with (cmd &rest args)
  "Filter the whole buffer through CMD ARGS, keeping contents when CMD fails."
  (if (not (executable-find cmd))
      (message "%s not installed" cmd)
    (let ((out (generate-new-buffer (concat " *" cmd "*"))))
      (unwind-protect
          (if (zerop (apply #'call-process-region nil nil cmd nil (list out nil) nil args))
              (replace-region-contents (point-min) (point-max) out)
            (message "%s: format failed (syntax error?)" cmd))
        (kill-buffer out)))))

;; Lua formats with stylua, not lua-ls (nvim BufWritePre: %!stylua -).
(defun my/stylua-format-buffer ()
  (my/format-buffer-with "stylua" "--stdin-filepath"
                         (or buffer-file-name "stdin.lua") "-"))
(add-hook 'lua-ts-mode-hook
          (lambda () (setq my/format-buffer-function #'my/stylua-format-buffer)))

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
  ;; Skip jsonrpc log formatting entirely -- measurable win on chatty servers
  (fset #'jsonrpc--log-event #'ignore)
  ;; Match nvim's lsp root_markers: a .luarc.json roots its own project, so
  ;; lua-language-server reads per-project config instead of flagging every
  ;; nvim `vim` global from the repo root (220 bogus diagnostics benched).
  (setq project-vc-extra-root-markers '(".luarc.json"))
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
  ;; a mode hook (e.g. lua -> stylua) wins over the LSP formatter
  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              (unless my/format-buffer-function
                (setq my/format-buffer-function #'my/eglot-format-when-capable))))
  ;; nvim 0.12 LSP defaults: gd/K come from evil; the rest bound here.
  (evil-define-key 'normal eglot-mode-map
    (kbd "g r a") #'eglot-code-actions
    (kbd "g r n") #'eglot-rename
    (kbd "g r r") #'xref-find-references
    (kbd "g r i") #'eglot-find-implementation
    (kbd "g r t") #'eglot-find-typeDefinition
    (kbd "g O")   #'imenu                          ; document symbols
    (kbd "<leader>f")  #'my/format-buffer
    (kbd "<leader>xx") #'consult-flymake
    (kbd "<leader>ih") #'eglot-inlay-hints-mode))

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
  :defer t ; avy-goto-word-0 is autoloaded
  :custom
  (avy-keys (string-to-list "asdfjkl;ghqwertyuiopzxcvbnm"))
  (avy-background t))
(evil-define-key 'normal 'global (kbd "RET") #'avy-goto-word-0)

;; ============================================================================
;; SYSTEM CLIPBOARD (nvim "+ interaction; works in emacs -nw via OSC 52)
;; ============================================================================

;; terminal-init-tmux replaces the global capability check with this list;
;; setSelection turns on OSC 52, which tmux forwards (set-clipboard on) to
;; ghostty. Makes gui-set-selection -- and evil's "+ register -- work in -nw.
(setq xterm-tmux-extra-capabilities '(modifyOtherKeys setSelection))

(defun my/clipboard-copy (text)
  "Copy TEXT to the system clipboard (OSC 52 in terminal frames).
Callers own the echo-area feedback."
  (gui-set-selection 'CLIPBOARD text))

(defun my/yank-to-clipboard (beg end)
  "Yank the visual selection to the system clipboard (nvim <leader>y)."
  (interactive "r")
  (my/clipboard-copy (buffer-substring-no-properties beg end))
  (evil-exit-visual-state)
  (message "Copied %d chars to clipboard" (- end beg)))

(defun my/copy-buffer-path ()
  "Copy the current buffer's file path to the clipboard (nvim <leader>xp)."
  (interactive)
  (let ((path (or buffer-file-name default-directory)))
    (my/clipboard-copy path)
    (message "Copied path: %s" path)))

(evil-define-key 'visual 'global (kbd "<leader>y") #'my/yank-to-clipboard)
(evil-define-key 'normal 'global (kbd "<leader>xp") #'my/copy-buffer-path)

;; ============================================================================
;; SMALL QOL (nvim parity odds and ends)
;; ============================================================================

;; j/k: logical lines in code (visual-line movement costs ~2.6ms/keystroke of
;; redisplay and is identical on unwrapped lines); screen lines in prose
(evil-define-key 'normal text-mode-map
  "j" #'evil-next-visual-line
  "k" #'evil-previous-visual-line)

;; < and > keep the visual selection (nvim <gv / >gv)
(defun my/visual-shift (cmd)
  "Shift the visual selection with CMD and reselect it."
  (call-interactively cmd)
  (evil-normal-state)
  (evil-visual-restore))
(defun my/visual-shift-left ()  (interactive) (my/visual-shift #'evil-shift-left))
(defun my/visual-shift-right () (interactive) (my/visual-shift #'evil-shift-right))
(evil-define-key 'visual 'global
  "<" #'my/visual-shift-left
  ">" #'my/visual-shift-right)

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

(defun my/close-buffer-or-quit ()
  "Kill the current buffer, or `:q' if it's the last (nvim <leader>q).
Listed approximates nvim `buflisted': file-visiting or plain-named.
With no listed buffers at all (e.g. only *scratch* left), quit emacs."
  (interactive)
  (let ((listed (match-buffers '(or buffer-file-name (not "\\`[ *]")))))
    (if (or (null listed) (equal listed (list (current-buffer))))
        (evil-quit)
      (kill-current-buffer))))

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
  (kbd "<leader>q") #'my/close-buffer-or-quit
  ;; redraw + clear search highlight (nvim <leader>l)
  (kbd "<leader>l") (lambda () (interactive) (redraw-display) (evil-ex-nohighlight))
  ;; trim trailing whitespace on demand (nvim <leader>ts)
  (kbd "<leader>ts") (lambda () (interactive)
                       (delete-trailing-whitespace)
                       (message "Trimmed trailing whitespace")))

;; Cosmetics: TODO/FIXME highlighting, other-occurrence underline, indent guides
(use-package hl-todo
  :hook ((prog-mode text-mode) . hl-todo-mode))
(use-package highlight-thing
  :hook (prog-mode . highlight-thing-mode)
  :custom
  (highlight-thing-exclude-thing-under-point t) ; only OTHER matches, as in nvim
  (highlight-thing-delay-seconds 0.25)
  ;; each idle fire rescans + re-overlays; keep it to +/-50 lines in big files
  ;; so a common symbol can't cons thousands of redisplay-slowing overlays
  (highlight-thing-limit-to-region-in-large-buffers-p t)
  (highlight-thing-narrow-region-lines 50)
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

;; Magit needs transient >= 0.13; Emacs 30 ships 0.7 built-in, so install it
(use-package transient
  :defer t)

(use-package magit
  :defer t) ; magit-status is autoloaded; loading magit eagerly costs ~500ms
(evil-define-key 'normal 'global (kbd "<leader>gs") #'magit-status)

;; ============================================================================
;; JJ MODE-LINE (port of the nvim statusline jj segment)
;; ============================================================================

(defvar-local my/jj-modeline-string nil
  "Pre-rendered jj segment, or nil when not in a jj repo.
Built once per refresh in the process sentinel, not per redisplay.")

;; Semantic inheritance: any theme styles these (catppuccin maps success ->
;; green, shadow -> overlay), and they follow flavor changes automatically.
(defface my/jj-dirty '((t :inherit success :weight bold))
  "jj diamond when the change has edits."
  :group 'mode-line-faces)
(defface my/jj-empty '((t :inherit shadow))
  "jj diamond when the change is empty."
  :group 'mode-line-faces)

(defconst my/jj--template
  (concat "change_id.shortest() ++ \"\\n\""
          " ++ bookmarks.filter(|b| b.remote() == \"\").map(|b| b.name()).join(\" \") ++ \"\\n\""
          " ++ description.first_line() ++ \"\\n\""
          " ++ if(empty, \"empty\", \"dirty\")"))

(defun my/jj--render (lines)
  "Render jj log output LINES as ◆/◇ + change id + bookmark + description."
  (let* ((id (car (split-string (or (nth 0 lines) ""))))
         (bookmark (or (car (split-string (or (nth 1 lines) ""))) ""))
         (desc (string-trim (or (nth 2 lines) "")))
         (desc (if (> (length desc) 30) (concat (substring desc 0 27) "...") desc)))
    (concat
     (if (string-prefix-p "empty" (or (nth 3 lines) ""))
         (propertize "◇" 'face 'my/jj-empty)
       (propertize "◆" 'face 'my/jj-dirty))
     " " id
     (unless (string-empty-p bookmark) (concat " " bookmark))
     (unless (string-empty-p desc) (concat " " desc))
     " ")))

(defun my/jj--refresh (&optional buffer)
  "Asynchronously refresh `my/jj-modeline-string' for BUFFER's file."
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
                 (setq my/jj-modeline-string
                       (when (and ok (not (string-empty-p out)))
                         (my/jj--render (split-string out "\n"))))
                 (force-mode-line-update))))))))))

(add-hook 'find-file-hook #'my/jj--refresh)
(add-hook 'after-save-hook #'my/jj--refresh)

(add-to-list 'mode-line-misc-info '(:eval my/jj-modeline-string) t)

;; ============================================================================
;; MODELINE (doom-modeline; shows the jj segment via misc-info)
;; ============================================================================

(use-package nerd-icons)
(use-package doom-modeline
  ;; icons stay on in -nw (the default) -- ghostty runs a nerd font
  :custom
  (doom-modeline-buffer-encoding nil)
  (doom-modeline-buffer-file-name-style 'relative-to-project) ; nvim filename
  (doom-modeline-check 'simple)  ; one worst-severity count, not three
  :config
  ;; Lean layout (benched ~2ms/redisplay with the kitchen sink): drop vcs
  ;; (the jj segment in misc-info is our vcs), selection-info, word-count &co.
  (doom-modeline-def-modeline 'main
    '(eldoc bar modals buffer-info buffer-position)
    '(misc-info check lsp major-mode))
  (doom-modeline-mode 1))
