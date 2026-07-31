# Filament: AI-Assisted Development (Reference)

Source: <https://filamentphp.com/docs/5.x/introduction/ai> (Filament v5.x)

Verbatim content of Filament's "AI-assisted development" documentation, reproduced for offline reference. This page is the inspiration for how this skill is shaped: idiomatic Filament depends more on the plan (choosing primitives, structuring relationships, anticipating edge cases) than on syntax.

## Introduction

> **Info:** This page is inspired by Laravel's [AI Assisted Development documentation](https://laravel.com/docs/ai). Laravel Boost is developed by the Laravel team, and you can find out more about it in their official docs, alongside other information about building Laravel projects with AI assistance.

AI coding agents like [Claude Code](https://www.claude.com/product/claude-code), [Cursor](https://cursor.com), and [GitHub Copilot](https://github.com/features/copilot) can significantly accelerate your Filament development. Filament includes guidelines for [Laravel Boost](https://laravel.com/ai/boost) that teach AI agents how to write idiomatic Filament code and follow framework conventions. Laravel Boost even allows your agent to search the Filament documentation for answers when it encounters unfamiliar requirements.

## Installing Laravel Boost

Install Boost as a development dependency:

```bash
composer require laravel/boost --dev
```

Then run the interactive installer and select **Filament** when prompted:

```bash
php artisan boost:install
```

The installer will detect your IDE and AI agents, generating the necessary configuration files. To verify installation, check your `AGENTS.md`, `CLAUDE.md`, or similar file for a new **Filament** section.

For more information about Laravel Boost, including available tools, documentation search, and IDE integration, see the [Laravel AI documentation](https://laravel.com/docs/ai).

## Filament Blueprint

The guidelines included with Boost are designed primarily for **implementing agents**: they help agents write correct Filament code once they know what to build. However, the quality of AI-generated code depends heavily on the quality of the plan. When an implementing agent has a clear, detailed specification, it can focus entirely on writing correct code rather than guessing at requirements or making assumptions about your intent.

For complex features, you may find that agents struggle with the planning phase: choosing the right components, structuring relationships, and anticipating edge cases. A vague plan leads to vague code, and you end up spending more time correcting the agent than you saved by using it.

**Filament Blueprint is a premium extension that helps AI agents produce accurate, detailed implementation plans for Filament.** It's compatible with Filament v4 and above.

Blueprint bridges the gap between what you want and what AI agents build. Instead of hoping an agent understands Filament's conventions, Blueprint provides structured planning guidelines that produce unambiguous specification documents.

A blueprint specifies everything an implementing agent needs:

- **Models**: Attributes, casts, relationships, and enums with exact syntax
- **Resources**: Full namespaces, scaffold commands, and configuration
- **Forms**: Field components, validation rules, and layout structure
- **Tables**: Columns, filters, actions, and sorting behavior
- **Authorization**: Plain-English policy rules that translate directly to code
- **Testing**: What to test and how to verify it works
- **More**: Reactive fields, wizards, imports/exports, bulk actions, widgets, multi-tenancy, and more

The guidelines cover details that agents commonly get wrong, like namespaces, method names, component selection, and nested layout calculations, so the implementing agent can write correct code on the first try.

The planning guidelines are designed for planning agents only, they shouldn't consume the implementing agent's context window. The planning agent copies all necessary details (namespaces, documentation URLs to fetch, exact method syntax) into the blueprint itself, so the implementing agent has everything it needs without loading the guidelines.

### Using Blueprint

To create a blueprint, enable **planning mode** in your AI agent and ask it to create a Filament Blueprint for your feature. The agent will produce a detailed specification document ready for direct implementation.

### Running a security audit

Blueprint also ships a **Filament Security Audit** skill that scans a Filament codebase against a catalogue of known security misconfigurations (authorization, file uploads, XSS, query scoping, dependency CVEs, etc.) and writes a per-finding remediation plan. Every entry names the exact file, component namespace, documentation URL, and pasteable fix, so an implementing agent can apply it without guessing.

Naming the skill explicitly in your prompt is the most reliable way to invoke it. The skill also responds to the keywords `security-audit`, `security-review`, `harden`, and `pen-test` when paired with a target like a panel, resource, page, or Livewire component.

The agent will produce a Markdown report grouped by finding category, plus a table of every check performed (`Finding` / `Pass` / `N/A`) and recommended tests for each confirmed issue.
