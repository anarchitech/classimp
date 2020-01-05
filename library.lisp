(cl:in-package :%open-asset-import-library)

(define-foreign-library assimp
  (:darwin "libassimp.dylib")
  (:windows (:or "assimp.dll" "libassimp.dll"));; :calling-convention :stdcall ?
  #++(:unix "libassimp.so")

  ;; NixOS stores its per user path information in $HOME/.nix-profile,
  ;; so we need to aim at that too if we're playing on that system.
  
  (:unix (:or "libassimp.so.4" "libassimp.so.4.1.0" "libassimp.so" "~/.nix-profile/lib/libassimp.so.4" "~/.nix-profile/lib/libassimp.so.4.1.0" "~/.nix-profile/lib/libassimp.so")))

(use-foreign-library assimp)
