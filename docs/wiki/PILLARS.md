# The Five Pillars of BashFX

These are the core engineering principles for the BashFX project. They ensure that all contributions are high-quality, maintainable, and consistent.

---

### I. Clarity and User Experience

Scripts should provide a clear and intuitive user experience. Output should be structured for immediate comprehension.

- **Structured Visual Feedback:** Use color, symbols (e.g., `✓`, `✗`, `!`), and consistent formatting to convey status and hierarchy.
- **Actionable Output:** Information should be presented in a way that is easy to scan and act upon. Avoid verbose, unstructured text dumps.
- **Consistent Symbology:** Use a standardized set of symbols to represent common states (success, failure, warning) across the framework.

---

### II. Performance and Efficiency

Code must be performant and resource-efficient.

- **Prioritize Shell Builtins:** Use Bash built-in commands whenever possible to avoid the overhead of forking external processes.
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

### V. Code Clarity and Documentation

Code should be as self-explanatory as possible.

- **Self-Documenting Code:** Use clear, descriptive names for variables and functions. A logical structure should make the code's purpose apparent.
- **Purposeful Commenting:** Comments should explain the *why* (the rationale behind a design choice or a non-obvious implementation), not the *what* (which should be clear from the code itself).
- **Refactor for Clarity:** If a section of code is difficult to understand, the preferred solution is to refactor it for clarity rather than adding explanatory comments.
