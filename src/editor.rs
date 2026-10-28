//! Persistent Typst sources and the small amount of editing state for each tab.
use std::{collections::HashMap, ops::Range, path::PathBuf, sync::Mutex};

use eframe::egui::{self, Event, Key, Pos2, Rect, Stroke, pos2, vec2};
use typst::diag::{FileError, FileResult};
use typst::foundations::{Bytes, Datetime, Duration};
use typst::layout::{Abs, Frame, FrameItem, Point, Transform};
use typst::syntax::{FileId, RootedPath, Source, SyntaxKind, VirtualPath, VirtualRoot};
use typst::text::{Font, FontBook};
use typst::utils::LazyHash;
use typst::{Library, LibraryExt, World};
use typst_layout::PagedDocument;

use crate::display_list::{PAGE_GAP, px};

pub struct Document {
    pub name: String,
    pub source: Source,
    pub rendered: Option<PagedDocument>,
    pub error: String,
    pub scroll: f32,
    pub cursor: usize,
    anchor: usize,
    stops: Vec<Caret>,
    undo: Vec<Edit>,
    redo: Vec<Edit>,
}

#[derive(Clone, Copy)]
struct Caret {
    byte: usize,
    top: Pos2,
    bottom: Pos2,
}

struct Edit {
    start: usize,
    before: String,
    after: String,
}

impl Document {
    pub fn new(name: String, text: String) -> Self {
        let id = RootedPath::new(VirtualRoot::Project, VirtualPath::new(&name).unwrap()).intern();
        Self {
            name,
            source: Source::new(id, text),
            rendered: None,
            error: String::new(),
            scroll: 0.0,
            cursor: 0,
            anchor: 0,
            stops: Vec::new(),
            undo: Vec::new(),
            redo: Vec::new(),
        }
    }

    pub fn height(&self) -> f32 {
        self.rendered.as_ref().map_or(0.0, |doc| {
            doc.pages()
                .iter()
                .map(|p| px(p.frame.height()) + PAGE_GAP)
                .sum::<f32>()
                - PAGE_GAP
        })
    }

    fn selection(&self) -> Range<usize> {
        self.cursor.min(self.anchor)..self.cursor.max(self.anchor)
    }

    fn replace(&mut self, range: Range<usize>, text: &str) -> bool {
        if &self.source.text()[range.clone()] == text {
            return false;
        }
        self.undo.push(Edit {
            start: range.start,
            before: self.source.text()[range.clone()].into(),
            after: text.into(),
        });
        self.redo.clear();
        self.source.edit(range.clone(), text);
        self.cursor = range.start + text.len();
        self.anchor = self.cursor;
        true
    }

    fn move_cursor(&mut self, byte: usize, select: bool) {
        self.cursor = byte.min(self.source.text().len());
        if !select {
            self.anchor = self.cursor;
        }
    }

    pub fn click(&mut self, point: Pos2, select: bool) {
        // A stale layout's spans must never be used against an edited syntax tree.
        if !self.error.is_empty() {
            return;
        }
        if let Some(stop) = self.stops.iter().min_by(|a, b| {
            let distance = |s: &Caret| {
                let y = point.y.clamp(s.top.y, s.bottom.y);
                (point.x - s.bottom.x).powi(2) + 16.0 * (point.y - y).powi(2)
            };
            distance(a).total_cmp(&distance(b))
        }) {
            self.move_cursor(stop.byte, select);
        }
    }

