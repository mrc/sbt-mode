;;; sbt-mode.el --- comint-mode for the Scala Build Tool

;; Copyright (C) 2013 Matt Curtis
;; All rights reserved.
;;
;; Author: Matt Curtis <matt.r.curtis@gmail.com>
;; Version: 0.1
;; Keywords: processes, sbt
;; URL: https://github.com/mrc/sbt-mode

;; This file is not part of GNU Emacs.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are
;; met:
;;
;;  - Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;;
;;  - Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;;
;;  - Neither the name of Edward Marco Baringer, nor BESE, nor the names
;;    of its contributors may be used to endorse or promote products
;;    derived from this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;; A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
;; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:
;; Portions based on the cassandra-mode example from
;; http://www.masteringemacs.org/
;;
;;; Code:

;;; Customization

(defgroup sbt-mode nil
  "Comint mode for `sbt'."
  :group 'scala)

(defcustom sbt-program "sbt"
  "Path to the sbt executable."
  :type 'string
  :group 'sbt-mode)

(defcustom sbt-arguments ""
  "Arguments to `sbt'."
  :type 'string
  :group 'sbt-mode)

(defcustom sbt-prompt-regexp "^>+ *"
  "Prompt for `sbt-mode'."
  :type 'string
  :group 'sbt-mode)

;;; Keymap

(defvar sbt-mode-map
  (let ((map (nconc (make-sparse-keymap) comint-mode-map)))
    (define-key map "\t" 'sbt-dynamic-complete)
    (define-key map "\C-a" 'comint-bol-or-process-mark)
    map)
  "Basic mode map for `sbt-mode'")

;;; Completion and highlighting

(defconst sbt-keywords
  '("help" "about" "tasks" "settings" "reload" "projects" "project" "session" "exit"
    "set"
    "inspect"
    "last" "last-grep"
    "export"
    "show"
    "clean" "compile" "console" "doc" "package" "publish" "run" "update"
    "test" "testOnly" "testQuick"
    "styleCheck"))

(defvar sbt-font-lock-keywords
  (list
   ;; highlight all the reserved commands.
   `(,(concat "\\_<" (regexp-opt sbt-keywords) "\\_>") . font-lock-keyword-face))
  "Additional expressions to highlight in `sbt-mode'.")

(defun sbt-dynamic-complete ()
  (interactive)
  (let* ((end (point))
         (stub (save-excursion
                 (skip-syntax-backward "w_")
                 (when (looking-at comint-prompt-regexp)
                   (goto-char (match-end 0)))
                 (buffer-substring-no-properties (point) end))))
    (message "stub [%s]" stub)
    (comint-dynamic-simple-complete stub sbt-keywords)))

;;; Mode definition

(defun sbt--initialize ()
  "Helper function to initialize sbt."
  (setq comint-process-echoes t)
  (setq comint-use-prompt-regexp t))

(define-derived-mode sbt-mode comint-mode "sbt"
  "Major mode for `sbt-mode'.

\\<sbt-mode-map>"
  nil "sbt"
  (setq comint-prompt-regexp sbt-prompt-regexp)
  (setq comint-prompt-read-only t)
  (set (make-local-variable 'paragraph-separate) "\\'")
  (set (make-local-variable 'font-lock-defaults) '(sbt-font-lock-keywords t))
  (set (make-local-variable 'paragraph-start) sbt-prompt-regexp)
  (add-hook 'comint-dynamic-completion-functions 'sbt-dynamic-complete)
  (add-hook 'comint-dynamic-completion-functions 'comint-c-a-p-replace-by-expanded-history))

;; this has to be done in a hook. grumble grumble.
(add-hook 'sbt-mode-hook 'sbt--initialize)

;;; Runner

(defun run-sbt ()
  "Run `sbt'."
  (interactive)
  (let* ((buffer (comint-check-proc "sbt")))
    ;; pop to the "*sbt*" buffer if the process is dead, the
    ;; buffer is missing or it's got the wrong mode.
    (pop-to-buffer-same-window
     (if (or buffer (not (derived-mode-p 'sbt-mode))
             (comint-check-proc (current-buffer)))
         (get-buffer-create (or buffer "*sbt*"))
       (current-buffer)))
    ;; create the comint process if there is no buffer.
    (unless buffer
      (apply 'make-comint-in-buffer "sbt" buffer
             sbt-program sbt-arguments)
      (sbt-mode))))

(provide 'sbt-mode)

;;; sbt-mode.el ends here
