{
  lib,
  runCommand,
  name,
  src,
  extras,
  requirements ? [],
  scripts ? {},
  files ? {},
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
    '')
    extras
  )}

  chmod u+w "$out/scripts"

  ${lib.concatStringsSep "\n" (
    lib.mapAttrsToList (target: source: ''
      if [ -e "$out/scripts/${target}" ] \
        || [ -L "$out/scripts/${target}" ]; then
        echo "Klipper script already exists: ${target}" >&2
        exit 1
      fi

      install -m755 "${source}" "$out/scripts/${target}"
    '')
    scripts
  )}

  ${lib.concatStringsSep "\n" (
    lib.mapAttrsToList (target: source: ''
      targetPath="$out/${target}"
      if [ -e "$targetPath" ] || [ -L "$targetPath" ]; then
        echo "Package file already exists: ${target}" >&2
        exit 1
      fi

      targetDir="$(dirname "$targetPath")"
      mkdir -p "$targetDir"
      chmod u+w "$targetDir"
      cp -rL "${source}" "$targetPath"
    '')
    files
  )}

  chmod u+w "$out/scripts/klippy-requirements.txt"
  ${lib.concatMapStringsSep "\n" (requirementsFile: ''
      printf '\n' >> "$out/scripts/klippy-requirements.txt"
      cat "${requirementsFile}" >> "$out/scripts/klippy-requirements.txt"
    '')
    requirements}
''