    /// Returns true for each mutation. The caller compiles and submits immediately.
    pub fn event(&mut self, event: &Event, ctx: &egui::Context) -> bool {
        match event {
            Event::Text(text) | Event::Paste(text) | Event::Ime(egui::ImeEvent::Commit(text)) => {
                return self.replace(self.selection(), text);
            }
            Event::Copy | Event::Cut => {
                let range = self.selection();
                ctx.copy_text(self.source.text()[range.clone()].into());
                if matches!(event, Event::Cut) {
                    return self.replace(range, "");
                }
            }
            Event::Key {
                key,
                pressed: true,
                modifiers,
                ..
            } => {
                if modifiers.command && *key == Key::A {
                    self.anchor = 0;
                    self.cursor = self.source.text().len();
                } else if modifiers.command && (*key == Key::Z || *key == Key::Y) {
                    let redo = modifiers.shift || *key == Key::Y;
                    let stack = if redo { &mut self.redo } else { &mut self.undo };
                    if let Some(edit) = stack.pop() {
                        let (old, new) = if redo {
                            (&edit.before, &edit.after)
                        } else {
                            (&edit.after, &edit.before)
                        };
                        self.source.edit(edit.start..edit.start + old.len(), new);
                        self.cursor = edit.start + new.len();
                        self.anchor = self.cursor;
                        if redo {
                            self.undo.push(edit);
                        } else {
                            self.redo.push(edit);
                        }
                        return true;
                    }
                } else {
                    let text = self.source.text();
                    let previous = text[..self.cursor]
                        .char_indices()
                        .next_back()
                        .map_or(0, |(i, _)| i);
                    let next =
                        self.cursor + text[self.cursor..].chars().next().map_or(0, char::len_utf8);
                    match key {
                        Key::Backspace | Key::Delete => {
                            let mut range = self.selection();
                            if range.is_empty() {
                                range = if *key == Key::Backspace {
                                    previous..self.cursor
                                } else {
                                    self.cursor..next
                                };
                            }
                            return self.replace(range, "");
                        }
                        Key::Enter => return self.replace(self.selection(), "\n"),
                        Key::Tab => return self.replace(self.selection(), "  "),
                        Key::ArrowLeft | Key::ArrowRight => {
                            let left = *key == Key::ArrowLeft;
                            let range = self.selection();
                            let byte = if !modifiers.shift && !range.is_empty() {
                                if left { range.start } else { range.end }
                            } else if left {
                                previous
                            } else {
                                next
                            };
                            self.move_cursor(byte, modifiers.shift);
                        }
                        Key::Home | Key::End => {
                            let byte = if *key == Key::Home {
                                if modifiers.command {
                                    0
                                } else {
                                    text[..self.cursor].rfind('\n').map_or(0, |i| i + 1)
                                }
                            } else if modifiers.command {
                                text.len()
                            } else {
                                text[self.cursor..]
                                    .find('\n')
                                    .map_or(text.len(), |i| self.cursor + i)
                            };
                            self.move_cursor(byte, modifiers.shift);
                        }
                        Key::ArrowUp | Key::ArrowDown => {
                            if let Some(current) = self.caret() {
                                let down = *key == Key::ArrowDown;
                                if let Some(target) = self
                                    .stops
                                    .iter()
                                    .filter(|s| {
                                        if down {
                                            s.bottom.y > current.bottom.y + 1.0
                                        } else {
                                            s.bottom.y < current.bottom.y - 1.0
                                        }
                                    })
                                    .min_by(|a, b| {
                                        let distance = |s: &Caret| {
                                            (s.bottom.y - current.bottom.y).abs() * 1000.0
                                                + (s.bottom.x - current.bottom.x).abs()
                                        };
                                        distance(a).total_cmp(&distance(b))
                                    })
                                {
                                    self.move_cursor(target.byte, modifiers.shift);
                                }
                            }
                        }
                        _ => {}
                    }
                }
            }
            _ => {}
        }
        false
    }

    fn caret(&self) -> Option<Caret> {
        self.stops
            .iter()
            .min_by_key(|s| s.byte.abs_diff(self.cursor))
            .copied()
    }

