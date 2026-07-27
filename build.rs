use std::process::Command;
use std::error::Error;

fn qlot() -> Result<(), Box<dyn Error>> {
    println!("cargo::rerun-if-changed=qlfile");
    println!("cargo::rerun-if-changed=qlfile.lock");

    Command::new("qlot").arg("install").status()?;

    Ok(())
}

fn main() -> Result<(), Box<dyn Error>> {
    qlot()?;

    Ok(())
}
