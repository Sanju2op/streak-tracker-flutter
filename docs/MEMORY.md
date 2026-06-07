# Agent Memory

## Environment Information

- **Current local workspace:** Windows PowerShell at
  `C:\Users\Sanjay\Desktop\projects\streak-tracker-flutter`.
- **Flutter SDK location:** The user does not want Flutter installed on the
  local PC. Flutter commands should be run in the GitHub Codespace, or the
  agent should ask the user to run them there when verification is needed.
- **Guideline:** Treat the live session environment as authoritative. Do not
  assume Linux-only commands when the session provides a Windows workspace.

## Instructions for AI Agents

- **Memory Retention:** Whenever the user types a message containing `#` (e.g.,
  `#note`, `#memory`, or any message containing a hashtag/hash symbol), you must
  add that information/instruction to this `memory.md` file to maintain a
  persistent record across sessions.

## Skill Discovery & Installation Capabilities

- **Installed Skills System:** The `find-skills` tool is installed in
  `/home/sanjay/.agents/skills/find-skills`.
- **Ecosystem:** We use the Skills CLI (`npx skills`) from the open agent
  skills ecosystem (<https://skills.sh/>).
- **Discovering Skills:** If a capability/task is mentioned or needed but not
  currently installed, agents can search for skills using:

  ```bash
  npx skills find [query]
  ```

- **Installing Skills:** Agents are empowered to install new skills globally
  using:

  ```bash
  npx skills add <owner/repo@skill> -g -y
  ```

  And check or update installed skills using `npx skills check` or
  `npx skills update`.
