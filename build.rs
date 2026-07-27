#![feature(exit_status_error)]

use std::error::Error;
use std::path::PathBuf;
use std::process::Command;

fn qlot() -> Result<(), Box<dyn Error>> {
    println!("cargo::rerun-if-changed=qlfile");
    println!("cargo::rerun-if-changed=qlfile.lock");

    Ok(Command::new("qlot").arg("install").status()?.exit_ok()?)
}

fn ecl() -> Result<(), Box<dyn Error>> {
    for flag in String::from_utf8(Command::new("ecl-config").arg("--libs").output()?.stdout)?
        .split_whitespace()
    {
        println!("cargo::rustc-link-arg={flag}")
    }

    Ok(bindgen::Builder::default()
        .header_contents("ecl-wrapper.h", "#include <ecl/ecl.h>")
        .allowlist_function("cl_.*")
        .allowlist_function("ecl_.*")
        .allowlist_function("si_.*")
        .allowlist_type("cl_.*")
        .clang_args(
            pkg_config::Config::new()
                .cargo_metadata(false)
                .probe("bdw-gc")?
                .include_paths
                .into_iter()
                .map(|path| format!("-I{}", path.display())),
        )
        .clang_args(
            String::from_utf8(Command::new("ecl-config").arg("--cflags").output()?.stdout)?
                .split_whitespace(),
        )
        .generate()?
        .write_to_file(PathBuf::from(std::env::var("OUT_DIR").unwrap()).join("ecl.rs"))?)
}

fn main() -> Result<(), Box<dyn Error>> {
    qlot()?;
    ecl()?;

    Ok(())
}
