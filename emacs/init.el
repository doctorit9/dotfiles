;;; init.el --- Cosmic-powered Emacs configuration -*- lexical-binding: t; -*-

;; Emacs configuration tuned for the COSMIC Desktop dark theme.
;; Provides an IDE-like experience with F5 / F6 / F7 / F8 build shortcuts.

;; ---------------------------------------------------------------------------
;; Performance & startup
;; ---------------------------------------------------------------------------
(setq gc-cons-threshold (* 100 1024 1024))
(setq read-process-output-max (* 4 1024 1024))
(setq load-prefer-newer t)

;; ---------------------------------------------------------------------------
;; Package bootstrap (GNU ELPA + MELPA)
;; ---------------------------------------------------------------------------
(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/"))
      package-archive-priorities
      '(("gnu" . 10) ("nongnu" . 5) ("melpa" . 0)))
(unless (file-exists-p package-user-dir)
  (package-refresh-contents))
(package-initialize)

;; Packages installed on first run (kept here so they can be pre-installed).
(defvar my-packages
  '(orderless vertico marginalia consult corfu cape embark
    embark-consult which-key projectile magit doom-modeline
    nerd-icons rainbow-delimiters exec-path-from-shell)
  "Third-party packages used by this configuration.")

(dolist (pkg my-packages)
  (unless (package-installed-p pkg)
    (package-install pkg)))

