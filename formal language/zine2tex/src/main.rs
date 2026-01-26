use std::io::{Write, Result, stdout};
use tree_sitter::{Parser, Node};
use clap::{Parser as ClapParser, ValueEnum};
use tree_sitter_zine::LANGUAGE;

#[derive(Copy, Clone, Debug, PartialEq, ValueEnum)]
enum Format {
    #[value(name = "plain")]
    Plain,
    #[value(name = "latex")]
    LaTeX,
    #[value(name = "context")]
    ConTeXt,
}

#[derive(ClapParser)]
#[command(version, about, long_about = None)]
struct Args {
    /// Output TeX format
    #[arg(long, value_enum, default_value = "latex")]
    format: Format,
}

fn convert<W: Write>(out: &mut W, format: Format, root: Node) -> Result<()> {
    write!(out, "\\{}", root.kind())?;
    let mut cursor = root.walk();
    for child in root.children(&mut cursor) {
        convert(out, format, child)?;
    }
    Ok(())
}

fn main() {
    let args = Args::parse();
    
    let code = r#"int"#;
    
    let mut parser = Parser::new();
    parser.set_language(&LANGUAGE.into()).expect("Error loading Zine parser");
    
    let tree = parser.parse(code, None).expect("Error parsing code");

    convert(&mut stdout(), args.format, tree.root_node()).expect("Error converting");
}
