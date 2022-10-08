"""Generate the code reference pages and navigation."""

from pathlib import Path

import mkdocs_gen_files

nav = mkdocs_gen_files.Nav()

EXCLUSIONS = (
    "types.py"
)

for path in sorted(Path("selenium/").rglob("*.py")):
    print(f"Collecting: {path}")
    if str(path).endswith("types.py"): continue
    module_path = path.relative_to("").with_suffix("")
    doc_path = path.relative_to("").with_suffix(".md")
    full_doc_path = Path("ref", doc_path)

    parts = tuple(module_path.parts)

    if parts[-1] == "__init__":
        parts = parts[:-1]
    elif parts[-1] == "__main__":
        continue

    if not parts:
        continue
    nav[parts] = doc_path.as_posix()

    with mkdocs_gen_files.open(full_doc_path, "w") as fd:
        ident = ".".join(parts)
        fd.write(f"::: {ident}")

    mkdocs_gen_files.set_edit_path(full_doc_path, path)

with mkdocs_gen_files.open("ref/summary.md", "w") as nav_file:
    nav_file.writelines(nav.build_literate_nav())
