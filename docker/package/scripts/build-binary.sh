#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA
set -euo pipefail

export OPAMYES=true
mkdir opamroot
export OPAMROOT=$PWD/opamroot

dune_filepath="$1"
binary_name="$2"

# The cc-wrapper below works around two mismatches between the pinned
# toolchain (OCaml 4.14.1; wasmer 3.3.0 via tezos-rust-libs 1.6) and a
# modern Fedora host (GCC 15 defaults to C23; Rust 1.9x):
#
#   1. -std=gnu17: OCaml 4.14.1's runtime/interp.c does not compile under
#      GCC 15's C23 default, and OCaml's configure ignores the CFLAGS env.
#   2. __rust_probestack: wasmer 3.3.0 references this stack-probe symbol,
#      but modern Rust's compiler-builtins no longer exports it, so the
#      static libwasmer.a is left with an undefined reference. We assemble
#      it ourselves (x86_64 only; weak, so a real definition still wins)
#      and append it to every link step. It is weak and self-contained, so
#      it is harmless on the links that do not need it.
real_gcc=$(command -v gcc)
real_cc=$(command -v cc || echo "$real_gcc")
mkdir -p "$PWD/cc-wrapper"

probestack_obj=""
if [ "$(uname -m)" = "x86_64" ]; then
  cat > "$PWD/cc-wrapper/probestack.s" <<'PROBE'
    .text
    .globl __rust_probestack
    .weak  __rust_probestack
    .type  __rust_probestack,@function
__rust_probestack:
    .cfi_startproc
    pushq  %rbp
    .cfi_adjust_cfa_offset 8
    .cfi_offset %rbp, -16
    movq   %rsp, %rbp
    .cfi_def_cfa_register %rbp
    movq   %rax, %r11
    cmpq   $0x1000, %r11
    jna    3f
2:
    subq   $0x1000, %rsp
    testq  %rsp, 8(%rsp)
    subq   $0x1000, %r11
    cmpq   $0x1000, %r11
    ja     2b
3:
    subq   %r11, %rsp
    testq  %rsp, 8(%rsp)
    addq   %rax, %rsp
    leave
    .cfi_def_cfa_register %rsp
    .cfi_adjust_cfa_offset -8
    ret
    .cfi_endproc
    .size __rust_probestack, .-__rust_probestack
    .section .note.GNU-stack,"",@progbits
PROBE
  "$real_gcc" -c "$PWD/cc-wrapper/probestack.s" -o "$PWD/cc-wrapper/probestack.o"
  probestack_obj="$PWD/cc-wrapper/probestack.o"
fi

cat > "$PWD/cc-wrapper/gcc" <<EOF
#!/bin/sh
extra=""
case " \$* " in
  *\\ -c\\ *|*\\ -E\\ *|*\\ -S\\ *) : ;;
  *\\ -o\\ *) extra="$probestack_obj" ;;
esac
exec "$real_gcc" -std=gnu17 "\$@" \$extra
EOF
cat > "$PWD/cc-wrapper/cc" <<EOF
#!/bin/sh
extra=""
case " \$* " in
  *\\ -c\\ *|*\\ -E\\ *|*\\ -S\\ *) : ;;
  *\\ -o\\ *) extra="$probestack_obj" ;;
esac
exec "$real_cc" -std=gnu17 "\$@" \$extra
EOF
chmod +x "$PWD/cc-wrapper/gcc" "$PWD/cc-wrapper/cc"
export PATH="$PWD/cc-wrapper:$PATH"

cd mavryk
opam init local ../opam-repository --bare --disable-sandboxing
opam switch create . --repositories=local --no-install

eval "$(opam env)"
OPAMASSUMEDEPEXTS=true opam install conf-rust conf-rust-2021

export CFLAGS="-fPIC -std=gnu17 ${CFLAGS:-}"
opam install opam/virtual/mavkit-deps.opam --deps-only --criteria="-notuptodate,-changed,-removed"

eval "$(opam env)"
dune build "$dune_filepath"
cp "./_build/default/$dune_filepath" "../$binary_name"
cd ..
