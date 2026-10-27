use super::push_haskell;
use typst::syntax::{ast::Expr, parse_math};

fn convert(source: &str) -> Result<String, String> {
    let parsed = parse_math(source);
    let (errors, _) = parsed.errors_and_warnings();
    assert!(
        errors.is_empty(),
        "invalid Typst math {source:?}: {errors:?}"
    );
    let expr = parsed.cast::<Expr>().expect("expected a math expression");
    let mut haskell = String::new();
    push_haskell(&mut haskell, expr)?;
    Ok(haskell)
}

fn assert_haskell(source: &str, expected: &str) {
    assert_eq!(
        convert(source),
        Ok(expected.to_owned()),
        "Typst: {source:?}"
    );
}

#[test]
fn empty_math_is_parenthesized() {
    assert_haskell("", "()");
    assert_haskell(" ", "()");
    assert_haskell("\t\n", "()");
}

#[test]
fn single_letter_variables_are_quoted() {
    assert_haskell("x", r#"("x")"#);
    assert_haskell("Y", r#"("Y")"#);
    assert_haskell("α", r#"("α")"#);
    assert_haskell("é", r#"("é")"#);
}

#[test]
fn numbers_preserve_their_spelling() {
    assert_haskell("0", "(0)");
    assert_haskell("42", "(42)");
    assert_haskell("3.1415", "(3.1415)");
    assert_haskell("001.20", "(001.20)");
}

#[test]
fn nonalphabetic_symbols_are_not_quoted() {
    assert_haskell("+", "(+)");
    assert_haskell("=", "(=)");
    assert_haskell("∞", "(∞)");
}

#[test]
fn named_identifiers_are_emitted_verbatim() {
    assert_haskell("alpha", "(alpha)");
    assert_haskell("pi", "(pi)");
    assert_haskell("sin", "(sin)");
}

#[test]
fn field_access_uses_apostrophes() {
    assert_haskell("arrow.r", "(arrow'r)");
    assert_haskell("arrow.r.long", "(arrow'r'long)");
    assert_haskell("alpha.alt", "(alpha'alt)");
}

#[test]
fn shorthands_expand_to_unicode() {
    assert_haskell("-", "(−)");
    assert_haskell("*", "(∗)");
    assert_haskell("->", "(→)");
    assert_haskell("<=", "(≤)");
    assert_haskell("!=", "(≠)");
}

#[test]
fn math_alternates_operands_and_backticked_operators() {
    // This records the current emitter output, including backticks on symbols.
    assert_haskell("x + y", r#"("x" `+` "y")"#);
    assert_haskell("1 + 2 * 3", "(1 `+` 2 `∗` 3)");
    assert_haskell("x dot y", r#"("x" `dot` "y")"#);
    assert_haskell("1 arrow.r.long 2", "(1 `arrow'r'long` 2)");
}

#[test]
fn whitespace_does_not_change_output_or_operator_positions() {
    assert_haskell("x+y", r#"("x" `+` "y")"#);
    assert_haskell("x + y", r#"("x" `+` "y")"#);
    assert_haskell("  x  +  y  ", r#"("x" `+` "y")"#);
    assert_haskell("\tx\n+\ty\n", r#"("x" `+` "y")"#);
}

#[test]
fn adjacent_identifiers_insert_multiplication() {
    assert_haskell("alpha beta", "(alpha ∗ beta)");
    assert_haskell("alpha beta gamma", "(alpha ∗ beta ∗ gamma)");
    assert_haskell(
        "alpha beta + gamma delta",
        "(alpha ∗ beta `+` gamma ∗ delta)",
    );
    assert_haskell("alpha + beta", "(alpha `+` beta)");
}

#[test]
fn fractions_convert_both_operands() {
    assert_haskell("1/2", "(1/2)");
    assert_haskell("x / 2", r#"("x"/2)"#);
    assert_haskell("alpha / beta", "(alpha/beta)");
    assert_haskell("arrow.r / arrow.l", "(arrow'r/arrow'l)");
}

#[test]
fn fractions_preserve_grouped_and_nested_operands() {
    // Typst retains nested Math nodes for these parenthesized operands.
    assert_haskell("(x + y) / (2 + 3)", r#"((("x" `+` "y"))/((2 `+` 3)))"#);
    assert_haskell("a / (b / c)", r#"("a"/(("b"/"c")))"#);
    assert_haskell("(a / b) / (c / d)", r#"((("a"/"b"))/(("c"/"d")))"#);
}

#[test]
fn standalone_primes_include_their_count() {
    assert_haskell("'", "(primes 1 )");
    assert_haskell("''", "(primes 2 )");
    assert_haskell("'''", "(primes 3 )");
}

#[test]
fn alignment_point_emits_no_text() {
    assert_haskell("&", "()");
}

#[test]
fn unsupported_expressions_return_an_error() {
    let source = r#""hello""#;
    let error = convert(source).expect_err("expected an unsupported expression");
    assert!(
        error.starts_with("unknown expression: Str("),
        "Typst: {source:?}, error: {error}"
    );
    let source = "#true";
    let error = convert(source).expect_err("expected an unsupported expression");
    assert!(
        error.starts_with("unknown expression: Bool("),
        "Typst: {source:?}, error: {error}"
    );
    let source = "x + #true";
    let error = convert(source).expect_err("expected an unsupported expression");
    assert!(
        error.starts_with("unknown expression: Bool("),
        "Typst: {source:?}, error: {error}"
    );
}
