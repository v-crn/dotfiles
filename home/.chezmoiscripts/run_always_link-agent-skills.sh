#!/bin/sh
# Sync ~/.agents/skills/* into each coding agent's skills directory as symlinks.
# Runs on every chezmoi apply so new skills are linked automatically.
# Existing symlinks are preserved; stale (broken) symlinks are removed.

AGENTS_SKILLS="${HOME}/.agents/skills"

link_skills() {
    target_dir="$1"
    # Relative depth from target_dir to HOME (e.g. ~/.claude/skills → ../../)
    rel_prefix="$2"

    [ -d "${AGENTS_SKILLS}" ] || return 0
    mkdir -p "${target_dir}"

    # Remove stale (broken) symlinks
    # Use /* (not /*/) so broken symlinks are included in the glob
    for link in "${target_dir}"/*; do
        [ -L "$link" ] || continue
        [ -e "$link" ] || rm "$link"
    done

    # Create missing symlinks
    for skill_dir in "${AGENTS_SKILLS}"/*/; do
        [ -d "${skill_dir}" ] || continue
        skill_name="${skill_dir%/}"
        skill_name="${skill_name##*/}"
        link="${target_dir}/${skill_name}"
        [ -e "${link}" ] && continue
        ln -s "${rel_prefix}.agents/skills/${skill_name}" "${link}"
    done
}

# Claude Code: ~/.claude/skills/  (2 levels below HOME → ../../)
link_skills "${HOME}/.claude/skills" "../../"

# Gemini CLI: ~/.gemini/skills/  (2 levels below HOME → ../../)
link_skills "${HOME}/.gemini/skills" "../../"
