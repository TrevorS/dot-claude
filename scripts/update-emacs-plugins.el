;;; update-emacs-plugins.el --- headless elpaca update -*- lexical-binding: t -*-

;; Usage: emacs --batch -l ~/.config/emacs/init.el -l scripts/update-emacs-plugins.el
;; init.el queues every package but --batch never runs after-init-hook, so the
;; queues must be processed explicitly (elpaca-wait does this) between phases.
;;
;; `elpaca-update-all' force-recompiles and rebuilds docs for every package even
;; when nothing was fetched, which is most of its runtime. Instead: fetch all
;; in parallel, merge + rebuild only repos behind upstream, then rebuild their
;; dependents so macros expanded from an updated package are recompiled.

(require 'cl-lib)

(defun my/elpaca-behind-p (e)
  "Return non-nil if E's source repo has fetched commits not yet merged."
  (and (not (elpaca-pinned-p e))
       (file-directory-p (elpaca<-source-dir e))
       (let* ((default-directory (elpaca<-source-dir e))
              (result (elpaca-process-call "git" "rev-list" "--count" "HEAD..@{u}")))
         (and (eql (car result) 0) (> (string-to-number (nth 1 result)) 0)))))

(defun my/elpaca-finished-p (id)
  (eq (elpaca<-status (elpaca-get id)) 'finished))

(elpaca-wait)
(elpaca-fetch-all)
(elpaca-wait)

(let* ((stale (cl-loop for (id . e) in (reverse (elpaca--queued))
                       when (my/elpaca-behind-p e) collect id))
       (dependents (cl-set-difference
                    (delete-dups (cl-mapcan (lambda (id) (copy-sequence (elpaca--dependents id t)))
                                            stale))
                    stale)))
  (when stale
    (message "elpaca: updating %S" stale)
    (mapc #'elpaca-merge (cl-remove-if-not #'my/elpaca-finished-p stale))
    (elpaca-wait))
  ;; Separate phase: a dependent compiled alongside its dependency's merge
  ;; could load the stale .elc.
  (when dependents
    (message "elpaca: rebuilding dependents %S" dependents)
    (mapc #'elpaca-rebuild (cl-remove-if-not #'my/elpaca-finished-p dependents))
    (elpaca-wait))
  (let ((failed (cl-loop for (id . e) in (elpaca--queued)
                         unless (eq (elpaca<-status e) 'finished) collect id)))
    (if (not failed)
        (message "elpaca: %d packages checked, %d updated, %d rebuilt"
                 (length (elpaca--queued)) (length stale) (length dependents))
      (message "elpaca: FAILED: %S" failed)
      (cl-loop for ev in (reverse elpaca--event-log)
               when (memq (elpaca-event<-id ev) failed)
               do (message "%s | %s | %S" (elpaca-event<-id ev)
                           (elpaca-event<-type ev) (elpaca-event<-payload ev)))
      (kill-emacs 1))))
