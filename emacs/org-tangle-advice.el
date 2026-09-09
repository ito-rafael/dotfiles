;; -*- lexical-binding: t; -*-
(defun efs/org-babel-ignore-explicit-tangle-no (info)
  "Intercept Org Babel block INFO.
If `:tangle no' is explicitly present in the block header text,
temporarily strip `:noweb-ref' so it is skipped during noweb expansions."
  (if info
      (let* ((params (nth 2 info))
             (explicit-tangle-no-p nil))
        ;; peek at the raw header string of the current block
        (save-excursion
          (let* ((element (org-element-at-point))
                 (params-str (org-element-property :parameters element)))
            ;; if the header contains literally ":tangle no", flag it
            (when (and (eq (org-element-type element) 'src-block)
                       params-str
                       (string-match-p ":tangle[ \t]+no\\b" params-str))
              (setq explicit-tangle-no-p t))))

        ;; if flagged, remove the :noweb-ref from the parsed params
        (if explicit-tangle-no-p
            (append (list (nth 0 info)
                          (nth 1 info)
                          (assq-delete-all :noweb-ref (copy-alist params)))
                    (nthcdr 3 info))
          ;; otherwise, let the block behave normally
          info))
    nil))

;; apply the advice
(advice-add 'org-babel-get-src-block-info :filter-return #'efs/org-babel-ignore-explicit-tangle-no)
