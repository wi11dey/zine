use typst::syntax::ast::{Expr, MathTextKind};

pub fn push_haskell(haskell: &mut String, math: &Expr) -> Result<(), String> {
    match math {
        Expr::Math(math) => {
            haskell.push('(');
            let mut first = true;
            let mut last_ident = false;
            let mut next_operator = false;
            for expr in math.exprs() {
                if !first {
                    haskell.push(' ');
                }
                first = false;

                if let Expr::MathIdent(_) = expr {
                    if (last_ident) {
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
                push_haskell(haskell, &expr)?;
                if next_operator {
                    haskell.push('`');
                }

                next_operator = !next_operator;
            }
            haskell.push(')');
        }
        Expr::MathText(text) => match text.get() {
            MathTextKind::Grapheme(grapheme) => {
                let variable = grapheme.chars().all(char::is_alphabetic);
                if variable {
                    haskell.push('"');
                }
                haskell.push_str(grapheme.as_str());
                if variable {
                    haskell.push('"');
                }
            }
            MathTextKind::Number(number) => haskell.push_str(number.as_str()),
        },
        Expr::MathIdent(ident) => {
            haskell.push_str(ident.as_str());
        }
        Expr::MathFieldAccess(_) => todo!(),
        Expr::MathShorthand(shorthand) => haskell.push(shorthand.get()),
        Expr::MathCall(_) => todo!(),
        Expr::MathDelimited(_) => todo!(),
        Expr::MathAttach(_) => todo!(),
        Expr::MathPrimes(primes) => {
            haskell.push_str("primes ");
            haskell.push_str(&primes.count().to_string());
            haskell.push(' ');
        }
        Expr::MathFrac(frac) => {
            push_haskell(haskell, &frac.num())?;
            haskell.push('/');
            push_haskell(haskell, &frac.denom())?;
        }
        Expr::MathRoot(_) => todo!(),
        Expr::MathAlignPoint(_) => {},
        _ => Err(format!("unknown expression: {:?}", math))?,
    }

    Ok(())
}
