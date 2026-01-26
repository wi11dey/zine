use tree_sitter::{Parser, Node};
use tree_sitter_zine::LANGUAGE;

fn main() {
    let code = r#"int"#;
    
    let mut parser = Parser::new();
    parser.set_language(&LANGUAGE.into()).expect("Error loading Zine parser");
    
    let tree = parser.parse(code, None).expect("Error parsing code");
    let root_node = tree.root_node();
    
    println!("Parse successful! Root node kind: {}", root_node.kind());
}
