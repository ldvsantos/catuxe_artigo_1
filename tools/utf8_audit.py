import argparse
import os
import subprocess
from datetime import datetime
from pathlib import Path

TEXT_EXTS = {
    ".tex",
    ".bib",
    ".md",
    ".txt",
    ".csv",
    ".tsv",
    ".json",
    ".yaml",
    ".yml",
    ".toml",
    ".ini",
    ".cfg",
    ".ps1",
    ".sh",
    ".r",
    ".R",
    ".py",
    ".sty",
    ".cls",
    ".bst",
}

SKIP_DIR_PARTS = {
    ".git",
    "node_modules",
    "_fig_cache",
}


def _repo_root() -> Path:
    out = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
    return Path(out)


def _git_ls_files(repo: Path) -> list[Path]:
    out = subprocess.check_output(["git", "ls-files", "-z"], cwd=repo, text=False)
    parts = out.split(b"\x00")
    rels = [p.decode("utf-8", errors="strict") for p in parts if p]
    return [repo / r for r in rels]


def _should_check(path: Path) -> bool:
    if not path.is_file():
        return False

    # Extension filter (skip extensionless unless clearly text-like)
    if path.suffix and path.suffix not in TEXT_EXTS:
        return False

    # Skip generated/build artifacts
    for part in path.parts:
        if part in SKIP_DIR_PARTS:
            return False

    # Skip common LaTeX aux outputs even if tracked (shouldn't be)
    if path.suffix in {".aux", ".bbl", ".blg", ".fdb_latexmk", ".fls", ".log"}:
        return False

    return True


def _decode_best(data: bytes) -> tuple[str | None, str | None]:
    """Return (text, encoding_used) or (None, None) if undecodable as text."""
    # Null bytes usually indicate binary
    if b"\x00" in data:
        return None, None

    # Prefer UTF-8
    try:
        return data.decode("utf-8"), "utf-8"
    except UnicodeDecodeError:
        pass

    # UTF-8 with BOM
    try:
        return data.decode("utf-8-sig"), "utf-8-sig"
    except UnicodeDecodeError:
        pass

    # Common Windows encodings
    for enc in ("cp1252", "latin-1"):
        try:
            return data.decode(enc), enc
        except UnicodeDecodeError:
            continue

    return None, None


def audit(repo: Path, fix: bool, report_path: Path | None) -> int:
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")

    checked = 0
    ok_utf8 = 0
    needs_fix: list[tuple[Path, str]] = []
    undecodable: list[Path] = []
    fixed: list[Path] = []

    for file_path in _git_ls_files(repo):
        if not _should_check(file_path):
            continue

        data = file_path.read_bytes()
        checked += 1

        text, enc = _decode_best(data)
        if text is None:
            undecodable.append(file_path)
            continue

        # If it's already UTF-8 (or UTF-8 with BOM), accept.
        if enc in {"utf-8", "utf-8-sig"}:
            ok_utf8 += 1
            # Optional: normalize BOM away when fixing
            if fix and enc == "utf-8-sig":
                backup = file_path.with_suffix(file_path.suffix + f".bak-utf8-{timestamp}")
                backup.write_bytes(data)
                file_path.write_text(text, encoding="utf-8", newline="")
                fixed.append(file_path)
            continue

        needs_fix.append((file_path, enc))

        if fix:
            backup = file_path.with_suffix(file_path.suffix + f".bak-utf8-{timestamp}")
            backup.write_bytes(data)
            file_path.write_text(text, encoding="utf-8", newline="")
            # sanity check
            _ = file_path.read_text(encoding="utf-8")
            fixed.append(file_path)

    lines: list[str] = []
    lines.append(f"Repo: {repo}")
    lines.append(f"Checked text files (tracked): {checked}")
    lines.append(f"Already UTF-8: {ok_utf8}")
    lines.append(f"Non-UTF8 but decodable as text: {len(needs_fix)}")
    lines.append(f"Undecodable/binary-like (skipped): {len(undecodable)}")
    if needs_fix:
        lines.append("\nFiles needing UTF-8 conversion:")
        for p, enc in needs_fix:
            lines.append(f"- {p.relative_to(repo)}  (detected: {enc})")
    if undecodable:
        lines.append("\nFiles skipped as binary/undecodable:")
        for p in undecodable:
            lines.append(f"- {p.relative_to(repo)}")
    if fixed:
        lines.append("\nFiles converted to UTF-8 (backups created):")
        for p in fixed:
            lines.append(f"- {p.relative_to(repo)}")

    report = "\n".join(lines) + "\n"
    if report_path:
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(report, encoding="utf-8")

    print(report)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit (and optionally fix) non-UTF8 encodings in tracked text files.")
    parser.add_argument("--fix", action="store_true", help="Convert non-UTF8 text files to UTF-8 (creates .bak backups).")
    parser.add_argument("--report", default="utf8_report.txt", help="Write report to this path (relative to repo root).")
    args = parser.parse_args()

    repo = _repo_root()
    report_path = repo / args.report if args.report else None
    return audit(repo, fix=args.fix, report_path=report_path)


if __name__ == "__main__":
    raise SystemExit(main())
