# SPDX-FileCopyrightText: 2021-2022 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

# This file needs to become empty.
self: super: rec {
  # For some reason mavkit-protocol-compiler wants some docs to be present in mavkit libs
  mavkit-libs = super.mavkit-libs.overrideAttrs (o: {
    postFixup = ''
      DUMMY_DOCS_DIR="$OCAMLFIND_DESTDIR/../doc/${o.pname}"
      mkdir -p "$DUMMY_DOCS_DIR"
      for doc in "README.md" "CHANGES.rst" "LICENSE"; do
        touch "$DUMMY_DOCS_DIR/$doc"
      done

      DUMMY_ODOC_PAGES_DIR="$DUMMY_DOCS_DIR/odoc-pages"
      mkdir -p "$DUMMY_ODOC_PAGES_DIR"
      for doc in "mavryk_workers.mld" "mavryk_lwt_result_stdlib.mld" "index.mld"; do
        touch "$DUMMY_ODOC_PAGES_DIR/$doc"
      done
    '';
  });
  mavkit-proto-libs = super.mavkit-proto-libs.overrideAttrs (o: {
    postFixup = ''
      DUMMY_DOCS_DIR="$OCAMLFIND_DESTDIR/../doc/${o.pname}"
      mkdir -p "$DUMMY_DOCS_DIR"
      for doc in "README.md" "CHANGES.rst" "LICENSE"; do
        touch "$DUMMY_DOCS_DIR/$doc"
      done

      DUMMY_ODOC_PAGES_DIR="$DUMMY_DOCS_DIR/odoc-pages"
      mkdir -p "$DUMMY_ODOC_PAGES_DIR"
      for doc in "mavryk_workers.mld" "mavryk_lwt_result_stdlib.mld" "index.mld"; do
        touch "$DUMMY_ODOC_PAGES_DIR/$doc"
      done
    '';
  });
  mavkit-admin-client = super.mavkit-client.overrideAttrs (_ : {
    name = "mavkit-admin-client";
    postInstall = "rm $out/bin/mavkit-client $out/bin/*.sh";
  });
  mavkit-client = super.mavkit-client.overrideAttrs (_ : {
    postInstall = "rm $out/bin/mavkit-admin-client $out/bin/*.sh";
  });
  mavkit-node = super.mavkit-node.overrideAttrs (_ : {
    postInstall = "rm $out/bin/*.sh";
  });
  ocamlfind = super.ocamlfind.overrideAttrs (drv: {
    patches = [ ./install_topfind_196.patch ];
  });
  pyml = super.pyml.overrideAttrs (drv: {
    sourceRoot = ".";
  });
}
