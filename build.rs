fn main() {
    pkg_config::Config::new()
        .atleast_version("1.56")
        .statik(true)
        .probe("pangoft2")
        .expect("PangoFT2 1.56 or newer is required");

    let status = std::process::Command::new("stack")
        .arg("build")
        .status()
        .expect("Failed to run stack build");
    assert!(status.success(), "stack build failed with {status}");
}
