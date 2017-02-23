;;; ui/doom/config.el

(defvar +doom-theme 'doom-one
  "The color theme currently in use.")

(defvar +doom-font
  (font-spec :family "Fira Mono" :size 12)
  "The font currently in use.")

(defvar +doom-variable-pitch-font
  (font-spec :family "Fira Sans" :size 12)
  "The font currently in use.")

(defvar +doom-unicode-font
  (font-spec :family "DejaVu Sans Mono" :size 12)
  "Fallback font for unicode glyphs.")


;;; Set fonts
(when (display-graphic-p)
  (with-demoted-errors "FONT ERROR: %s"
    (set-frame-font +doom-font t t)
    ;; Fallback to `doom-unicode-font' for Unicode characters
    (when +doom-unicode-font
      (set-fontset-font t 'unicode +doom-unicode-font))
    ;; ...and for variable-pitch mode
    (when +doom-variable-pitch-font
      (set-face-attribute 'variable-pitch nil :font +doom-variable-pitch-font))))


;;; More reliable inter-window border
;; The native border "consumes" a pixel of the fringe on righter-most splits,
;; `window-divider' does not. Available since Emacs 25.1.
(setq window-divider-default-places t
      window-divider-default-bottom-width 0
      window-divider-default-right-width 1)
(window-divider-mode +1)


;; doom-one: gives Emacs a look inspired by Dark One in Atom.
;; <https://github.com/hlissner/emacs-doom-theme>
(def-package! doom-themes :demand t
  :load-path "~/work/plugins/emacs-doom-theme"
  :config
  (load-theme +doom-theme t)

  (defface +doom-folded-face
    `((t (:inherit font-lock-comment-face
          :background ,(face-background 'default))))
    "Face to hightlight `hideshow' overlays."
    :group 'doom)

  ;; Dark frames by default
  (push (cons 'background-color (face-background 'default)) default-frame-alist)
  (push (cons 'foreground-color (face-foreground 'default)) default-frame-alist)

  ;; brighter source buffers
  (defun +doom|buffer-mode-on ()
    "Brightens buffers so long as they represent files and aren't popups."
    (when (and (not doom-buffer-mode)
               (not doom-popup-mode)
               buffer-file-name)
      (doom-buffer-mode +1)))
  (add-hook 'find-file-hook '+doom|buffer-mode-on)
  (add-hook 'after-revert-hook '+doom|buffer-mode-on)

  ;; Popup buffers should always be dimmed
  (defun +doom|buffer-mode-off ()
    (when doom-buffer-mode (doom-buffer-mode -1)))
  (add-hook 'doom-popup-mode-hook '+doom|buffer-mode-off)

  (when (featurep! :feature workspaces)
    (defun +doom|restore-bright-buffers (&rest _)
      "Restore `doom-buffer-mode' in buffers when `persp-mode' loads a session."
      (dolist (buf (persp-buffer-list))
        (with-current-buffer buf
          (+doom|buffer-mode-on))))
    (add-hook '+workspaces-load-session-hook '+doom|restore-bright-buffers))

  ;; Add file icons to doom-neotree
  (require 'doom-neotree)
  (setq doom-neotree-enable-variable-pitch t
        doom-neotree-file-icons 'simple
        doom-neotree-line-spacing 3)

  ;; Add line-highlighting to nlinum
  (require 'doom-nlinum))


;; Causes a flash around the cursor when it moves across a "large" distance.
;; Usually between windows, or across files. This makes it easier to keep track
;; where your cursor is, which I find helpful on my 30" 2560x1600 display.
(def-package! beacon
  :after doom-themes
  :config
  (beacon-mode +1)
  (setq beacon-color (let ((bg (face-attribute 'highlight :background nil t)))
                       (if (eq bg 'unspecified)
                           (face-attribute 'highlight :foreground nil t)
                         bg))
        beacon-blink-when-buffer-changes t
        beacon-blink-when-point-moves-vertically 10))


(after! hideshow
  ;; Nicer code-folding overlays
  (setq hs-set-up-overlay
        (lambda (ov)
          (when (eq 'code (overlay-get ov 'hs))
            (overlay-put
             ov 'display (propertize "  [...]  " 'face '+doom-folded-face))))))


;; subtle diff indicators in the fringe
(after! git-gutter-fringe
  ;; places the git gutter outside the margins.
  (setq-default fringes-outside-margins t)
  ;; thin fringe bitmaps
  (define-fringe-bitmap 'git-gutter-fr:added
    [224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224]
    nil nil 'center)
  (define-fringe-bitmap 'git-gutter-fr:modified
    [224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224 224]
    nil nil 'center)
  (define-fringe-bitmap 'git-gutter-fr:deleted
    [0 0 0 0 0 0 0 0 0 0 0 0 0 128 192 224 240 248]
    nil nil 'center))
