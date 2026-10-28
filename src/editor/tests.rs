use super::*;

fn key(key: Key) -> Event {
    Event::Key {
        key,
        physical_key: None,
        pressed: true,
        repeat: false,
        modifiers: Default::default(),
    }
}

#[test]
fn edits_preserve_source_identity_unicode_and_tabs() {
    let ctx = egui::Context::default();
    let typesetter = Typesetter::new();
    let mut docs = vec![
        Document::new("main.typ".into(), String::new()),
        Document::new("other.typ".into(), "Other tab".into()),
    ];
    let id = docs[0].source.id();
    assert!(docs[0].event(&Event::Text("Hello é🙂".into()), &ctx));
    typesetter.compile(&mut docs, 0);
    assert!(docs[0].error.is_empty(), "{}", docs[0].error);
    assert!(docs[0].rendered.is_some());
    assert!(docs[0].event(&key(Key::Backspace), &ctx));
    typesetter.compile(&mut docs, 0);
    assert_eq!(docs[0].source.text(), "Hello é");
    assert_eq!(docs[0].source.id(), id);
    assert_eq!(docs[1].source.text(), "Other tab");
    assert!(
        docs[0]
            .stops
            .iter()
            .all(|s| docs[0].source.text().is_char_boundary(s.byte))
    );
}

#[test]
fn incomplete_typst_keeps_last_layout_and_recovers() {
    let ctx = egui::Context::default();
    let typesetter = Typesetter::new();
    let mut docs = vec![Document::new("main.typ".into(), "Hello".into())];
    typesetter.compile(&mut docs, 0);
    let before = typst::utils::hash128(docs[0].rendered.as_ref().unwrap());
    docs[0].move_cursor(5, false);
    docs[0].event(&Event::Text(" #rect(".into()), &ctx);
    typesetter.compile(&mut docs, 0);
    assert!(!docs[0].error.is_empty());
    assert_eq!(
        before,
        typst::utils::hash128(docs[0].rendered.as_ref().unwrap())
    );
    docs[0].event(&Event::Text(")".into()), &ctx);
    typesetter.compile(&mut docs, 0);
    assert!(docs[0].error.is_empty(), "{}", docs[0].error);
    assert_ne!(
        before,
        typst::utils::hash128(docs[0].rendered.as_ref().unwrap())
    );
}

#[test]
fn click_maps_ligatures_and_utf8_back_to_source() {
    let typesetter = Typesetter::new();
    let mut docs = vec![Document::new("main.typ".into(), "office café".into())];
    typesetter.compile(&mut docs, 0);
    let doc = &mut docs[0];
    assert!(doc.error.is_empty(), "{}", doc.error);
    for byte in [1, 2, 3, 4, 10, 12] {
        let stop = doc
            .stops
            .iter()
            .find(|s| s.byte == byte)
            .copied()
            .expect("glyph boundary has a caret");
        doc.click(stop.bottom, false);
        assert_eq!(doc.cursor, byte);
    }
}

#[test]
fn undo_redo_and_selection_use_incremental_edits() {
    let ctx = egui::Context::default();
    let mut doc = Document::new("main.typ".into(), "abc".into());
    doc.move_cursor(3, false);
    doc.move_cursor(1, true);
    assert!(doc.event(&Event::Paste("é".into()), &ctx));
    assert_eq!(doc.source.text(), "aé");
    let mut undo = key(Key::Z);
    if let Event::Key { modifiers, .. } = &mut undo {
        modifiers.command = true;
    }
    assert!(doc.event(&undo, &ctx));
    assert_eq!(doc.source.text(), "abc");
    if let Event::Key { modifiers, .. } = &mut undo {
        modifiers.shift = true;
    }
    assert!(doc.event(&undo, &ctx));
    assert_eq!(doc.source.text(), "aé");
}

#[test]
fn imports_see_other_tabs_in_memory() {
    let typesetter = Typesetter::new();
    let mut docs = vec![
        Document::new("main.typ".into(), "#include \"other.typ\"".into()),
        Document::new("other.typ".into(), "From another tab".into()),
    ];
    typesetter.compile(&mut docs, 0);
    assert!(docs[0].error.is_empty(), "{}", docs[0].error);
    let before = typst::utils::hash128(docs[0].rendered.as_ref().unwrap());
    docs[1].replace(0..4, "Changed");
    typesetter.compile(&mut docs, 0);
    assert!(docs[0].error.is_empty());
    assert_ne!(
        before,
        typst::utils::hash128(docs[0].rendered.as_ref().unwrap())
    );
}
