use typst::syntax::ast::{Expr, MathAccess, MathTextKind};

// TODO produce LINE and COLUMN pragmas as well
pub fn push_haskell(haskell: &mut String, math: Expr) -> Result<(), String> {
    match math {
        Expr::Math(math) => {
            haskell.push('(');
            haskell.push(' ');
            for expr in math.exprs() {
                push_haskell(haskell, expr)?;
                haskell.push(' ')
            }
            haskell.push(')')
        }
        Expr::MathText(text) => match text.get() {
            MathTextKind::Grapheme(grapheme) => haskell.push_str(grapheme.as_str()),
            MathTextKind::Number(number) => haskell.push_str(number.as_str()),
        },
        Expr::MathIdent(ident) => {
            // could be either operand like pi or operator like dot
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
        Expr::Space(_) | Expr::MathAlignPoint(_) => {}
        _ => Err(format!("unknown expression: {:?}", math))?,
    }

    Ok(())
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
