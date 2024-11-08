(
  ;; default EFS profile (Emacs From Scratch)
  ("efs" . ((user-emacs-directory . "~/.config/emacs-efs")
                (server-name . "efs")))

  ;; Doom Emacs profile (Emacs distribution)
   ("doom" . ((user-emacs-directory . "~/.config/emacs-doom")
               (server-name . "doom")
               (env . (("DOOMDIR" . "~/.config/doom")))))
)
