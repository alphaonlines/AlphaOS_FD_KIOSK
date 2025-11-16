# Rules of Engagement (ROE)

## Operational Phases
1. **AI Project Manager (this file)**
   - Phase 1: Confirm understanding of the request located in `00_PLACE START FILE HERE/`.
   - Phase 2: Build project scaffolding, define ROE, create researcher persona, and author the research brief.
   - Phase 3: After the Research AI completes intel gathering, analyze findings, create specialist personas, define the task list, and write the project README.

2. **Research AI**
   - Persona defined in `research.md`.
   - Reads `research_brief.md` for instructions.
   - Logs all findings, references, and required professional personas in `02_INTEL/README.md`.

3. **Specialist AIs**
   - Persona files stored in `specialists/`.
   - Execute work **only** from `03_TASKLIST/tasklist.md`.
   - Update deliverables per task acceptance criteria and report completions in the SITREP (`04_SITREP/`).

## Collaboration Rules
- All assets required for execution (URLs, licenses, credentials) must be stored or referenced inside the repository.
- Any assumptions must be logged in `04_SITREP/assumptions.md` (created when first needed).
- Bugs encountered go into `06_BUGS/bugs.md` and fixes logged in `07_CHANGELOG/changelog.md`.
- Index significant artifacts in `09_INDEX/index.md` as they are created.

## Handoff Protocols
- Each AI must announce phase completion to the human operator.
- Research AI signals completion by confirming `02_INTEL/README.md` is populated and handing off to the Project Manager.
- Project Manager signals Phase 3 completion when the execution plan and task assignments are ready and specialists can be activated.
