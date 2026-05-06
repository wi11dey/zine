# MathTeXEngine (Haskell Port)

A Haskell port of MathTeXEngine.jl - a native LaTeX math equation renderer using the diagrams package.

## Overview

MathTeXEngine is a pure Haskell implementation that parses LaTeX mathematical expressions and renders them using the diagrams library. It provides:

- LaTeX math mode parser
- Layout engine for mathematical typesetting
- SVG output via diagrams-svg backend
- Support for common LaTeX math commands

## Features

- **Mathematical constructs**: fractions, square roots, superscripts, subscripts
- **Greek letters and symbols**: `\alpha`, `\beta`, `\omega`, etc.
- **Font commands**: `\mathbb`, `\mathrm`, `\text`, etc.
- **Operators and relations**: properly spaced `+`, `-`, `=`, `<`, etc.
- **Delimiters**: automatic scaling with `\left` and `\right`
- **Functions**: `\sin`, `\cos`, `\log`, etc.

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd math-tex-engine-hs

# Build with Stack
stack build

# Run tests
stack test
```

## Usage

### Command Line

```bash
stack exec math-tex-engine-exe -- "x^2 + \\frac{1}{2}" output.svg
```

### Library API

```haskell
import MathTeXEngine

-- Parse LaTeX expression
expr :: TeXExpr
expr = texParse "x^2 + \\frac{\\alpha}{2}"

-- Generate layout elements
elements :: AnyTeXElement
elements = generateTeXElements "x^2 + \\frac{\\alpha}{2}"

-- Render to SVG
main :: IO ()
main = renderTeXToSVG "x^2 + \\frac{\\alpha}{2}" "output.svg"
```

## Architecture

The system follows a three-stage pipeline:

1. **Tokenization**: LaTeX string → tokens
2. **Parsing**: Tokens → Abstract Syntax Tree (TeXExpr)
3. **Layout**: AST → positioned visual elements (TeXElements)
4. **Rendering**: Elements → SVG via diagrams

### Core Types

```haskell
-- Expression representation
data TeXExpr = TeXExpr TeXExprHead [TeXExpr]
             | TeXChar Char
             | TeXString Text
             | TeXNothing

-- Visual elements
class TeXElement a where
    leftInkBound :: a -> Double
    rightInkBound :: a -> Double
    -- ... other geometric properties

-- Concrete elements
data TeXChar = TeXChar { ... }
data Space = Space { spaceWidth :: Double }
data Group = Group { groupElements :: [(P2 Double, Double, AnyTeXElement)] }
```

## Differences from Julia Version

This Haskell port maintains bug-for-bug compatibility with the Julia version while being idiomatic Haskell:

- Uses diagrams instead of direct font rendering
- Parser uses explicit token types instead of Automa
- Layout uses diagrams' positioning system
- Simplified font metrics (actual font loading delegated to diagrams)

## Examples

```haskell
-- Fraction
renderTeXToSVG "\\frac{1}{2}" "fraction.svg"

-- Superscript and subscript
renderTeXToSVG "x_i^{n+1}" "subsup.svg"

-- Square root
renderTeXToSVG "\\sqrt{x^2 + y^2}" "sqrt.svg"

-- Greek letters
renderTeXToSVG "\\alpha + \\beta = \\gamma" "greek.svg"

-- Complex expression
renderTeXToSVG "\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}" "integral.svg"
```

## License

Same as the original MathTeXEngine.jl project.