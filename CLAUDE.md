# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**mkdocs-material** is a Material Design theme for MkDocs. It's a hybrid TypeScript/Python project:
- **Frontend**: TypeScript and SCSS source files compiled to CSS/JavaScript bundles
- **Backend**: Python plugins, extensions, and MkDocs template overrides
- **Build System**: Custom TypeScript-based build pipeline with esbuild and Sass

The theme extends MkDocs with Material Design components, advanced search, multi-language support, and custom plugins for documentation features.

## Directory Structure

- **`src/`** - TypeScript and SCSS source code (author here, never commit changes to material/)
- **`material/`** - Generated compiled theme and Python plugins (do not edit directly; regenerated on every build)
  - `material/plugins/` - Python plugins for MkDocs functionality
  - `material/extensions/` - Python extensions for Markdown processing
  - `material/templates/` - Jinja2 templates for MkDocs theme
  - `material/overrides/` - Template overrides for MkDocs
- **`tools/`** - Build system scripts (build.ts is the main orchestrator)
- **`docs/`** - Documentation markdown files and mkdocs.yml configuration
- **`includes/`** - Markdown partials and snippets included in docs
- **`.github/workflows/`** - CI/CD pipelines for automated builds and tests

## Common Development Commands

**Setup & Dependencies**
```bash
npm install                      # Install Node.js dependencies
pip install -r requirements.txt  # Install Python dependencies
```

**Development (watch mode)**
```bash
npm start                        # Watch TypeScript/SCSS changes, rebuild on save (recommended for development)
```

**Building**
```bash
npm run build                    # Production build (optimized, clean rebuild)
npm run build:all               # Build with all language variants
npm run build:dirty             # Rebuild only changed files (faster iteration)
npm run clean                   # Remove compiled material/ directory
```

**Code Quality**
```bash
npm run check                   # Run all checks (TypeScript + SCSS)
npm run check:build             # TypeScript type checking only
npm run check:style             # Lint SCSS and TypeScript
npm run fix                     # Auto-fix linting issues
npm run fix:style:ts            # Auto-fix TypeScript linting only
```

**Testing & Documentation**
```bash
mkdocs serve                    # Serve documentation locally (after build)
mkdocs build                    # Build documentation site
```

## Build System Architecture

The build pipeline is orchestrated by `tools/build.ts`:

1. **Source Compilation**: TypeScript and SCSS from `src/` are compiled using:
   - `esbuild` for JavaScript/TypeScript bundling and minification
   - `sass` for SCSS compilation
   - `postcss` for CSS post-processing (autoprefixer, optimization)

2. **Output**: Compiled assets are placed in `material/` with proper directory structure preserving theme layout

3. **Optimization**: Production builds apply:
   - Minification and tree-shaking
   - CSS optimization with cssnano
   - SVG optimization with svgo
   - Asset inlining where beneficial

4. **Watch Mode**: `npm start` uses chokidar to watch `src/` and incrementally rebuild on changes

**Key Build Flags**:
- `--optimize` - Enables production optimizations (minification, compression)
- `--dirty` - Incremental build (only rebuild changed files)
- `--watch` - Enable watch mode for development
- `--verbose` - Detailed build logging
- `--all` - Build all language variants

## Code Architecture & Conventions

### TypeScript/JavaScript

- **Entry Points**: Compiled from `src/` (typically `src/assets/javascripts/`)
- **Type Checking**: Strict mode enabled (`tsconfig.json`)
- **Linting**: ESLint with custom rules in `.eslintrc`
- **Module System**: ES modules, transpiled for browser compatibility
- **Key Dependencies**: 
  - `lunr` - Full-text search indexing
  - `clipboard` - Copy-to-clipboard functionality
  - `rxjs` - Reactive programming for event handling
  - `preact` - Lightweight alternative to React for UI components

### SCSS/CSS

- **Organization**: SMACSS naming conventions (base, layout, module, state, theme)
- **Linting**: StyleLint with custom rules in `.stylelintrc`
- **Material Design**: Uses Material Design color system and typography
- **Responsive**: Mobile-first approach with breakpoint mixins
- **Key Files**: Base styles in `src/assets/stylesheets/`

### Python Components

All Python code resides in `material/` after build. Key areas:

- **Plugins** (`material/plugins/`): Custom MkDocs plugins for search indexing, tag management, offline functionality, etc.
- **Extensions** (`material/extensions/`): Python-Markdown extensions for custom syntax (superfences, blocks, etc.)
- **Utilities** (`material/utilities/`): Helper functions for color conversion, URL processing, etc.

Python changes here directly affect the theme; no compilation step needed.

### Configuration

- **`mkdocs.yml`** - Main MkDocs configuration: theme settings, plugins, markdown extensions, navigation
- **`pyproject.toml`** - Package metadata, build requirements, and Python project configuration
- **`requirements.txt`** - Python runtime dependencies (subset of pyproject.toml)
- **`package.json`** - Node.js dependencies and build scripts
- **ESLint/StyleLint RC files** - Code style enforcement

## Typical Development Workflow

1. **For frontend changes** (TypeScript/SCSS):
   - Run `npm start` to enable watch mode
   - Edit files in `src/`
   - Build automatically triggers on save
   - Test with `mkdocs serve` in another terminal

2. **For Python plugin/extension changes**:
   - Edit files in `material/plugins/`, `material/extensions/`, or `material/utilities/`
   - Run `npm run build:dirty` or wait for watch to recompile
   - Test with `mkdocs serve`

3. **Before committing**:
   - Run `npm run check` to verify types and style
   - Run `npm run fix` to auto-correct style issues
   - Only commit changes in `src/` and Python files; `material/` is generated
   - Update `CHANGELOG` if making user-facing changes

4. **CI/CD Workflows** (`.github/workflows/`):
   - `build.yml` - Tests build on every push
   - `documentation.yml` - Deploys documentation site

## Important Notes

- **`material/` is generated**: Never manually edit compiled files in `material/`. Edit `src/` instead.
- **Node version**: Requires Node.js >= 18
- **Build time**: Production builds can take 30+ seconds; use `--dirty` or watch mode during development
- **Multi-language support**: Build variants exist for 60+ languages; use `--all` for complete builds, `--optimize` for production
- **Git artifacts**: `.gitignore` excludes `material/` and `node_modules/` — these are always regenerated

## Debugging & Troubleshooting

- **Type errors**: Run `npm run check:build` for TypeScript diagnostics
- **Style issues**: Run `npm run check:style` to identify linting problems
- **Build failures**: Use `npm start` with `--verbose` flag for detailed logs
- **Stale builds**: Run `npm run clean` then `npm run build` for a fresh build
- **Hot reload**: `npm start` watches changes; save files to trigger rebuild

## Resources

- **MkDocs Documentation**: https://www.mkdocs.org/
- **Material Design System**: https://material.io/design/
- **Main Project Docs**: See `/docs` directory (buildable with `mkdocs serve`)
