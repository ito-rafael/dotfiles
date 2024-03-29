;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

;; LaTeX preview
(require 'latex-preview-pane)
(latex-preview-pane-enable)

;; org-auto-tangle
(use-package! org-auto-tangle
  :defer t
  :hook (org-mode . org-auto-tangle-mode)
  :config
  (setq org-auto-tangle-default t))

;; ":ignore:" attribute support to export contents without the header
(require 'ox-extra)
(ox-extras-activate '(ignore-headlines))

;; support for ":newpage:" tag
;;   - inserts a line with "\clearpage" one line above the header in the .tex file
;;   - the same as inserting "#+LATEX: \newpage" one live above the header in the .org file
;; https://emacs.stackexchange.com/questions/30575/adding-latex-newpage-before-a-heading
(defun org/get-headline-string-element  (headline backend info)
  (let ((prop-point (next-property-change 0 headline)))
    (if prop-point (plist-get (text-properties-at prop-point headline) :parent))))

(defun org/ensure-latex-clearpage (headline backend info)
  (when (org-export-derived-backend-p backend 'latex)
    (let ((elmnt (org/get-headline-string-element headline backend info)))
      (when (member "newpage" (org-element-property :tags elmnt))
        (concat "\\clearpage\n" headline)))))

(add-to-list 'org-export-filter-headline-functions
             'org/ensure-latex-clearpage)

;; change table of contents title for beamer export (default: "Outline")
(setq org-beamer-outline-frame-title "Agenda")

;; LaTeX abntex2
;; abntex2.cls is available in texlive-publishers package
(require 'ox-latex)
(unless (boundp 'org-latex-classes)
  (setq org-latex-classes nil))
(add-to-list 'org-latex-classes
  '("abntex2"
    "\\documentclass{abntex2}"
    ("\\chapter{%s}"         . "\\chapter*{%s}")
    ("\\section{%s}"         . "\\section*{%s}")
    ("\\subsection{%s}"      . "\\subsection*{%s}")
    ("\\subsubsection{%s}"   . "\\subsubsection*{%s}")
    ("\\paragraph{%s}"       . "\\paragraph*{%s}")
    ("\\subparagraph{%s}"    . "\\subparagraph*{%s}")))

;; LaTeX IEEEtran
;; https://alexshroyer.com/posts/2022-06-24-IEEE-org-template.html
;; IEEEtran.cls is available in texlive-publishers package
(require 'ox-latex)
(unless (boundp 'org-latex-classes)
  (setq org-latex-classes nil))
(add-to-list 'org-latex-classes
  '("IEEEtran" "\\documentclass[conference]{IEEEtran}"
    ("\\section{%s}" . "\\section*{%s}")
    ("\\subsection{%s}" . "\\subsection*{%s}")
    ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
    ("\\paragraph{%s}" . "\\paragraph*{%s}")
    ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

; evil home row navigation: hjkl --> jkl;
(define-key evil-motion-state-map "j" 'evil-backward-char)
(define-key evil-motion-state-map "k" 'evil-next-line)
(define-key evil-motion-state-map "l" 'evil-previous-line)
(define-key evil-motion-state-map ";" 'evil-forward-char)
; window home row management: hjkl --> jkl;
; unbinding
(define-key evil-window-map "h" nil)
(define-key evil-window-map "H" nil)
(define-key evil-window-map "j" nil)
(define-key evil-window-map "J" nil)
(define-key evil-window-map "k" nil)
(define-key evil-window-map "K" nil)
(define-key evil-window-map "l" nil)
(define-key evil-window-map "L" nil)
; binding
(define-key evil-window-map "j" 'evil-window-left)
(define-key evil-window-map "J" 'evil-window-move-far-left)
(define-key evil-window-map "k" 'evil-window-down)
(define-key evil-window-map "K" 'evil-window-move-very-bottom)
(define-key evil-window-map "l" 'evil-window-up)
(define-key evil-window-map "L" 'evil-window-move-very-top)
(define-key evil-window-map ";" 'evil-window-right)
(define-key evil-window-map ":" 'evil-window-move-far-right)

; magit home row navigation: hjkl --> jkl;
(after! magit
  (map! :map magit-mode-map
        :n "h" 'magit-log
        :n "j" 'evil-backward-char
        :n "k" 'magit-next-line
        :n "l" 'magit-previous-line
        :n ";" 'evil-forward-char))
