;;; ulisp-mode.el --- Major mode for editing and evaluate uLisp

;; SPDX-License-Identifier: GPL-3.0

;; Author: DEADBLACKCLOVER <deadblackclover@protonmail.com>
;; Version: 0.1.0
;; URL: https://codeberg.org/deadblackclover/ulisp-mode
;; Keywords: languages
;; Package-Requires: ((emacs "25.1"))

;; Copyright (c) 2024, DEADBLACKCLOVER.

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; uLisp® is a version of the Lisp programming language specifically designed
;; to run on microcontrollers with a limited amount of RAM.

;; In addition to editing, this mode also allows you to connect to a remote
;; device and execute the code directly on it.

;;; Code:
(defgroup ulisp-mode-line nil
  "Showing information on mode-line."
  :prefix "ulisp-mode-line-"
  :group 'ulisp-mode)

(defvar ulisp-mode-port ""
  "Stores the port to send data to later.")

(defvar ulisp-mode-line-status ""
  "String showing the connection.")

(defun ulisp-mode-open-port (port speed)
  "Opening a PORT at a set SPEED.
It also creates a buffer that holds the connection.
Buffer name matches the PORT."
  (interactive (list (read-string "Port: " "/dev/ttyACM0")
                     (read-string "Speed: " "9600")))
  (let ((buffer (current-buffer)))
    (make-serial-process
     :port port
     :speed (string-to-number speed)
     :buffer (get-buffer-create port))
    (switch-to-buffer port)
    (special-mode)
    (switch-to-buffer buffer)
    (setq ulisp-mode-port port)
    (setq ulisp-mode-line-status (concat "[ Connect: " ulisp-mode-port " ] "))))

(defun ulisp-mode-kill-buffer ()
  "Kill the buffer and kill a connection."
  (interactive)
  (if (string= "" ulisp-mode-port)
      (message
       "The port is not installed, need to execute `ulisp-mode-open-port`")
    (kill-buffer ulisp-mode-port))
  (setq ulisp-mode-port "")
  (setq ulisp-mode-line-status ""))

(defun ulisp-mode-send (str)
  "Sending a string STR to the device."
  (interactive)
  (if (string= "" ulisp-mode-port)
      (message
       "The port is not installed, need to execute `ulisp-mode-open-port`")
    (process-send-string ulisp-mode-port str)))

(defun ulisp-mode-block ()
  "Fetching and sending a code block."
  (interactive)
  (let ((initial-point (point))
        (block-end (progn (if (equal (char-before) ?\))
                              (backward-char))
                          (up-list)
                          (point)))
        (block-beginning (backward-list)))
    (goto-char initial-point)
    (ulisp-mode-send (buffer-substring-no-properties block-beginning
                                                     block-end))))

(defvar ulisp-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map lisp-mode-shared-map)
    (define-key map (kbd "C-c C-o") 'ulisp-mode-open-port)
    (define-key map (kbd "C-c C-k") 'ulisp-mode-kill-buffer)
    (define-key map (kbd "C-c C-c") 'ulisp-mode-block)
    map)
  "Keymap for `ulisp-mode', derived from `lisp-mode'.")

(define-derived-mode ulisp-mode lisp-mode "uLisp"
  "Major mode for editing and evaluate uLisp."
  (use-local-map ulisp-mode-map))

(defun ulisp-mode-line-enable ()
  "Turn on `ulisp-mode-line'."
  (interactive)
  (ulisp-mode-line-mode 1))

(defun ulisp-mode-line-disable ()
  "Turn off `ulisp-mode-line'."
  (interactive)
  (ulisp-mode-line-mode -1))

;;;###autoload
(define-minor-mode ulisp-mode-line-mode
  "Minor mode to display an open serial port."
  :global t
  (if ulisp-mode-line-mode
      (add-to-list 'mode-line-modes '(t ulisp-mode-line-status) t)
    (if (boundp 'mode-line-modes)
        (delete '(t ulisp-mode-line-status) mode-line-modes))))

(provide 'ulisp-mode)
;;; ulisp-mode.el ends here
