;;; update-emacs-plugins.el --- headless elpaca update-all -*- lexical-binding: t -*-

;; Usage: emacs --batch -l ~/.config/emacs/init.el -l scripts/update-emacs-plugins.el
;; init.el queues every package but --batch never runs after-init-hook, so the
;; queues must be processed explicitly (elpaca-wait does this) before and after
;; queueing the update merges.

(require 'cl-lib)

(elpaca-wait)
(elpaca-update-all t)
(elpaca-wait)

(let ((failed (cl-loop for (id . e) in (elpaca--queued)
                       unless (eq (elpaca<-status e) 'finished) collect id)))
  (if (not failed)
      (message "elpaca: all %d packages up to date" (length (elpaca--queued)))
    (message "elpaca: FAILED: %S" failed)
    (cl-loop for ev in (reverse elpaca--event-log)
             when (memq (elpaca-event<-id ev) failed)
             do (message "%s | %s | %S" (elpaca-event<-id ev)
                         (elpaca-event<-type ev) (elpaca-event<-payload ev)))
    (kill-emacs 1)))
