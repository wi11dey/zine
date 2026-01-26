use clap::{Parser as ClapParser, ValueEnum};
use tree_sitter::{Parser, Node};
use tree_sitter_zine::LANGUAGE;

#[derive(Copy, Clone, Debug, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
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

fn traverse_tree(node: Node, depth: usize) {
    let indent = "  ".repeat(depth);
    println!("\\{}{}", indent, node.kind());
    
    let mut cursor = node.walk();
    for child in node.children(&mut cursor) {
        traverse_tree(child, depth + 1);
    }
}

fn main() {
    let args = Args::parse();
    
    let code = r#"int"#;
    
    let mut parser = Parser::new();
    parser.set_language(&LANGUAGE.into()).expect("Error loading Zine parser");
    
    let tree = parser.parse(code, None).expect("Error parsing code");
    let root_node = tree.root_node();
    
    traverse_tree(root_node, 0);
}
