mod ecl;

fn main() {
    let mut argv = [c"zine".as_ptr().cast_mut(), std::ptr::null_mut()];
    unsafe {
        ecl::cl_boot(1, argv.as_mut_ptr());
        ecl::cl_shutdown();
    }
}
