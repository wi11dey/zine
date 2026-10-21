fn main() {
    pkg_config::Config::new()
        .atleast_version("1.56")
        .probe("pangoft2")
        .expect("PangoFT2 1.56 or newer is required");
}
