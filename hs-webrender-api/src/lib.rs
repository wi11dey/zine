use hs_bindgen::*;
use webrender_api::*;

#[hs_bindgen]
fn hello(name: &str) {
    println!("Hello, {name}!");
}

#[hs_bindgen(a :: DisplayListBuilder)]
fn new_dlb() -> DisplayListBuilder {
    DisplayListBuilder::new(PipelineId::dummy());
}
