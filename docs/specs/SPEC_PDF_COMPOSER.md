# Hybrid PDF Composer Spec

Goal
- Combine static pages filled via AcroForm with dynamic Appendix pages for overflow content.
- Produce one flattened, court ready PDF with stable layout and footers.

Sections
- Section A static: patient info, summary, discrepancy table, signature page.
- Section B dynamic: D1 substances, D2 medications, Problems list.

Overflow rules
- Substances: first 3 rows on static page. Additional rows flow to Appendix B1.
- Medications: first 6 rows on static page. Additional rows to Appendix B2.
- Problems: first 4 rows on static page. Additional rows to Appendix B3.
- No truncation allowed. Always overflow to Appendix.

Footers
- Every page shows: Doc ID, short hash, page X of Y.

Fonts
- Embed one sans family with full glyph set. Do not rely on system fonts.

Atomic write
- Write to temp file, fsync, then move to final path.

API sketch
- See code-like API in comments.

Pseudo API
struct PDFSection { id: String, pages: [PDFPageSpec] }
enum PDFPageSpec {
  acroform(templateName: String, fieldMap: [String:String])
  dynamic(renderer: (CGContext, CGRect) -> PDFPageResult)
}
struct PDFPageResult { nextCursor: Int? }

Composer responsibilities
- Open PDF context
- Render static acro pages by field map
- Call dynamic renderers until nextCursor is None
- Stamp footers with doc id and short hash
- Close context and write atomically
