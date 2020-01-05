(cl:in-package :%open-asset-import-library)

(define-foreign-library assimp
  (:darwin "libassimp.dylib")
  (:windows (:or "assimp.dll" "libassimp.dll"));; :calling-convention :stdcall ?
  #++(:unix "libassimp.so")
  (:unix (:or "libassimp.so.4" "libassimp.so.4.1.0" "libassimp.so" "~/.nix-profile/lib/libassimp.so.4" "~/.nix-profile/lib/libassimp.so.4.1.0" "~/.nix-profile/lib/libassimp.so")))

(use-foreign-library assimp)
