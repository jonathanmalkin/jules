# Code Intelligence

For code navigation (jump to definition, find references, hover for type info, workspace symbol search), prefer the LSP tool over Grep/Glob. LSP gives precise, compiler-level answers when you have a file path and line number.

Grep/Glob remain the right choice for discovery -- finding files by name, searching for string patterns, or exploring unfamiliar code. The two are complementary: Grep to discover, LSP to navigate.
