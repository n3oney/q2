{
  lib,
  runCommand,
  name,
  src,
  extras,
}:
runCommand name {} ''
  mkdir -p "$out"
  cp -rf "${src}/." "$out/"

  chmod u+w "$out/klippy/extras"

  ${lib.concatStringsSep "\n" (
    lib.mapAttrsToList (target: source: ''
      if [ -e "$out/klippy/extras/${target}" ] \
        || [ -L "$out/klippy/extras/${target}" ]; then
        echo "Klippy extra already exists: ${target}" >&2
        exit 1
      fi

      cp -rL \
        "${source}" \
        "$out/klippy/extras/${target}"
    '') extras
  )}
''