(setq package-native-compile t)
(require 'use-package)
(setq use-package-always-ensure t)

;; ---------------------------------------------------------------------------
;; Matugen theme (wallpaper colors; same faces as the COSMIC theme)
;; ---------------------------------------------------------------------------
(add-to-list 'custom-theme-load-path user-emacs-directory)
(load-theme 'matugen t)

(setq custom-file (expand-file-name "custom-set.el" user-emacs-directory))
(when (file-exists-p custom-file) (load custom-file))

;; ---------------------------------------------------------------------------
;; Font: JetBrains Mono Nerd Font, 15px
;; ---------------------------------------------------------------------------
(when (display-graphic-p)
  (let ((cosmic-font (font-spec :family "JetBrainsMono Nerd Font"
                                :size 15 :weight 'regular)))
    (ignore-errors
      (set-face-attribute 'default nil :font cosmic-font)
      (set-face-attribute 'variable-pitch nil
                          :family "JetBrainsMono Nerd Font"
                          :height 110))
    (setq default-frame-alist (assq-delete-all 'font default-frame-alist))
    (add-to-list 'default-frame-alist '(font . "-*-JetBrainsMono Nerd Font-*-15-*"))
    (setq-default line-spacing 0.2)))

;; Use a proportional font for org documents.
(when (and (display-graphic-p) (member "MiSans" (font-family-list)))
  (set-face-attribute 'variable-pitch nil :family "MiSans" :height 1.1))

;; ---------------------------------------------------------------------------
;; Basic editing & UX
;; ---------------------------------------------------------------------------
(scroll-bar-mode -1)
(tool-bar-mode -1)
(menu-bar-mode -1)
(setq inhibit-startup-screen t)
(setq initial-scratch-message "")
(setq ring-bell-function #'ignore)
(tab-bar-mode 1)
(column-number-mode 1)
(size-indication-mode 1)
(savehist-mode 1)
(save-place-mode 1)
(recentf-mode 1)
(winner-mode 1)
(electric-pair-mode 1)
(global-auto-revert-mode 1)
(global-hl-line-mode 1)
(setq display-line-numbers-type 'relative)
(setq display-line-numbers-width-start t)
(global-display-line-numbers-mode 1)
(pixel-scroll-precision-mode 1)
(setq create-lockfiles nil)
(setq confirm-kill-emacs #'y-or-n-p)
(setq vc-follow-symlinks t)
(setq kill-ring-max 200)
(setq echo-keystrokes 0.1)
(setq split-width-threshold 160)

;; Release GC pressure shortly after startup.
(run-with-idle-timer 10 nil (lambda () (setq gc-cons-threshold (* 64 1024 1024))))

;; ---------------------------------------------------------------------------
;; Completion framework: vertico + orderless + marginalia + consult + corfu
;; ---------------------------------------------------------------------------
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic)))))

(use-package vertico
  :init (vertico-mode 1))

(use-package marginalia
  :init (marginalia-mode 1))

(use-package consult
  :config
  (setq consult-project-root-function #'projectile-project-root))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim))
  :init
  (setq embark-prompter 'embark-completing-read-prompter))

(use-package embark-consult
  :after (embark consult)
  :config
  (add-hook 'embark-collect-mode-hook #'consult-preview-at-point-mode))

(use-package corfu
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0.1)
  (corfu-quit-no-match 'separator)
  (corfu-on-exact-match nil)
  :init
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1))

(use-package cape
  :after corfu
  :config
  (add-to-list 'completion-at-point-functions #'cape-file t)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev t))

;; ---------------------------------------------------------------------------
;; which-key: discover key bindings
;; ---------------------------------------------------------------------------
(use-package which-key
  :config (which-key-mode 1))

;; ---------------------------------------------------------------------------
;; Project management (like IntelliJ projects)
;; ---------------------------------------------------------------------------
(use-package projectile
  :config
  (projectile-mode 1)
  (setq projectile-switch-project-action #'projectile-find-file)
  (setq projectile-indexing-method 'native)
  (setq projectile-enable-caching t))

;; ---------------------------------------------------------------------------
;; Git: magit
;; ---------------------------------------------------------------------------
(use-package magit
  :bind (("C-x g" . magit-status)))

;; ---------------------------------------------------------------------------
;; Modeline: doom-modeline with nerd icons
;; ---------------------------------------------------------------------------
(use-package nerd-icons
  :custom
  (nerd-icons-font-family "Symbols Nerd Font Mono")
  :config
  (when (and (display-graphic-p)
             (not (find-font (font-spec :name "Symbols Nerd Font Mono"))))
    (nerd-icons-install-fonts)))

(use-package doom-modeline
  :after nerd-icons
  :custom
  (doom-modeline-height 26)
  (doom-modeline-buffer-encoding nil)
  (doom-modeline-minor-modes nil)
  (doom-modeline-enable-word-count nil)
  (doom-modeline-buffer-file-name-style 'truncate-with-project)
  :config
  (doom-modeline-mode 1))

;; ---------------------------------------------------------------------------
;; Rainbow delimiters (IDE-style colored parens)
;; ---------------------------------------------------------------------------
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; ---------------------------------------------------------------------------
;; Shell PATH in GUI Emacs (COSMIC launcher does not load rc files)
;; ---------------------------------------------------------------------------
(use-package exec-path-from-shell
  :when (display-graphic-p)
  :config
  (exec-path-from-shell-initialize))

;; ---------------------------------------------------------------------------
;; C/C++ setup
;; ---------------------------------------------------------------------------
(setq-default c-basic-offset 4 tab-width 4 indent-tabs-mode t)
(setq c-default-style "linux")
(setq treesit-font-lock-level 4)
(add-hook 'c-mode-common-hook
          (lambda () (setq show-trailing-whitespace t)))

;; LSP (eglot): activates only when a language server is installed.
;;   C/C++ needs clangd:   sudo dnf install clang-tools-extra
;;   Python needs pyright or pylsp.
(defun my-eglot-ensure-if-server ()
  "Enable eglot for the current buffer when a suitable server exists."
  (when (cond
         ((derived-mode-p 'c-mode 'c-ts-mode 'c++-mode 'c++-ts-mode)
          (or (executable-find "clangd") (executable-find "ccls")))
         ((derived-mode-p 'python-mode 'python-ts-mode)
          (or (executable-find "pyright") (executable-find "pylsp")))
         ((derived-mode-p 'rust-mode 'rust-ts-mode)
          (executable-find "rust-analyzer"))
         (t nil))
    (eglot-ensure)))

(use-package eglot
  :ensure nil
  :hook ((c-mode c-ts-mode c++-mode c++-ts-mode python-mode python-ts-mode
                 rust-ts-mode)
         . my-eglot-ensure-if-server)
  :config
  (setq eglot-autoshutdown t))

;; ---------------------------------------------------------------------------
;; Build & Run for C projects (F5 = build+run, F6 = build, F7 = run)
;; ---------------------------------------------------------------------------
(require 'compile)
(require 'comint)

(defvar my-c-run-command nil
  "Shell command used to run the built program, e.g. \"./main 1 2 3\".
Set it per-project with .dir-locals.el or a projectile variable.")

(defun my-jobs ()
  "Number of parallel build jobs (nproc, clamped to [1,16])."
  (let ((n (condition-case nil
               (string-to-number (string-trim (shell-command-to-string "nproc")))
             (error 0))))
    (max 1 (min 16 (if (zerop n) 4 n)))))

(defun my-guess-run-binary (root)
  "Guess the executable produced by building in ROOT."
  (or my-c-run-command
      (let ((cands '("main" "program" "app" "test" "hello" "a.out")))
        (seq-some (lambda (n)
                    (let ((f (expand-file-name n root)))
                      (and (file-executable-p f) n)))
                  cands))
      (seq-some (lambda (f)
                  (and (file-regular-p f)
                       (file-executable-p f)
                       (not (string-match-p
                             (regexp-opt '(".c" ".c++" ".cc" ".cpp" ".h" ".hpp"
                                           ".sh" ".py" ".o" ".so" ".a"
                                           ".cmake" ".txt" ".log" ".md" ".ron"))
                             f))
                       f))
                (directory-files root t))))

(defun my-build-and-run-command (root)
  "Return (BUILD-COMMAND . RUN-COMMAND) for the project rooted at ROOT."
  (cond
   ((file-exists-p (expand-file-name "Makefile" root))
    (cons (format "make -j%d" (my-jobs))
          (my-guess-run-binary root)))
   ((file-exists-p (expand-file-name "build.ninja" root))
    (cons (format "ninja -j%d" (my-jobs))
          (my-guess-run-binary root)))
   ((file-exists-p (expand-file-name "CMakeLists.txt" root))
    (let ((build-dir (expand-file-name "build" root)))
      (unless (file-directory-p build-dir)
        (make-directory build-dir t))
      (cons (format "cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug && cmake --build build -j%d"
                    (my-jobs))
            (expand-file-name "main" build-dir))))
   ((buffer-file-name)
    (let* ((file (expand-file-name (buffer-file-name)))
           (out  (expand-file-name (file-name-base file) (file-name-directory file))))
      (cons (format "cc -Wall -Wextra -g -std=c17 %s -o %s"
                    (shell-quote-argument file)
                    (shell-quote-argument out))
            out)))
   (t (user-error "No build system found (Makefile, CMake, or a C buffer)."))))

(defun my-cc-run-program (cmd)
  "Run CMD in a comint buffer named *run*."
  (when (string-empty-p cmd)
    (user-error "No run command available."))
  (let* ((parts (split-string-and-unquote cmd))
         (prog  (car parts))
         (args  (cdr parts))
         (buf   (apply #'make-comint-in-buffer "run" nil prog nil args)))
    (when (window-live-p (selected-window))
      (select-window (display-buffer buf)))
    (get-buffer-process buf)))

(defun my-cc-build (&optional run-on-success)
  "Compile the C project; when RUN-ON-SUCCESS and a run command exists, run it."
  (interactive)
  (let* ((root (or (and (fboundp 'projectile-project-root)
                        (projectile-project-root))
                   default-directory))
         (build (my-build-and-run-command root))
         (buf (let ((default-directory root))
                (compilation-start (car build) nil (lambda (_) "*c-compilation*")))))
    (when run-on-success
      (save-match-data
        (let ((proc (get-buffer-process buf)))
          (when proc
            (set-process-sentinel
             proc (lambda (p _ev)
                    (when (and (memq (process-status p) '(exit signal))
                               (zerop (process-exit-status p)))
                      (if-let* ((run (cdr build)))
                          (my-cc-run-program run)
                        (message "Build OK. No run command set (C-h v my-c-run-command).")))))))))
    (display-buffer buf)))

(defun my-cc-build-and-run ()
  "Build then run the C project (F5)."
  (interactive)
  (my-cc-build t))

(defun my-cc-build-only ()
  "Build the C project without running (F6)."
  (interactive)
  (my-cc-build nil))

(defun my-cc-run-last ()
  "Run the previously built program (F7)."
  (interactive)
  (let* ((root (or (and (fboundp 'projectile-project-root)
                        (projectile-project-root))
                   default-directory))
         (run (my-guess-run-binary root)))
    (if run
        (my-cc-run-program run)
      (user-error "No run command available."))))

(with-eval-after-load 'compile
  (setq compilation-always-kill t)
  (setq compilation-scroll-output 'first-error))

;; F-key IDE shortcuts for C-like modes.  The maps only exist after the
;; C modes are loaded, so bind once per C buffer activation.
(defun my-c-define-fkeys ()
  "Bind F5/F6/F7 build shortcuts in the active C mode map."
  (dolist (map (delq nil (list c-mode-base-map
                               (and (boundp 'c-ts-base-mode-map)
                                    c-ts-base-mode-map))))
    (define-key map (kbd "<f5>") #'my-cc-build-and-run)
    (define-key map (kbd "<f6>") #'my-cc-build-only)
    (define-key map (kbd "<f7>") #'my-cc-run-last)))

(add-hook 'c-mode-common-hook #'my-c-define-fkeys)
(with-eval-after-load 'c-ts-mode
  (add-hook 'c-ts-mode-hook #'my-c-define-fkeys))

;; Use the bundled tree-sitter major modes for C/C++ files (Emacs 30 ships
;; the C and C++ grammars, giving IDE-grade highlighting).
(dolist (pat '("\\.c\\'" "\\.h\\'" "\\.i\\'"))
  (add-to-list 'auto-mode-alist `(,pat . c-ts-mode)))
(dolist (pat '("\\.c\\+\\+\\'" "\\.cc\\'" "\\.cpp\\'" "\\.cxx\\'"
               "\\.hh\\'" "\\.hpp\\'" "\\.hxx\\'"))
  (add-to-list 'auto-mode-alist `(,pat . c++-ts-mode)))

;; Tree-sitter highlighting for every language whose grammar is installed.
;; Language <-> (mode, grammar, extensions).  Color faces come from the
;; `font-lock-*' and tree-sitter `font-lock-*' faces in the cosmic theme.
(require 'treesit)
(let ((ts-modes
       '((rust-ts-mode        "rust"        "\\.rs\\'")
         (python-ts-mode      "python"      "\\.py\\'")
         (go-ts-mode          "go"          "\\.go\\'")
         (js-ts-mode          "javascript"  "\\.js\\'" "\\.mjs\\'" "\\.cjs\\'")
         (typescript-ts-mode  "typescript"  "\\.ts\\'")
         (tsx-ts-mode         "tsx"         "\\.tsx\\'")
         (css-ts-mode         "css"         "\\.css\\'")
         (html-ts-mode        "html"        "\\.html\\'" "\\.htm\\'" "\\.xhtml\\'")
         (json-ts-mode        "json"        "\\.json\\'")
         (yaml-ts-mode        "yaml"        "\\.ya?ml\\'")
         (toml-ts-mode        "toml"        "\\.toml\\'")
         (java-ts-mode        "java"        "\\.java\\'")
         (ruby-ts-mode        "ruby"        "\\.rb\\'" "\\.rake\\'")
         (elixir-ts-mode      "elixir"      "\\.ex\\'" "\\.exs\\'")
         (bash-ts-mode        "bash"        "\\.sh\\'" "\\.bash\\'"))))
  (dolist (entry ts-modes)
    (pcase-let ((`(,mode ,lang . ,exts) entry))
      (if (treesit-language-available-p (intern lang))
          (dolist (ext exts)
            (add-to-list 'auto-mode-alist (cons ext mode)))
        (message "cosmic: tree-sitter grammar missing for %s" lang)))))

;; F8 = jump to next compilation error, Shift-F8 = previous.
(global-set-key (kbd "<f8>") #'next-error)
(global-set-key (kbd "<S-f8>") #'previous-error)

;; ---------------------------------------------------------------------------
;; Final touches
;; ---------------------------------------------------------------------------
(setq browse-url-browser-function 'browse-url-generic)
(setq browse-url-generic-program (executable-find "xdg-open"))
(add-hook 'text-mode-hook #'turn-on-auto-fill)
(global-set-key (kbd "C-c w") #'whitespace-cleanup)

(message "Cosmic Emacs loaded.")

;;; init.el ends here