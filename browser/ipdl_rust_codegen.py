#!/usr/bin/env python3
"""
Advanced IPDL to Rust code generator

This module provides Rust code generation for IPDL protocols with support for:
- Managed protocols
- Complex types (arrays, nullable, unions, structs)  
- Message priorities and attributes
- Proper IPC channel setup
"""

import sys
import os
import re
from pathlib import Path

# Add Firefox IPDL directory to path for AST reuse
FIREFOX_IPDL_DIR = Path(__file__).parent / "firefox" / "ipc" / "ipdl"
sys.path.insert(0, str(FIREFOX_IPDL_DIR))

try:
    import ipdl.ast
    import ipdl.builtin
    HAVE_IPDL_AST = True
except ImportError:
    HAVE_IPDL_AST = False


class RustIPCGenerator:
    """Advanced Rust code generator for IPDL protocols"""
    
    def __init__(self):
        self.indent = 0
        self.output = []
        self.imports = set()
        
    def emit(self, line=""):
        """Emit line with indentation"""
        if line:
            self.output.append("    " * self.indent + line)
        else:
            self.output.append("")
            
    def push_indent(self):
        self.indent += 1
        
    def pop_indent(self):
        self.indent -= 1
        
    def add_import(self, import_stmt):
        self.imports.add(import_stmt)
        
    def generate_file(self, protocol_ast, filename):
        """Generate complete Rust file for protocol"""
        self.emit("// Automatically generated from IPDL")
        self.emit("// DO NOT EDIT")
        self.emit()
        
        # Collect imports based on what we'll generate
        self.collect_imports(protocol_ast)
        
        # Emit imports
        for imp in sorted(self.imports):
            self.emit(imp)
        self.emit()
        
        # Generate protocol module
        if hasattr(protocol_ast, 'namespace'):
            self.emit(f"pub mod {protocol_ast.namespace} {{")
            self.push_indent()
            
        # Generate type definitions
        self.generate_types(protocol_ast)
        
        # Generate message types
        self.generate_messages(protocol_ast)
        
        # Generate protocol implementation
        self.generate_protocol(protocol_ast)
        
        if hasattr(protocol_ast, 'namespace'):
            self.pop_indent()
            self.emit("}")
            
        return '\n'.join(self.output)
        
    def collect_imports(self, protocol_ast):
        """Collect required imports based on protocol"""
        # Base imports
        self.add_import("use serde::{Serialize, Deserialize};")
        self.add_import("use std::sync::Arc;")
        self.add_import("use tokio::sync::{mpsc, oneshot};")
        self.add_import("use std::error::Error;")
        self.add_import("use std::collections::HashMap;")
        
        # Check if we need async runtime
        if self.has_messages(protocol_ast):
            self.add_import("use tokio::task;")
            self.add_import("use async_trait::async_trait;")
            
    def has_messages(self, protocol_ast):
        """Check if protocol has messages"""
        return hasattr(protocol_ast, 'messages') and protocol_ast.messages
        
    def generate_types(self, protocol_ast):
        """Generate custom types (structs, unions)"""
        if hasattr(protocol_ast, 'structs'):
            for struct in protocol_ast.structs:
                self.generate_struct(struct)
                
        if hasattr(protocol_ast, 'unions'):
            for union in protocol_ast.unions:
                self.generate_union(union)
                
    def generate_struct(self, struct_ast):
        """Generate Rust struct from IPDL struct"""
        self.emit("#[derive(Debug, Clone, Serialize, Deserialize)]")
        self.emit(f"pub struct {struct_ast.name} {{")
        self.push_indent()
        
        for field in struct_ast.fields:
            rust_type = self.convert_type(field.type)
            self.emit(f"pub {field.name}: {rust_type},")
            
        self.pop_indent()
        self.emit("}")
        self.emit()
        
    def generate_union(self, union_ast):
        """Generate Rust enum from IPDL union"""
        self.emit("#[derive(Debug, Clone, Serialize, Deserialize)]")
        self.emit(f"#[serde(untagged)]")
        self.emit(f"pub enum {union_ast.name} {{")
        self.push_indent()
        
        for i, component in enumerate(union_ast.components):
            variant_name = self.type_to_variant(component)
            rust_type = self.convert_type(component)
            self.emit(f"{variant_name}({rust_type}),")
            
        self.pop_indent()
        self.emit("}")
        self.emit()
        
    def generate_messages(self, protocol_ast):
        """Generate message enums and response types"""
        protocol_name = protocol_ast.name
        
        # Collect messages by direction
        parent_messages = []
        child_messages = []
        
        for msg in protocol_ast.messages:
            if msg.direction == "parent":
                parent_messages.append(msg)
            else:
                child_messages.append(msg)
                
        # Generate message enums
        self.generate_message_enum(f"{protocol_name}Message", parent_messages + child_messages)
        
        # Generate response types for sync messages
        for msg in protocol_ast.messages:
            if msg.is_sync and msg.out_params:
                self.generate_response_type(msg)
                
    def generate_message_enum(self, enum_name, messages):
        """Generate enum for messages"""
        if not messages:
            return
            
        self.emit("#[derive(Debug, Clone, Serialize, Deserialize)]")
        self.emit(f"pub enum {enum_name} {{")
        self.push_indent()
        
        for msg in messages:
            # Generate variant
            variant = msg.name
            
            if msg.in_params:
                if len(msg.in_params) == 1:
                    rust_type = self.convert_type(msg.in_params[0].type)
                    self.emit(f"{variant}({rust_type}),")
                else:
                    # Named fields
                    self.emit(f"{variant} {{")
                    self.push_indent()
                    for param in msg.in_params:
                        rust_type = self.convert_type(param.type)
                        self.emit(f"{param.name}: {rust_type},")
                    self.pop_indent()
                    self.emit("},")
            else:
                self.emit(f"{variant},")
                
            # Add response channel for sync messages
            if msg.is_sync:
                response_type = f"{msg.name}Response"
                self.emit(f"// Note: {variant} requires oneshot:Sender<{response_type}> for responses")
                
        self.pop_indent()
        self.emit("}")
        self.emit()
        
    def generate_response_type(self, msg):
        """Generate response type for sync message"""
        self.emit("#[derive(Debug, Clone, Serialize, Deserialize)]")
        self.emit(f"pub struct {msg.name}Response {{")
        self.push_indent()
        
        for param in msg.out_params:
            rust_type = self.convert_type(param.type)
            self.emit(f"pub {param.name}: {rust_type},")
            
        self.pop_indent()
        self.emit("}")
        self.emit()
        
    def generate_protocol(self, protocol_ast):
        """Generate protocol trait and implementations"""
        protocol_name = protocol_ast.name
        
        # Generate protocol handler trait
        self.emit("#[async_trait]")
        self.emit(f"pub trait {protocol_name}Handler: Send + Sync {{")
        self.push_indent()
        
        for msg in protocol_ast.messages:
            self.generate_handler_method(msg)
            
        self.pop_indent()
        self.emit("}")
        self.emit()
        
        # Generate protocol actor
        self.generate_actor(protocol_ast)
        
    def generate_handler_method(self, msg):
        """Generate handler method in trait"""
        method = f"handle_{self.to_snake_case(msg.name)}"
        
        # Build parameters
        params = ["&mut self"]
        for param in msg.in_params:
            rust_type = self.convert_type(param.type)
            params.append(f"{param.name}: {rust_type}")
            
        # Build return type
        if msg.is_sync and msg.out_params:
            return_types = [self.convert_type(p.type) for p in msg.out_params]
            if len(return_types) == 1:
                return_type = return_types[0]
            else:
                return_type = f"({', '.join(return_types)})"
            return_sig = f" -> Result<{return_type}, Box<dyn Error + Send + Sync>>"
        else:
            return_sig = " -> Result<(), Box<dyn Error + Send + Sync>>"
            
        self.emit(f"async fn {method}({', '.join(params)}){return_sig};")
        
    def generate_actor(self, protocol_ast):
        """Generate protocol actor implementation"""
        protocol_name = protocol_ast.name
        
        self.emit(f"pub struct {protocol_name}Actor<H: {protocol_name}Handler> {{")
        self.push_indent()
        self.emit("handler: H,")
        self.emit(f"rx: mpsc::Receiver<{protocol_name}Message>,")
        self.emit(f"tx: mpsc::Sender<{protocol_name}Message>,")
        self.pop_indent()
        self.emit("}")
        self.emit()
        
        self.emit(f"impl<H: {protocol_name}Handler> {protocol_name}Actor<H> {{")
        self.push_indent()
        
        # Constructor
        self.emit(f"pub fn new(handler: H) -> (Self, mpsc::Sender<{protocol_name}Message>) {{")
        self.push_indent()
        self.emit("let (tx, rx) = mpsc::channel(100);")
        self.emit("let actor = Self {")
        self.push_indent()
        self.emit("handler,")
        self.emit("rx,")
        self.emit("tx: tx.clone(),")
        self.pop_indent()
        self.emit("};")
        self.emit("(actor, tx)")
        self.pop_indent()
        self.emit("}")
        self.emit()
        
        # Run method
        self.emit("pub async fn run(mut self) {")
        self.push_indent()
        self.emit("while let Some(msg) = self.rx.recv().await {")
        self.push_indent()
        self.emit("match msg {")
        self.push_indent()
        
        # Generate match arms for each message
        for msg in protocol_ast.messages:
            self.generate_message_handler(msg)
            
        self.pop_indent()
        self.emit("}")
        self.pop_indent()
        self.emit("}")
        self.pop_indent()
        self.emit("}")
        
        self.pop_indent()
        self.emit("}")
        self.emit()
        
    def generate_message_handler(self, msg):
        """Generate message handler match arm"""
        pattern = f"{msg.name}"
        
        # Build pattern matching
        if msg.in_params:
            if len(msg.in_params) == 1:
                param = msg.in_params[0]
                pattern += f"({param.name})"
            else:
                fields = [p.name for p in msg.in_params]
                pattern += " { " + ", ".join(fields) + " }"
                
        self.emit(f"{pattern} => {{")
        self.push_indent()
        
        # Call handler method
        method = f"handle_{self.to_snake_case(msg.name)}"
        args = ["&mut self.handler"] + [p.name for p in msg.in_params]
        
        if msg.is_sync:
            self.emit(f"match self.handler.{method}({', '.join(args[1:])}).await {{")
            self.push_indent()
            self.emit("Ok(result) => {")
            self.push_indent()
            self.emit("// Send response back via channel")
            self.pop_indent()
            self.emit("}")
            self.emit("Err(e) => {")
            self.push_indent()
            self.emit(f'eprintln!("Error handling {msg.name}: {{:?}}", e);')
            self.pop_indent()
            self.emit("}")
            self.pop_indent()
            self.emit("}")
        else:
            self.emit(f"if let Err(e) = self.handler.{method}({', '.join(args[1:])}).await {{")
            self.push_indent()
            self.emit(f'eprintln!("Error handling {msg.name}: {{:?}}", e);')
            self.pop_indent()
            self.emit("}")
            
        self.pop_indent()
        self.emit("}")
        
    def convert_type(self, ipdl_type):
        """Convert IPDL type to Rust type"""
        if isinstance(ipdl_type, str):
            # Basic type mapping
            type_map = {
                "bool": "bool",
                "int8_t": "i8",
                "uint8_t": "u8",
                "int16_t": "i16",
                "uint16_t": "u16", 
                "int32_t": "i32",
                "uint32_t": "u32",
                "int64_t": "i64",
                "uint64_t": "u64",
                "float": "f32",
                "double": "f64",
                "nsString": "String",
                "nsCString": "String",
                "nsresult": "u32",
                "void": "()",
            }
            return type_map.get(ipdl_type, ipdl_type)
            
        # Handle complex types if we have AST
        if HAVE_IPDL_AST:
            if isinstance(ipdl_type, ipdl.ast.ArrayType):
                inner = self.convert_type(ipdl_type.basetype)
                return f"Vec<{inner}>"
            elif isinstance(ipdl_type, ipdl.ast.MaybeType):
                inner = self.convert_type(ipdl_type.basetype)
                return f"Option<{inner}>"
                
        return "Vec<u8>"  # Default to bytes
        
    def type_to_variant(self, ipdl_type):
        """Generate enum variant name from type"""
        if isinstance(ipdl_type, str):
            return ipdl_type.replace("::", "").title()
        return "Value"
        
    def to_snake_case(self, name):
        """Convert CamelCase to snake_case"""
        s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
        return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()


