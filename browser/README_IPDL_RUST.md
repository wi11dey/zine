# IPDL to Rust Translator

This directory contains tools to translate Firefox IPDL (Inter-Process communication Definition Language) files to Rust code.

## Files

- `ipdl2rust.py` - Full IPDL to Rust translator using Firefox's IPDL parser (requires Firefox IPDL modules)
- `ipdl2rust_standalone.py` - Standalone translator with simplified parser (no dependencies)  
- `ipdl_rust_codegen.py` - Advanced code generator with async/await support
- `test.ipdl` - Example IPDL file for testing
- `test_protocol.rs` - Generated Rust code example

## Usage

### Standalone Translator (Recommended for simple protocols)
```bash
python3 ipdl2rust_standalone.py input.ipdl -o output.rs
```

### Full Translator (When Firefox IPDL is available)
```bash
python3 ipdl2rust.py input.ipdl -o output.rs --include /path/to/ipdl/includes
```

## IPDL Format

IPDL files define protocols for inter-process communication:

```ipdl
namespace mozilla {

protocol ProtocolName {
parent:
    async AsyncMessage(nsString data);
    sync SyncMessage(int32_t id) returns (nsString result);
    
child:
    async Notification(bool success);
};

} // namespace mozilla
```

## Generated Rust Code

The translator generates:

1. **Message Enums** - Strongly typed message representations
2. **Protocol Trait** - Handler interface for messages  
3. **Actor Structs** - Parent and Child implementations
4. **Async Support** - Uses tokio for async message handling

Example output:
```rust
pub enum TestProtocolMessage {
    Hello(String),
    GetValue { id: i32 },
}

#[async_trait]
pub trait TestProtocolHandler {
    async fn handle_hello(&mut self, message: String) -> Result<(), Box<dyn Error>>;
    async fn handle_get_value(&mut self, id: i32) -> Result<String, Box<dyn Error>>;
}
```

## Type Mappings

| IPDL Type | Rust Type |
|-----------|-----------|
| bool | bool |
| int32_t | i32 |
| uint32_t | u32 |
| nsString | String |
| nsCString | String |
| array<T> | Vec<T> |
| nullable T | Option<T> |

## Implementation Notes

- The standalone version uses regex-based parsing suitable for simple protocols
- The full version reuses Firefox's IPDL AST for complete language support
- Generated code uses serde for serialization and tokio for async runtime
- Sync messages are handled with oneshot channels for responses

## Future Improvements

- Support for managed protocols (parent/child relationships)
- Memory sharing (Shmem) support
- File descriptor passing
- More complex type conversions
- Integration with Firefox's IPC transport layer