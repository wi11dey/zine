use std::process::id;
use typst::syntax::ast::{Expr, MathAccess, MathTextKind};

// TODO produce LHsExprs instead of direct Haskell to propagate SrcSpans from the untyped typst span
pub fn push_haskell(haskell: &mut String, math: Expr) -> Result<(), String> {
    match math {
        Expr::Math(math) => {
            haskell.push('(');
            let mut first = true;
            let mut last_ident = false;
            let mut next_operator = false;
            for expr in math.exprs() {
                if ignored(&expr) {
                    continue;
                }

                if !first {
                    haskell.push(' ');
                }
                first = false;

                if matches!(expr, Expr::MathIdent(_)) {
                    if last_ident {
                        haskell.push_str("∗ ");
                        next_operator = false;
                    }

                    last_ident = true;
                } else {
                    last_ident = false;
                }

                if next_operator {
                    haskell.push('`');
                }
                push_haskell(haskell, expr)?;
                if next_operator {
                    haskell.push('`');
                }

                next_operator = !next_operator;
            }
            haskell.push(')')
        }
        Expr::MathText(text) => match text.get() {
            MathTextKind::Grapheme(grapheme) => {
                let variable = grapheme.chars().all(char::is_alphabetic);
                if variable {
                    haskell.push('"')
                }
                haskell.push_str(grapheme.as_str());
                if variable {
                    haskell.push('"')
                }
            }
            MathTextKind::Number(number) => haskell.push_str(number.as_str()),
        },
        Expr::MathIdent(ident) => {
            haskell.push_str(ident.as_str());
        }
        Expr::MathFieldAccess(field_access) => {
            push_math_access(haskell, MathAccess::MathFieldAccess(field_access))
        }
        Expr::MathShorthand(shorthand) => haskell.push(shorthand.get()),
        Expr::MathCall(_) => todo!(),
        Expr::MathDelimited(_) => todo!(),
        Expr::MathAttach(_) => todo!(),
        Expr::MathPrimes(primes) => {
            haskell.push_str("primes ");
            haskell.push_str(&primes.count().to_string());
            haskell.push(' ')
        }
        Expr::MathFrac(frac) => {
            push_haskell(haskell, frac.num())?;
            haskell.push('/');
            push_haskell(haskell, frac.denom())?
        }
        Expr::MathRoot(_) => todo!(),
        _ => {
            if !ignored(&math) {
                Err(format!("unknown expression: {:?}", math))?
            }
        }
    }

    Ok(())
}

fn ignored(expr: &Expr) -> bool {
    matches!(expr, Expr::Space(_) | Expr::MathAlignPoint(_))
}

fn push_math_access(haskell: &mut String, access: MathAccess) {
    match access {
        MathAccess::MathIdent(ident) => haskell.push_str(ident.as_str()),
        MathAccess::MathFieldAccess(field_access) => {
            push_math_access(haskell, field_access.target());
            haskell.push('\'');
            haskell.push_str(field_access.field().as_str())
        }
    }
}

#[cfg(test)]
mod tests;