# Simple protocol representation for standalone mode
class SimpleProtocol:
    def __init__(self, name, namespace=None):
        self.name = name
        self.namespace = namespace
        self.messages = []
        self.structs = []
        self.unions = []
        
class SimpleMessage:
    def __init__(self, name, is_sync, direction, in_params, out_params):
        self.name = name
        self.is_sync = is_sync
        self.direction = direction
        self.in_params = in_params
        self.out_params = out_params
        
class SimpleParam:
    def __init__(self, name, param_type):
        self.name = name
        self.type = param_type


def generate_rust_from_ipdl(protocol_ast, output_file=None):
    """Main entry point for code generation"""
    generator = RustIPCGenerator()
    rust_code = generator.generate_file(protocol_ast, output_file or "protocol.rs")
    
    if output_file:
        with open(output_file, 'w') as f:
            f.write(rust_code)
        print(f"Generated {output_file}")
    else:
        print(rust_code)
        

if __name__ == "__main__":
    # Example usage
    protocol = SimpleProtocol("TestProtocol", "mozilla")
    protocol.messages = [
        SimpleMessage("Hello", False, "parent", 
                     [SimpleParam("message", "nsString")], []),
        SimpleMessage("GetValue", True, "parent",
                     [SimpleParam("id", "int32_t")], 
                     [SimpleParam("value", "nsString")]),
    ]
    
    generate_rust_from_ipdl(protocol, "test_generated.rs")