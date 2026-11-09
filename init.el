;;; init.el --- Personal Emacs configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;; Sections:
;;   1. Package setup
;;   2. Evil (Vim keys)
;;   3. Look and clipboard
;;   4. Completion and search (vertico, orderless, consult, corfu)
;;   5. C# (eglot, tree-sitter, dotnet helpers)
;;   6. Keybindings
;;   7. Customize-managed settings

;;; Code:

;; ---------------------------------------------------------------------------
;; 1. Package setup
;; ---------------------------------------------------------------------------
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(add-to-list 'exec-path (expand-file-name "~/.dotnet/tools"))
(setenv "PATH" (concat (getenv "PATH") ":" (expand-file-name "~/.dotnet/tools")))

;; ---------------------------------------------------------------------------
;; 2. Evil (Vim keys)
;; ---------------------------------------------------------------------------
(use-package evil
  :ensure t
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump nil)
  (setq evil-undo-system 'undo-redo)
  :config
  (evil-mode 1))

(use-package evil-collection
  :ensure t
  :after evil
  :config
  (evil-collection-init))

;; ---------------------------------------------------------------------------
;; 3. Look and clipboard
;; ---------------------------------------------------------------------------
(load-theme 'modus-vivendi-deuteranopia t)

(use-package clipetty
  :ensure t
  :hook (after-init . global-clipetty-mode))

;; Pasting from Windows: turn CRLF / CR into plain newlines
(define-advice xterm-paste (:filter-args (args) my/normalize-newlines)
  (let ((event (car args)))
    (list (list (car event)
                (replace-regexp-in-string "\r\n?" "\n" (nth 1 event))))))

(setq frame-title-format
      '((:eval (file-name-nondirectory
                (directory-file-name default-directory)))
        " - %b"))

(setq xterm-set-window-title t)

;; ---------------------------------------------------------------------------
;; 4. Completion and search
;; ---------------------------------------------------------------------------

;; Fuzzy find (Ctrl-p) and search
(use-package vertico
  :ensure t
  :init (vertico-mode 1))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package consult
  :ensure t)

(defun my/find-file ()
  "Fuzzy-find a file in the current project, else open any file."
  (interactive)
  (if (project-current)
      (call-interactively #'project-find-file)
    (call-interactively #'find-file)))

;; Completion popup: manual with Ctrl-Space, Tab accepts (like your VS Code)
(use-package corfu
  :ensure t
  :custom
  (corfu-auto nil)                      ; only show the popup when you ask for it
  (corfu-cycle t)                       ; wrap around at the ends of the list
  :init (global-corfu-mode 1)
  :config
  (define-key corfu-map (kbd "C-n") #'corfu-next)
  (define-key corfu-map (kbd "C-p") #'corfu-previous)
  (define-key corfu-map (kbd "TAB") #'corfu-insert)
  (define-key corfu-map [tab] #'corfu-insert))

;; Integrated terminal, like VS Code's panel
(use-package eat
  :ensure t
  :config
  ;; Let the shell get your keys (Esc, Ctrl-r, arrows) instead of Evil
  (evil-set-initial-state 'eat-mode 'emacs))

;; Show the terminal at the bottom, 30% of the window
(add-to-list 'display-buffer-alist
             '("\\*.*eat\\*"
               (display-buffer-in-side-window)
               (side . bottom)
               (window-height . 0.3)))

(defun my/toggle-terminal ()
  "Show or hide a terminal for the current project."
  (interactive)
  (let ((win (seq-find (lambda (w)
                         (with-current-buffer (window-buffer w)
                           (derived-mode-p 'eat-mode)))
                       (window-list))))
    (if win
        (delete-window win)
      (if (project-current)
          (eat-project)
        (eat)))))

;; ---------------------------------------------------------------------------
;; 5. C#
;; Needs: dotnet-sdk, csharp-ls, and the c-sharp tree-sitter grammar.
;; Install the grammar once with: M-x treesit-install-language-grammar RET c-sharp
;; ---------------------------------------------------------------------------
(setq treesit-language-source-alist
      '((c-sharp "https://github.com/tree-sitter/tree-sitter-c-sharp")))

(add-to-list 'auto-mode-alist '("\\.cs\\'" . csharp-ts-mode))

(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure eglot-rename eglot-format-buffer
             eglot-code-actions eglot-find-implementation
             eglot-find-typeDefinition)
  :hook (csharp-ts-mode . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               '((csharp-mode csharp-ts-mode) . ("csharp-ls")))
  (setq eglot-autoshutdown t))

;; 4-space indent, like VS Code
(add-hook 'csharp-ts-mode-hook
          (lambda () (setq-local tab-width 4 csharp-ts-mode-indent-offset 4)))

;; Build and test from the folder that holds the .sln
(defun my/dotnet (command)
  "Run `dotnet COMMAND' from the folder with the nearest .sln file."
  (let ((default-directory
         (or (locate-dominating-file
              default-directory
              (lambda (dir) (directory-files dir nil "\\.slnx?\\'")))
             default-directory)))
    (compile (concat "dotnet " command))))

(defun my/dotnet-build () (interactive) (my/dotnet "build"))
(defun my/dotnet-test () (interactive) (my/dotnet "test"))

;; ---------------------------------------------------------------------------
;; 6. Keybindings
;; ---------------------------------------------------------------------------
(with-eval-after-load 'evil
  ;; Normal mode: general
  (evil-define-key 'normal 'global
    (kbd "C-p") #'my/find-file          ; fuzzy find file
    (kbd "C-a") #'mark-whole-buffer)

  ;; Insert mode: Ctrl-Space completion, M-p parameter hints
  (evil-define-key 'insert 'global
    (kbd "C-SPC") #'completion-at-point
    (kbd "M-p")   #'eldoc)

  ;; Normal mode: code navigation (same keys as your VS Code Vim setup)
  (evil-define-key 'normal 'global
    (kbd "g d") #'xref-find-definitions
    (kbd "g r") #'xref-find-references
    (kbd "g i") #'eglot-find-implementation
    (kbd "g y") #'eglot-find-typeDefinition
    (kbd "g f") #'eglot-format-buffer
    (kbd "g q") #'eglot-code-actions
    (kbd "g s") #'consult-imenu
    (kbd "g p") #'eldoc
    (kbd "K")   #'eldoc-doc-buffer
    (kbd "] d") #'flymake-goto-next-error
    (kbd "[ d") #'flymake-goto-prev-error))

;; Half-page cursor movement instead of window scrolling
(defun my/half-page-down ()
  (interactive)
  (evil-next-line (/ (window-body-height) 2)))

(defun my/half-page-up ()
  (interactive)
  (evil-previous-line (/ (window-body-height) 2)))

(with-eval-after-load 'evil
  (evil-define-key '(normal visual) 'global
    (kbd "C-d") #'my/half-page-down
    (kbd "C-u") #'my/half-page-up))

;; Scroll one line at a time when the cursor leaves the screen,
;; instead of recentering it
(setq scroll-conservatively 101
      scroll-margin 3)

(global-set-key (kbd "C-c t") #'my/toggle-terminal)

;; ---------------------------------------------------------------------------
;; 7. Customize-managed settings (written by Emacs; avoid hand-editing)
;; ---------------------------------------------------------------------------
(custom-set-variables
 '(package-selected-packages
   '(clipetty consult corfu evil evil-collection orderless vertico)))

(custom-set-faces)

(provide 'init)
;;; init.el ends here