    pub fn reveal_cursor(&mut self, height: f32) {
        if !self.error.is_empty() {
            return;
        }
        if let Some(caret) = self.caret() {
            if caret.top.y < self.scroll {
                self.scroll = (caret.top.y - 16.0).max(0.0);
            } else if caret.bottom.y > self.scroll + height {
                self.scroll = caret.bottom.y - height + 16.0;
            }
        }
    }

    pub fn cursor_rect(&self, origin: Pos2) -> Rect {
        let offset = origin.to_vec2() - vec2(0.0, self.scroll);
        self.caret().map_or(
            Rect::from_min_size(origin + vec2(94.5, 94.5), vec2(1.0, 15.0)),
            |caret| Rect::from_two_pos(caret.top + offset, caret.bottom + offset + vec2(1.0, 0.0)),
        )
    }

    pub fn paint_cursor(&self, painter: &egui::Painter, origin: Pos2) {
        let offset = origin.to_vec2() - vec2(0.0, self.scroll);
        let range = self.selection();
        for pair in self.stops.windows(2) {
            let [a, b] = [pair[0], pair[1]];
            if a.byte >= range.start
                && b.byte <= range.end
                && a.byte < b.byte
                && (a.bottom.y - b.bottom.y).abs() < 1.0
            {
                painter.rect_filled(
                    Rect::from_two_pos(a.top + offset, b.bottom + offset),
                    0.0,
                    egui::Color32::from_black_alpha(40),
                );
            }
        }
        let caret = self.cursor_rect(origin);
        painter.line_segment(
            [caret.left_top(), caret.left_bottom()],
            Stroke::new(1.0, egui::Color32::BLACK),
        );
    }

    fn collect_carets(&mut self) {
        fn walk(frame: &Frame, transform: Transform, source: &Source, out: &mut Vec<Caret>) {
            for (point, item) in frame.items() {
                let transform = transform.pre_concat(Transform::translate(point.x, point.y));
                match item {
                    FrameItem::Group(group) => walk(
                        &group.frame,
                        transform.pre_concat(group.transform),
                        source,
                        out,
                    ),
                    FrameItem::Text(text) => {
                        let mut pen = Point::zero();
                        for glyph in &text.glyphs {
                            let (span, offset) = glyph.span;
                            if span.id() == Some(source.id())
                                && let Some(node) = source.find(span)
                            {
                                let range = node.range();
                                let start = (range.start + usize::from(offset)).min(range.end);
                                let end = if matches!(
                                    node.kind(),
                                    SyntaxKind::Text | SyntaxKind::MathText | SyntaxKind::Space
                                ) {
                                    (start + glyph.range().len()).min(range.end)
                                } else {
                                    range.end
                                };
                                let width = glyph.x_advance.at(text.size);
                                let count = source
                                    .text()
                                    .get(start..end)
                                    .map_or(0, |s| s.chars().count());
                                let boundaries = source
                                    .text()
                                    .get(start..end)
                                    .into_iter()
                                    .flat_map(|s| s.char_indices().map(|(i, _)| start + i))
                                    .chain(std::iter::once(end));
                                for (i, byte) in boundaries.enumerate() {
                                    let x = pen.x + width * (i as f64 / count.max(1) as f64);
                                    let top =
                                        Point::new(x, -pen.y - text.size).transform(transform);
                                    let bottom = Point::new(x, -pen.y + text.size * 0.2)
                                        .transform(transform);
                                    if source.text().is_char_boundary(byte) {
                                        out.push(Caret {
                                            byte,
                                            top: pos2(px(top.x), px(top.y)),
                                            bottom: pos2(px(bottom.x), px(bottom.y)),
                                        });
                                    }
                                }
                            }
                            pen.x += glyph.x_advance.at(text.size);
                            pen.y += glyph.y_advance.at(text.size);
                        }
                    }
                    _ => {}
                }
            }
        }
        self.stops.clear();
        if let Some(doc) = &self.rendered {
            let mut y = 0.0;
            for page in doc.pages() {
                walk(
                    &page.frame,
                    Transform::translate(Abs::zero(), Abs::pt(y * 0.75)),
                    &self.source,
                    &mut self.stops,
                );
                y += f64::from(px(page.frame.height()) + PAGE_GAP);
            }
        }
    }
}

