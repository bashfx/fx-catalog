# The Five Pillars of BashFX

These are the core engineering principles for the BashFX project. They ensure that all contributions are high-quality, maintainable, and consistent.

---

### I. Idiomatic & Self-Contained

- **Prioritize Shell Builtins:** Favor native shell commands and constructs over forking external processes (`tput`, `sed`, `awk`) to improve performance and reduce dependencies.
- **Embrace Idiomatic Patterns:** Utilize established, efficient shell patterns (e.g., here-documents, parameter expansion) for clarity and portability.
- **Minimize External Dependencies:** A script's core functionality should not require a trip to the package manager. Build with what the shell provides.

---

### II. Performance and Efficiency

Code must be performant and resource-efficient.

- **Avoid Process Forking:** Be mindful of the performance cost of creating subshells and forking external processes, as guided by Pillar I.
- **Measure and Optimize:** Performance decisions should be based on measurable gains. While POSIX compliance is valued, it may be superseded by more performant Bash-specific features.
- **Efficient Constructs:** Favor idiomatic shell patterns that are known to be efficient.

---

### III. Modularity and Testability

Code must be modular, reusable, and verifiable.

- **Atomic and Reusable Functions:** Decompose logic into small, single-purpose functions that can be easily understood, reused, and tested in isolation.
- **Isolate for Reusability:** Design functions to be self-contained, minimizing dependencies on global state to facilitate their use in other scripts and libraries.
- **Mandatory Test Drivers:** Every feature must be accompanied by a test driver (`devfx driver [N]`). Code without a corresponding test is considered incomplete.

---

### IV. Portability and Compatibility

Scripts must be portable and run reliably across a range of common Bash environments.

- **Baseline Versioning:** The primary target for compatibility is Bash version 3.2+. Any deviation requiring a newer version must be justified and documented.
- **Reliable Patterns:** Prefer well-established, portable shell scripting patterns over new or experimental syntax that may have limited support.
- **Handle Version Differences:** Be aware of and account for behavioral differences between Bash versions.

---

### V. Clarity (Source & Output)

Code and its output should be as self-explanatory as possible.

- **Self-Documenting Code:** Use clear, descriptive names for variables and functions. A logical structure should make the code's purpose apparent.
- **Purposeful Commenting:** Comments should explain the *why* (the rationale behind a design choice or a non-obvious implementation), not the *what* (which should be clear from the code itself).
- **Structured Visual Feedback:** Use color, symbols, and consistent formatting to convey status and hierarchy in script output.


---

### Architecture Alignment

The Pillars provide general guidance, whereas the `ARCHITECTURE.md` document provides opinionated direction. Its rules, patterns, and guidance take precedence where appropriate.

- **Proper Script**: A so-called "Proper Script" is a self-contained solution that (i) implements the BashFX Standard Interface (set of functions),  (ii) supports the Standard Patterns (especially XDG+) and (iii) builds from the BashFX Script Template. As the library and standard patterns mature, the definition of proper script may expand. Proper here implies that a script is fully featured and compatible with the BashFX framework. A proper script in this context further adheres to the Guest Oath.

- **Meaningful Namespaces**: Namespaces are an ideal because naming things is hard, and context is dynamic. With that in mind, a script should make an heroic attempt to have its own vanity namespace to prevent clobbering in Bashland (e.g., FX_/fx_, MARK_/mark_). The is further extended to all assets and artifacts that have an inherent connection. Namespaces provide a visual hint in regards to ownership, relationship, and functionality. Once such meanings are established, they should be used consistently. 

- **Design Patterns**: Proper scripts should use the style, patterns, and conventions infered, established and applied by the BashFX framework; otherwise old and new guard Bashisms take precedence. 

- **Context Aware**: Core BashFX prioritizes the lowest common denominator, preferring to support the stable tail end rather than the bleeding edge; understanding that many of the low level tools provide sufficient surface to address most design needs. BashFX prefers pre-installed tools, and will defer installing additional packages whenever possible. Whenever higher functionality demands, Proper Scripts should provide graceful degredation or version guards.
