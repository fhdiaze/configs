;;; init.el --- Personal Emacs configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;; Sections:
;;   1. Package setup and environment
;;   2. Evil (Vim keys)
;;   3. Look and feel (theme, clipboard, title, bars, scrolling)
;;   4. Completion and search (vertico, orderless, consult, corfu)
;;   5. Terminal (eat on Linux/WSL, PowerShell on Windows)
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

;; Font (graphical Emacs only; in WSL the terminal sets the font)
(when (and (display-graphic-p)
           (member "Cascadia Mono" (font-family-list)))
  (set-face-attribute 'default nil :family "Cascadia Mono" :height 120))

;; Cursor (graphical Emacs only): solid box normally, hollow box in insert
;; mode, no blinking. In WSL the terminal draws the cursor instead.
(when (display-graphic-p)
  (blink-cursor-mode -1)
  (setq evil-normal-state-cursor 'box
        evil-visual-state-cursor 'box
        evil-insert-state-cursor 'hollow))

;; Mode line (bottom bar): Vim state, modified dot, file name, line/column,
;; git branch, language, language server and diagnostics. Hides line endings,
;; scroll position and the list of minor modes.
(setq evil-mode-line-format nil)        ; we place the <N>/<I> tag ourselves
(setq-default mode-line-format
              '("%e"
                mode-line-front-space
                (:eval evil-mode-line-tag)
                (:eval (if (buffer-modified-p) " \u25CF " "   ")) ; ● when unsaved
                mode-line-buffer-identification
                "  Ln %l, Col %C  "
                (vc-mode vc-mode)
                "  "
                mode-name
                "  "
                mode-line-misc-info     ; [eglot:project] and E/W/I counts
                mode-line-end-spaces))

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

;; Project text search (g /): deadgrep runs ripgrep directly (fast, also on
;; Windows) and keeps the results in their own buffer. RET opens a match.
(use-package deadgrep
  :ensure t
  :commands deadgrep)

;; Other xref-based searches use ripgrep too when it's installed
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
;; Linux/WSL: eat (full terminal). Windows: PowerShell (eat needs a Unix terminal).
;; ---------------------------------------------------------------------------
(unless my/windows-p
  (use-package eat
    :ensure t
    :config
    ;; Let the shell get your keys (Esc, Ctrl-r, arrows) instead of Evil
    (evil-set-initial-state 'eat-mode 'emacs)))

;; Show the terminal at the bottom, 30% of the window
(add-to-list 'display-buffer-alist
             '("\\*.*\\(eat\\|powershell\\).*\\*"
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
;; EditorConfig: follow each project's .editorconfig (indent size, tabs vs
;; spaces, line endings, final newline, trailing whitespace). Built into
;; Emacs 30+; installed from the package archives on older versions.
(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))

;; Guess indentation from the file itself (tabs vs spaces, indent size) when a
;; project has no .editorconfig. An .editorconfig, when present, still wins.
(use-package dtrt-indent
  :ensure t
  :config
  (setq dtrt-indent-verbosity 0)        ; don't announce what it detected
  (dtrt-indent-global-mode 1))

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
  (setq eglot-autoshutdown t)
  ;; Don't log every message to/from the language server (big speed-up)
  (if (boundp 'eglot-events-buffer-config)
      (setq eglot-events-buffer-config '(:size 0 :format full))
    (setq eglot-events-buffer-size 0)))

;; C#: 4-space indent, like VS Code
(add-hook 'csharp-ts-mode-hook
          (lambda () (setq-local tab-width 4 csharp-ts-mode-indent-offset 4)))
(add-hook 'csharp-mode-hook
          (lambda () (setq-local tab-width 4 c-basic-offset 4)))

;; Diagnostics in the mode line (bottom bar): E:errors W:warnings I:info,
;; for any buffer with flymake on (eglot turns it on for C#, C, C++).
(defun my/flymake-mode-line ()
  "Error, warning and info counts for the current buffer."
  (when (bound-and-true-p flymake-mode)
    (let ((e 0) (w 0) (i 0))
      (dolist (d (flymake-diagnostics))
        (pcase (flymake-diagnostic-type d)
          ((or :error 'eglot-error)     (setq e (1+ e)))
          ((or :warning 'eglot-warning) (setq w (1+ w)))
          (_                            (setq i (1+ i)))))
      (concat " "
              (propertize (format "E:%d" e) 'face (if (> e 0) 'error 'shadow))
              " "
              (propertize (format "W:%d" w) 'face (if (> w 0) 'warning 'shadow))
              " "
              (propertize (format "I:%d" i) 'face (if (> i 0) 'success 'shadow))
              " "))))

(add-to-list 'global-mode-string '(:eval (my/flymake-mode-line)))
(with-eval-after-load 'flymake
  (setq flymake-mode-line-format nil))  ; hide the default "Flymake[...]" text

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

;; Terminal: eat on Linux/WSL, PowerShell on Windows
(defun my/powershell ()
  "Open (or show) PowerShell in the project root, or the current folder."
  (require 'shell)
  (let* ((proj (project-current))
         (root (if proj (project-root proj) default-directory))
         (name (format "*powershell: %s*"
                       (file-name-nondirectory (directory-file-name root))))
         (buf (get-buffer-create name))
         (prog (or (executable-find "pwsh") "powershell")))  ; PowerShell 7 if installed
    (unless (comint-check-proc buf)
      (with-current-buffer buf
        (setq default-directory root)
        (shell-mode)
        (make-comint-in-buffer "powershell" buf prog nil "-NoLogo")))
    (pop-to-buffer buf)))

(defun my/toggle-terminal ()
  "Show or hide a terminal for the current project."
  (interactive)
  (let ((win (seq-find (lambda (w)
                         (with-current-buffer (window-buffer w)
                           (derived-mode-p 'eat-mode 'shell-mode)))
                       (window-list))))
    (cond (win (delete-window win))
          (my/windows-p (my/powershell))
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

;; Formatting: language server when available, else Emacs's own indentation.
;; Formats the selection in visual mode, otherwise the whole buffer.
(defun my/format ()
  "Format the selection or buffer with the language server, or re-indent it."
  (interactive)
  (let* ((region (use-region-p))
         (beg (if region (region-beginning) (point-min)))
         (end (if region (region-end) (point-max))))
    (unless (and (fboundp 'eglot-managed-p)
                 (eglot-managed-p)
                 (condition-case nil
                     (progn (if region (eglot-format beg end) (eglot-format-buffer))
                            t)
                   (error nil)))
      (indent-region beg end))))

;; Diagnostics: show or hide the list of problems in the current file
(defun my/toggle-diagnostics ()
  "Show or hide the list of problems in the current file."
  (interactive)
  (if-let* ((win (seq-find (lambda (w)
                             (with-current-buffer (window-buffer w)
                               (derived-mode-p 'flymake-diagnostics-buffer-mode)))
                           (window-list))))
      (quit-window nil win)
    (flymake-show-buffer-diagnostics)))

;; Search results: reopen the most recent g / results (deadgrep or xref)
(defun my/show-search-results ()
  "Show the last search results again."
  (interactive)
  (if-let* ((buf (seq-find (lambda (b)
                             (with-current-buffer b
                               (derived-mode-p 'deadgrep-mode 'xref--xref-buffer-mode)))
                           (buffer-list))))
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
    (kbd "g f") #'my/format                ; format buffer (LSP, else re-indent)
    (kbd "g q") #'eglot-code-actions
    (kbd "g s") #'consult-imenu            ; symbols in this file
    (kbd "M-t") #'consult-eglot-symbols    ; symbols in the project
    (kbd "g /") #'deadgrep                 ; search text in project (results stay open)
    (kbd "g *") (lambda () (interactive)   ; search word under cursor
                  (consult-ripgrep nil (thing-at-point 'symbol)))
    (kbd "g .") #'my/show-search-results   ; reopen last search results
    (kbd "g p") #'eldoc
    (kbd "K")   #'eldoc-doc-buffer
    (kbd "g e") #'my/toggle-diagnostics    ; show/hide problems in this file
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
    (kbd "g f")       #'my/format          ; format selection
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