pub struct Typesetter {
    library: LazyHash<Library>,
    book: LazyHash<FontBook>,
    fonts: Vec<Font>,
    root: PathBuf,
    files: Mutex<HashMap<FileId, FileResult<Bytes>>>,
    sources: Mutex<HashMap<FileId, FileResult<Source>>>,
}

impl Typesetter {
    pub fn new() -> Self {
        let fonts: Vec<_> = typst_assets::fonts()
            .chain([
                include_bytes!("../assets/fonts/ChicagoFLF-XY-test.ttf").as_slice(),
                include_bytes!("../assets/fonts/Orbitron-Light.ttf").as_slice(),
            ])
            .flat_map(|bytes| Font::iter(Bytes::new(bytes)))
            .collect();
        Self {
            library: LazyHash::new(Library::default()),
            book: LazyHash::new(FontBook::from_fonts(&fonts)),
            fonts,
            root: std::env::current_dir().expect("working directory"),
            files: Mutex::new(HashMap::new()),
            sources: Mutex::new(HashMap::new()),
        }
    }

    pub fn compile(&self, documents: &mut [Document], active: usize) {
        let world = EditorWorld {
            typesetter: self,
            documents,
            active,
        };
        let result = typst::compile::<PagedDocument>(&world);
        let document = &mut documents[active];
        match result.output {
            Ok(rendered) => {
                document.rendered = Some(rendered);
                document.error.clear();
                document.collect_carets();
            }
            Err(errors) => {
                document.error = errors
                    .iter()
                    .map(|e| e.message.as_str())
                    .collect::<Vec<_>>()
                    .join("; ");
            }
        }
        // Retain recent incremental computations without growing the global cache forever.
        comemo::evict(10);
    }
}

struct EditorWorld<'a> {
    typesetter: &'a Typesetter,
    documents: &'a [Document],
    active: usize,
}

impl World for EditorWorld<'_> {
    fn library(&self) -> &LazyHash<Library> {
        &self.typesetter.library
    }
    fn book(&self) -> &LazyHash<FontBook> {
        &self.typesetter.book
    }
    fn main(&self) -> FileId {
        self.documents[self.active].source.id()
    }
    fn source(&self, id: FileId) -> FileResult<Source> {
        if let Some(doc) = self.documents.iter().find(|d| d.source.id() == id) {
            return Ok(doc.source.clone());
        }
        let mut sources = self.typesetter.sources.lock().unwrap();
        sources
            .entry(id)
            .or_insert_with(|| {
                let bytes = self.file(id)?;
                Ok(Source::new(id, std::str::from_utf8(&bytes)?.into()))
            })
            .clone()
    }
    fn file(&self, id: FileId) -> FileResult<Bytes> {
        if let Some(doc) = self.documents.iter().find(|d| d.source.id() == id) {
            return Ok(Bytes::from_string(doc.source.text().to_owned()));
        }
        self.typesetter
            .files
            .lock()
            .unwrap()
            .entry(id)
            .or_insert_with(|| {
                if !matches!(id.root(), VirtualRoot::Project) {
                    return Err(FileError::Other(Some(
                        "Package downloads are not configured".into(),
                    )));
                }
                let path = id.vpath().realize(&self.typesetter.root)?;
                std::fs::read(&path)
                    .map(Bytes::new)
                    .map_err(|e| FileError::from_io(e, &path))
            })
            .clone()
    }
    fn font(&self, index: usize) -> Option<Font> {
        self.typesetter.fonts.get(index).cloned()
    }
    fn today(&self, _offset: Option<Duration>) -> Option<Datetime> {
        None
    }
}

#[cfg(test)]
mod tests;
