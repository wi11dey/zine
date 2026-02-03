use std::process::Command;
use std::env;
use std::path::PathBuf;

fn main() {
    // Get the path to the Firefox executable
    let firefox_path = find_firefox_executable();
    
    println!("Found Firefox at: {:?}", firefox_path);
    
    // Generate a unique channel ID for IPC communication
    let channel_id = generate_channel_id();
    let child_id = "1"; // Process ID for this content process
    let process_type = "tab"; // Content process type
    
    // Build the command to launch Firefox content process
    let mut cmd = Command::new(&firefox_path);
    
    // Add the contentproc flag and required arguments
    cmd.arg("-contentproc")
       .arg(&channel_id)
       .arg(child_id)
       .arg(process_type);
    
    // Set required environment variables
    cmd.env("MOZ_DISABLE_CONTENT_SANDBOX", "1"); // Disable sandbox for testing
    
    println!("Launching Firefox content process...");
    println!("Command: {:?}", cmd);
    
    // Launch the subprocess
    match cmd.spawn() {
        Ok(mut child) => {
            println!("Content process launched with PID: {:?}", child.id());
            
            // Wait for the process to complete
            match child.wait() {
                Ok(status) => println!("Content process exited with: {:?}", status),
                Err(e) => eprintln!("Error waiting for content process: {}", e),
            }
        }
        Err(e) => {
            eprintln!("Failed to launch content process: {}", e);
        }
    }
}

fn find_firefox_executable() -> PathBuf {
    // Try to find Firefox in the firefox subdirectory first
    let local_firefox = PathBuf::from("firefox/firefox");
    if local_firefox.exists() {
        return local_firefox;
    }
    
    // Otherwise, try common Firefox locations based on OS
    #[cfg(target_os = "macos")]
    {
        let mac_paths = vec![
            "/Applications/Firefox.app/Contents/MacOS/firefox",
            "/Applications/Firefox Nightly.app/Contents/MacOS/firefox",
            "/Applications/Firefox Developer Edition.app/Contents/MacOS/firefox",
        ];
        
        for path in mac_paths {
            let p = PathBuf::from(path);
            if p.exists() {
                return p;
            }
        }
    }
    
    #[cfg(target_os = "linux")]
    {
        let linux_paths = vec![
            "/usr/bin/firefox",
            "/usr/local/bin/firefox",
            "/opt/firefox/firefox",
        ];
        
        for path in linux_paths {
            let p = PathBuf::from(path);
            if p.exists() {
                return p;
            }
        }
    }
    
    #[cfg(target_os = "windows")]
    {
        let win_paths = vec![
            "C:\\Program Files\\Mozilla Firefox\\firefox.exe",
            "C:\\Program Files (x86)\\Mozilla Firefox\\firefox.exe",
        ];
        
        for path in win_paths {
            let p = PathBuf::from(path);
            if p.exists() {
                return p;
            }
        }
    }
    
    // Fall back to PATH
    PathBuf::from("firefox")
}

fn generate_channel_id() -> String {
    // In a real implementation, this would generate a proper IPC channel ID
    // For now, we'll use a simple timestamp-based ID
    use std::time::{SystemTime, UNIX_EPOCH};
    
    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis();
    
    format!("channel_{}", timestamp)
}