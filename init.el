;;; init.el --- Personal Emacs configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;; Sections:
;;   1. Package setup and environment
;;   2. Evil (Vim keys)
;;   3. Look and feel (theme, clipboard, title, bars, scrolling)
;;   4. Completion and search (vertico, orderless, consult, corfu)
;;   5. Terminal (eat on Linux/WSL, eshell on Windows)
;;   6. Languages (tree-sitter, eglot, C#, C/C++, dotnet helpers)
;;   7. Custom commands
;;   8. Keybindings
;;   9. Customize-managed settings

;;; Code:

;; ---------------------------------------------------------------------------
;; 1. Package setup and environment
;; ---------------------------------------------------------------------------
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Platform check, used below for Windows-only and Linux-only settings
(defconst my/windows-p (eq system-type 'windows-nt)
  "Non-nil when running native Windows Emacs.")

;; Make dotnet global tools (csharp-ls) findable
(let ((tools (expand-file-name ".dotnet/tools"
                               (or (and my/windows-p (getenv "USERPROFILE"))
                                   "~"))))
  (when (file-directory-p tools)
    (add-to-list 'exec-path tools)
    (setenv "PATH" (concat (getenv "PATH") path-separator tools))))

;; Windows: use the Unix tools that ship with Git for Windows (xargs, find,
;; grep), which project search (g /) and project.el need
(when my/windows-p
  (let ((git-usr-bin "C:/Program Files/Git/usr/bin"))
    (when (file-directory-p git-usr-bin)
      (add-to-list 'exec-path git-usr-bin)
      (setenv "PATH" (concat git-usr-bin path-separator (getenv "PATH"))))))

;; Faster communication with language servers (eglot), most noticeable on Windows
(setq read-process-output-max (* 1024 1024))
(when my/windows-p
  (setq w32-pipe-read-delay 0))

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
;; 3. Look and feel
;; ---------------------------------------------------------------------------
(load-theme 'modus-vivendi-deuteranopia t)

;; Hide menu bar, tool bar and scroll bars
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode)   (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; Window title: project folder - buffer name
;; (falls back to the buffer's folder outside a project)
(defvar-local my/title-project-name nil
  "Cached project folder name for the window title.")

(defun my/title-project-name ()
  "Name of the current project's root folder, cached per buffer."
  (or my/title-project-name
      (setq my/title-project-name
            (file-name-nondirectory
             (directory-file-name
              (if-let* ((proj (project-current)))
                  (project-root proj)
                default-directory))))))

(setq frame-title-format
      '((:eval (my/title-project-name))
        " - %b"))
(setq xterm-set-window-title t)

;; Line numbers (absolute) in code and text files
(setq-default display-line-numbers-type t)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)

;; Show whitespace like VS Code: dots for spaces, arrows for tabs
(setq whitespace-style '(face spaces tabs space-mark tab-mark))
(setq whitespace-display-mappings
      '((space-mark ?\s [?\u00B7] [?.])       ; space -> middle dot
        (tab-mark   ?\t [?\u2192 ?\t] [?> ?\t]))) ; tab -> arrow
(with-eval-after-load 'whitespace
  ;; Subtle grey marks, no background highlight
  (set-face-attribute 'whitespace-space nil
                      :background 'unspecified :inherit 'shadow)
  (set-face-attribute 'whitespace-tab nil
                      :background 'unspecified :inherit 'shadow))
(add-hook 'prog-mode-hook #'whitespace-mode)
(add-hook 'text-mode-hook #'whitespace-mode)

;; Scroll one line at a time when the cursor leaves the screen,
;; instead of recentering it
(setq scroll-conservatively 101
      scroll-margin 3)

;; Terminal Emacs (WSL) only: native Windows Emacs uses the clipboard directly
(unless my/windows-p
  ;; Clipboard shared with Windows
  (use-package clipetty
    :ensure t
    :hook (after-init . global-clipetty-mode))

  ;; Pasting from Windows: turn CRLF / CR into plain newlines
  (define-advice xterm-paste (:filter-args (args) my/normalize-newlines)
    (let ((event (car args)))
      (list (list (car event)
                  (replace-regexp-in-string "\r\n?" "\n" (nth 1 event)))))))

;; ---------------------------------------------------------------------------
;; 4. Completion and search
;; Text search (g /, g *) needs ripgrep: sudo pacman -S ripgrep (Arch)
;;   or winget install BurntSushi.ripgrep.MSVC (Windows)
;; ---------------------------------------------------------------------------
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

;; Remember recently opened files and folders (M-x consult-recent-file)
(recentf-mode 1)

;; Project text search (g /) uses ripgrep; results stay in the *xref* buffer.
;; From your code, M-g n / M-g p go to the next / previous match.
(when (executable-find "rg")
  (setq xref-search-program 'ripgrep))

;; Project-wide symbol search through eglot (M-t)
(use-package consult-eglot
  :ensure t
  :after (consult eglot))

;; Completion popup: manual with Ctrl-Space, Tab accepts (like VS Code)
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

;; ---------------------------------------------------------------------------
;; 5. Terminal, like VS Code's integrated terminal
;; Linux/WSL: eat (full terminal). Windows: eshell (eat needs a Unix terminal).
;; ---------------------------------------------------------------------------
(unless my/windows-p
  (use-package eat
    :ensure t
    :config
    ;; Let the shell get your keys (Esc, Ctrl-r, arrows) instead of Evil
    (evil-set-initial-state 'eat-mode 'emacs)))

;; Show the terminal at the bottom, 30% of the window
(add-to-list 'display-buffer-alist
             '("\\*.*\\(eat\\|eshell\\)\\*"
               (display-buffer-in-side-window)
               (side . bottom)
               (window-height . 0.3)))

;; ---------------------------------------------------------------------------
;; 6. Languages
;; C# needs: dotnet-sdk and csharp-ls. The c-sharp tree-sitter grammar is
;;   optional: install it with M-x treesit-install-language-grammar RET c-sharp
;;   (needs a C compiler; on Windows that means MSYS2 gcc). Without it, the
;;   built-in csharp-mode is used instead, and eglot still works.
;; C/C++ needs: clang (for clangd) and ideally a compile_commands.json.
;; ---------------------------------------------------------------------------
(setq treesit-language-source-alist
      '((c-sharp "https://github.com/tree-sitter/tree-sitter-c-sharp")))

;; Use the tree-sitter mode when the grammar is installed, else csharp-mode
(when (and (fboundp 'treesit-language-available-p)
           (treesit-language-available-p 'c-sharp))
  (add-to-list 'auto-mode-alist '("\\.cs\\'" . csharp-ts-mode)))

(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure eglot-rename eglot-format-buffer
             eglot-code-actions eglot-find-implementation
             eglot-find-typeDefinition)
  :hook ((csharp-mode    . eglot-ensure)
         (csharp-ts-mode . eglot-ensure)
         (c-mode         . eglot-ensure)
         (c-ts-mode      . eglot-ensure)
         (c++-mode       . eglot-ensure)
         (c++-ts-mode    . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs
               '((csharp-mode csharp-ts-mode) . ("csharp-ls")))
  (setq eglot-autoshutdown t))

;; C#: 4-space indent, like VS Code
(add-hook 'csharp-ts-mode-hook
          (lambda () (setq-local tab-width 4 csharp-ts-mode-indent-offset 4)))
(add-hook 'csharp-mode-hook
          (lambda () (setq-local tab-width 4 c-basic-offset 4)))

;; ---------------------------------------------------------------------------
;; 7. Custom commands
;; ---------------------------------------------------------------------------

;; Files
(defun my/find-file ()
  "Fuzzy-find a file in the current project, else open any file."
  (interactive)
  (if (project-current)
      (call-interactively #'project-find-file)
    (call-interactively #'find-file)))

;; Terminal: eat on Linux/WSL, eshell on Windows
(defun my/toggle-terminal ()
  "Show or hide a terminal for the current project."
  (interactive)
  (let ((win (seq-find (lambda (w)
                         (with-current-buffer (window-buffer w)
                           (derived-mode-p 'eat-mode 'eshell-mode)))
                       (window-list))))
    (cond (win (delete-window win))
          (my/windows-p (if (project-current) (project-eshell) (eshell)))
          ((project-current) (eat-project))
          (t (eat)))))

;; dotnet: build and test from the folder that holds the .sln
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

;; Half-page cursor movement instead of window scrolling
(defun my/half-page-down ()
  "Move the cursor half a window down."
  (interactive)
  (evil-next-line (/ (window-body-height) 2)))

(defun my/half-page-up ()
  "Move the cursor half a window up."
  (interactive)
  (evil-previous-line (/ (window-body-height) 2)))

;; Delete without touching the clipboard (black hole register)
(evil-define-operator my/delete-no-yank (beg end type)
  "Delete text without saving it to the clipboard."
  (interactive "<R>")
  (evil-delete beg end type ?_))

(evil-define-operator my/delete-char-no-yank (beg end type)
  "Delete character without saving it to the clipboard."
  :motion evil-forward-char
  (interactive "<R>")
  (evil-delete beg end type ?_))

;; Paste over a selection without replacing the clipboard
(defun my/paste-no-yank ()
  "Replace the selection with the clipboard, keeping the clipboard."
  (interactive)
  (let ((evil-kill-on-visual-paste nil))
    (call-interactively #'evil-visual-paste)))

;; Search results: reopen the last g / results (the *xref* buffer)
(defun my/show-search-results ()
  "Show the last search results again."
  (interactive)
  (if-let* ((buf (get-buffer "*xref*")))
      (pop-to-buffer buf)
    (message "No search results yet")))

;; ---------------------------------------------------------------------------
;; 8. Keybindings
;; ---------------------------------------------------------------------------
(global-set-key (kbd "C-c t") #'my/toggle-terminal)
(global-set-key (kbd "C-M-r") #'consult-recent-file)   ; recent files and folders

(with-eval-after-load 'evil
  ;; Leader key: Space
  (evil-set-leader '(normal visual) (kbd "SPC"))

  ;; Normal mode: general
  (evil-define-key 'normal 'global
    (kbd "C-p") #'my/find-file           ; fuzzy find file
    (kbd "C-a") #'mark-whole-buffer)

  ;; Windows: C-w q closes the window but never quits Emacs
  (define-key evil-window-map (kbd "q") #'evil-window-delete)

  ;; Normal mode: code navigation (same keys as your VS Code Vim setup)
  (evil-define-key 'normal 'global
    (kbd "g d") #'xref-find-definitions
    (kbd "g r") #'xref-find-references
    (kbd "g i") #'eglot-find-implementation
    (kbd "g y") #'eglot-find-typeDefinition
    (kbd "g f") #'eglot-format-buffer
    (kbd "g q") #'eglot-code-actions
    (kbd "g s") #'consult-imenu            ; symbols in this file
    (kbd "M-t") #'consult-eglot-symbols    ; symbols in the project
    (kbd "g /") #'project-find-regexp      ; search text in project (results stay open)
    (kbd "g *") (lambda () (interactive)   ; search word under cursor
                  (consult-ripgrep nil (thing-at-point 'symbol)))
    (kbd "g .") #'my/show-search-results   ; reopen last search results
    (kbd "g p") #'eldoc
    (kbd "K")   #'eldoc-doc-buffer
    (kbd "] d") #'flymake-goto-next-error
    (kbd "[ d") #'flymake-goto-prev-error)

  ;; Normal and visual: half-page movement, clipboard-safe deletes
  (evil-define-key '(normal visual) 'global
    (kbd "C-d")       #'my/half-page-down
    (kbd "C-u")       #'my/half-page-up
    (kbd "<leader>d") #'my/delete-no-yank
    (kbd "<leader>x") #'my/delete-char-no-yank)

  ;; Insert mode: Ctrl-Space completion, M-p parameter hints
  (evil-define-key 'insert 'global
    (kbd "C-SPC") #'completion-at-point
    (kbd "M-p")   #'eldoc)

  ;; Visual mode: move selected lines, paste without replacing the clipboard
  (evil-define-key 'visual 'global
    (kbd "J")         (concat ":m '>+1" (kbd "RET") "gv=gv")
    (kbd "K")         (concat ":m '<-2" (kbd "RET") "gv=gv")
    (kbd "<leader>p") #'my/paste-no-yank))

;; ---------------------------------------------------------------------------
;; 9. Customize-managed settings (written by Emacs; avoid hand-editing)
;; ---------------------------------------------------------------------------
(custom-set-variables
 '(package-selected-packages
   '(clipetty consult corfu evil evil-collection orderless vertico)))

(custom-set-faces)

(provide 'init)
;;; init.el ends here
