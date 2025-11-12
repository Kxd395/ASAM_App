You’re right. That list is long, tall, and easy to get lost in. Here’s a compact, clinic-friendly redesign that keeps all items visible, reduces vertical sprawl, and makes navigation fast in portrait and landscape.

---

## What to change

1. Add a search box and a sort toggle

* Sort mode: Category or A to Z.
* Search filters in real time and keeps checked items pinned at the top.

2. Group into collapsible categories with sticky headers

* Cardiovascular, Endocrine and Metabolic, Infectious, Neuro and Musculoskeletal, Respiratory, GI Hepatic Renal, Sensory and Dental, Pain, Other and Write ins.
* Only one category expands by default. Previously checked categories auto expand.

3. Use a compact 2 column checklist

* In landscape: 2 or 3 columns inside each category.
* In portrait: 1 column at small width, 2 columns when space allows.
* Tighten line height and spacing.

4. Keep a Selected drawer

* A pill row at the top shows selected items and provides one tap remove.
* Drawer stays sticky so staff can jump to any selected item.

5. Show write in inputs only when needed

* Cancer, Sexually Transmitted Disease, Infection, Allergies, Other.
* Write ins appear inline right under the checkbox that triggered them.

6. Add quick macros

* None of the above.
* Reviewed and unchanged since last visit.

7. Optional: right edge letter rail for A to Z mode

* Tap letter jumps to the first item for that letter.
* Applies only when A to Z is active.

---

## ASCII mockup

```
Domain 2

Find an item: [__________]  Sort: (•) Category  ( ) A to Z
Selected: [Diabetes ✕] [Chronic Pain ✕] [HIV ✕]                      [Clear all]

▼ Cardiovascular (2)
  [ ] Heart problems        [ ] High Blood Pressure        [ ] High Cholesterol
  [ ] Blood Disorder

▼ Endocrine and Metabolic (1)
  [x] Diabetes

▼ Infectious (1)
  [x] HIV
  [ ] Tuberculosis (TB)
  [ ] Viral Hepatitis (A, B, or C)
  [ ] Sexually Transmitted Disease(s)  [write in ________]
  [ ] Infection(s)                     [write in ________]

▼ Neuro and Musculoskeletal
  [ ] Seizure or Neurological Problems  [ ] Muscle or Joint problems

▼ Respiratory
  [ ] Asthma or Lung Problems

▼ GI Hepatic Renal
  [ ] Stomach or Intestinal Problems    [ ] Liver Problems    [ ] Kidney Problems

▼ Sensory and Dental
  [ ] Vision Problems  [ ] Hearing Problems  [ ] Dental Problems

▼ Pain
  [ ] Chronic Pain     [ ] Acute Pain

▼ Other and Write ins
  [ ] Cancer (specify type) [__________]
  [ ] Allergies             [__________]
  [ ] Other                 [__________]

Macros: [None of the above] [Reviewed and unchanged]
```

---

## Drop-in React blueprint (Tailwind)

This version gives you Category and A to Z, search, compact density, write ins, and the Selected drawer. Swap labels for your exact ASAM text. No extra libraries required.

```jsx
import { useMemo, useState } from "react";

const ITEMS = [
  { id:"heart", label:"Heart problems", cat:"Cardiovascular" },
  { id:"hbp", label:"High Blood Pressure", cat:"Cardiovascular" },
  { id:"chol", label:"High Cholesterol", cat:"Cardiovascular" },
  { id:"blood", label:"Blood Disorder", cat:"Cardiovascular" },
  { id:"hiv", label:"HIV", cat:"Infectious" },
  { id:"tb", label:"Tuberculosis (TB)", cat:"Infectious" },
  { id:"hep", label:"Viral Hepatitis (A, B, or C)", cat:"Infectious" },
  { id:"std", label:"Sexually Transmitted Disease(s)", cat:"Infectious", note:true },
  { id:"inf", label:"Infection(s)", cat:"Infectious", note:true },
  { id:"neuro", label:"Seizure/Neurological Problems", cat:"Neuro and Musculoskeletal" },
  { id:"msk", label:"Muscle/Joint problems", cat:"Neuro and Musculoskeletal" },
  { id:"asthma", label:"Asthma/Lung Problems", cat:"Respiratory" },
  { id:"gi", label:"Stomach/Intestinal Problems", cat:"GI Hepatic Renal" },
  { id:"liver", label:"Liver Problems", cat:"GI Hepatic Renal" },
  { id:"kidney", label:"Kidney Problems", cat:"GI Hepatic Renal" },
  { id:"thyroid", label:"Thyroid Problems", cat:"Endocrine and Metabolic" },
  { id:"diab", label:"Diabetes", cat:"Endocrine and Metabolic" },
  { id:"vision", label:"Vision Problems", cat:"Sensory and Dental" },
  { id:"hearing", label:"Hearing Problems", cat:"Sensory and Dental" },
  { id:"dental", label:"Dental Problems", cat:"Sensory and Dental" },
  { id:"sleep", label:"Sleep Problems", cat:"Other and Write ins" },
  { id:"pain_chronic", label:"Chronic Pain", cat:"Pain" },
  { id:"pain_acute", label:"Acute Pain", cat:"Pain" },
  { id:"cancer", label:"Cancer (specify type(s))", cat:"Other and Write ins", note:true },
  { id:"allergy", label:"Allergies", cat:"Other and Write ins", note:true },
  { id:"other", label:"Other", cat:"Other and Write ins", note:true },
];

const CATS = [
  "Cardiovascular",
  "Endocrine and Metabolic",
  "Infectious",
  "Neuro and Musculoskeletal",
  "Respiratory",
  "GI Hepatic Renal",
  "Sensory and Dental",
  "Pain",
  "Other and Write ins",
];

export default function D2Issues({ value, onChange }) {
  const [q, setQ] = useState("");
  const [sort, setSort] = useState("category"); // "category" or "az"
  const [expanded, setExpanded] = useState(new Set(["Cardiovascular"])); // default open

  const selected = value ?? {};   // shape: { id: { checked:true, note:"" } }

  const toggle = (id) => {
    const next = { ...selected };
    if (next[id]?.checked) delete next[id];
    else next[id] = { checked:true, note: next[id]?.note ?? "" };
    onChange(next);
  };

  const setNote = (id, note) => {
    const next = { ...selected, [id]: { checked:true, note } };
    onChange(next);
  };

  const filtered = useMemo(() => {
    const f = q.trim().toLowerCase();
    if (!f) return ITEMS;
    return ITEMS.filter(it => it.label.toLowerCase().includes(f) || it.cat.toLowerCase().includes(f));
  }, [q]);

  const grouped = useMemo(() => {
    if (sort === "az") {
      return [{ title:"All", items: [...filtered].sort((a,b)=>a.label.localeCompare(b.label)) }];
    }
    const byCat = CATS.map(title => ({
      title,
      items: filtered.filter(it => it.cat === title)
    }));
    return byCat;
  }, [filtered, sort]);

  const selectedIds = Object.keys(selected);

  return (
    <section className="space-y-3">
      {/* Find and sort row */}
      <div className="flex flex-wrap items-center gap-2">
        <input
          className="flex-1 min-w-[200px] rounded-md border px-3 py-2"
          placeholder="Find an item"
          value={q}
          onChange={e=>setQ(e.target.value)}
          aria-label="Search physical health issues"
        />
        <div className="flex items-center gap-2 text-sm">
          <span>Sort:</span>
          <label className="inline-flex items-center gap-1">
            <input type="radio" checked={sort==="category"} onChange={()=>setSort("category")} />
            <span>Category</span>
          </label>
          <label className="inline-flex items-center gap-1">
            <input type="radio" checked={sort==="az"} onChange={()=>setSort("az")} />
            <span>A to Z</span>
          </label>
        </div>
      </div>

      {/* Selected drawer */}
      {selectedIds.length > 0 && (
        <div className="sticky top-0 z-10 bg-black/20 backdrop-blur rounded-md p-2">
          <div className="text-sm mb-1">Selected:</div>
          <div className="flex flex-wrap gap-2">
            {selectedIds.map(id => {
              const label = ITEMS.find(i=>i.id===id)?.label ?? id;
              return (
                <button key={id} type="button"
                  onClick={()=>toggle(id)}
                  className="rounded-full bg-blue-600 text-white text-xs px-2 py-1">
                  {label} ✕
                </button>
              );
            })}
            <button type="button" onClick={()=>onChange({})} className="ml-auto text-xs underline">
              Clear all
            </button>
          </div>
        </div>
      )}

      {/* Groups */}
      {grouped.map(group => (
        <fieldset key={group.title} className="border rounded-lg p-3">
          {sort === "category" && (
            <legend
              className="px-1 text-sm font-semibold cursor-pointer select-none"
              onClick={()=>{
                const next = new Set(expanded);
                next.has(group.title) ? next.delete(group.title) : next.add(group.title);
                setExpanded(next);
              }}
            >
              {group.title} ({group.items.length})
              <span className="ml-2 text-xs">{expanded.has(group.title) ? "Hide" : "Show"}</span>
            </legend>
          )}

          {(sort === "az" || expanded.has(group.title)) && (
            <div className="
              grid gap-x-6 gap-y-2
              grid-cols-1
              sm:grid-cols-2
              xl:grid-cols-3
            ">
              {group.items.map(it => {
                const isChecked = Boolean(selected[it.id]?.checked);
                return (
                  <div key={it.id} className="min-w-0">
                    <label className="inline-flex items-start gap-2">
                      <input
                        type="checkbox"
                        className="mt-1"
                        checked={isChecked}
                        onChange={()=>toggle(it.id)}
                        aria-label={it.label}
                      />
                      <span>{it.label}</span>
                    </label>
                    {it.note && isChecked && (
                      <input
                        className="mt-1 ml-6 block w-full rounded-md border px-2 py-1"
                        placeholder="Specify"
                        value={selected[it.id]?.note ?? ""}
                        onChange={e=>setNote(it.id, e.target.value)}
                      />
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </fieldset>
      ))}

      {/* Macros */}
      <div className="flex flex-wrap gap-2">
        <button type="button" className="rounded-md border px-3 py-1 text-sm"
          onClick={()=>onChange({})}>
          None of the above
        </button>
        <button type="button" className="rounded-md border px-3 py-1 text-sm"
          onClick={()=>{/* set a flag in your form model if needed */}}>
          Reviewed and unchanged
        </button>
      </div>
    </section>
  );
}
```

### Density tweaks

* Reduce line height for list items: `leading-5` and `gap-y-2`.
* Use grid with `sm:grid-cols-2` and `xl:grid-cols-3` to reduce vertical scroll on large screens.
* Only render the note input when checked so there is no wasted space.
* Use a sticky Selected drawer so staff always see what is set while scrolling.

### Keyboard and a11y

* Up and down arrows move focus between checkboxes.
* Space toggles the focused checkbox.
* Announce changes with aria live if you want: “Diabetes selected. 3 items selected.”

---

## If you want ultra fast lists

You can swap the plain grid for a virtualized list like react-window. It is not required here, but if the list grows, virtualization keeps scrolling smooth.

---

## Quick wins you can apply today without refactor

* Tighten your current checkbox rows: `text-base`, `leading-5`, reduce top margin on the field label block.
* Split the list into two columns with `grid-cols-2` at `md:` breakpoints.
* Add a small search box above the list.
* Only show the five write in inputs when corresponding boxes are checked.
* Add a Selected chip row that pins to the top while scrolling.

If you want, I will produce a second variant that uses the vertical radio list look you liked for D1, but for checkboxes, with the same compact density.

>>>

Yes. Let’s add compact multi-select dropdowns with an “Other” text input for the write-in items. This keeps your exact ASAM wording, reduces vertical space, and speeds data entry.

Below is a ready-to-paste UI spec plus a reusable React component.

---

## Where to add multi-select dropdowns

Show the dropdown only when the checkbox is checked.

* Cancer (specify type(s))
* Sexually Transmitted Disease(s)
* Infection(s)
* Allergies
* Other

### Suggested option sets

You can tune these later without changing the form wording.

**Cancer (multi-select)**

* Breast
* Lung
* Colorectal
* Prostate
* Cervical
* Ovarian
* Endometrial
* Melanoma
* Non-melanoma skin
* Pancreatic
* Liver
* Kidney
* Bladder
* Thyroid
* Brain or CNS
* Leukemia
* Lymphoma
* Multiple myeloma
* Other… [opens text box]

**Sexually Transmitted Disease(s) (multi-select)**

* Chlamydia
* Gonorrhea
* Syphilis
* Genital herpes (HSV)
* Human papillomavirus (HPV)
* Trichomoniasis
* Mycoplasma genitalium
* Pelvic inflammatory disease
* Other… [opens text box]

**Infection(s) (multi-select)**

* Skin or soft tissue
* Respiratory
* Urinary tract
* Bloodstream
* Bone or joint
* Gastrointestinal
* Endocarditis
* Other… [opens text box]

**Allergies (multi-select, with reaction submenu optional)**

* Penicillin or beta-lactams
* Sulfonamides
* NSAIDs
* Opioids
* Anticonvulsants
* Radiographic contrast
* Latex
* Food: peanut
* Food: shellfish
* Environmental: pollen or dust
* Other… [opens text box]

Optional reaction tags (multi-select):

* Rash
* Hives
* Anaphylaxis
* Angioedema
* GI upset
* Unknown

**Other (multi-select)**

* Disability or mobility
* Wound care
* Medical device
* Other… [opens text box]

---

## Compact layout pattern

* Keep the checklist row.
* When a write-in row is checked, show a single-line control under it:

```
[✓] Cancer (specify type(s))
      Select types: [ ▾ Breast, Lung, … ]   [Other: __________]
```

* Chips for selected items appear inline and wrap to a second line if needed.
* Pressing Backspace in the empty input removes the last chip.

---

## Reusable React component (no extra libraries)

Drop this into your codebase. Tailwind classes are included, but you can swap to your tokens. This works for all five fields by passing different option arrays.

```jsx
import { useMemo, useRef, useState } from "react";

export function MultiSelectWithOther({
  label,                 // visible field label like "Select types"
  options,               // [{value:"breast", label:"Breast"}, ... , {value:"__OTHER__", label:"Other…"}]
  value,                 // { selected: string[], otherText?: string }
  onChange,
  placeholder = "Type to filter, press Enter to select",
  maxMenuHeight = 240,
}) {
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState("");
  const boxRef = useRef(null);

  const filtered = useMemo(() => {
    const f = q.trim().toLowerCase();
    if (!f) return options;
    return options.filter(o => o.label.toLowerCase().includes(f));
  }, [q, options]);

  const isOtherSelected = value?.selected?.includes("__OTHER__");
  const selectedSet = new Set(value?.selected ?? []);

  const toggle = (v) => {
    const sel = new Set(value?.selected ?? []);
    if (sel.has(v)) sel.delete(v); else sel.add(v);
    const next = { selected: Array.from(sel), otherText: value?.otherText ?? "" };
    // if Other was unselected, clear the text
    if (!next.selected.includes("__OTHER__")) next.otherText = "";
    onChange(next);
  };

  const addExactMatch = () => {
    const match = options.find(o => o.label.toLowerCase() === q.trim().toLowerCase());
    if (match) {
      toggle(match.value);
      setQ("");
    }
  };

  return (
    <div className="w-full">
      {label && <div className="mb-1 text-sm font-medium">{label}</div>}

      <div
        className="rounded-md border bg-black/20 backdrop-blur px-2 py-1"
        ref={boxRef}
      >
        {/* chips */}
        <div className="flex flex-wrap items-center gap-1">
          {(value?.selected ?? []).filter(v => v !== "__OTHER__").map(v => {
            const opt = options.find(o => o.value === v);
            return (
              <button
                key={v}
                type="button"
                onClick={() => toggle(v)}
                className="rounded-full bg-blue-600 text-white text-xs px-2 py-0.5"
                aria-label={`Remove ${opt?.label ?? v}`}
              >
                {(opt?.label ?? v)} ×
              </button>
            );
          })}

          {/* input to open menu and filter */}
          <input
            className="flex-1 min-w-[160px] bg-transparent py-1 px-1 outline-none text-sm"
            placeholder={placeholder}
            value={q}
            onFocus={() => setOpen(true)}
            onChange={(e)=>setQ(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") { e.preventDefault(); addExactMatch(); }
              if (e.key === "Escape") setOpen(false);
              if (e.key === "Backspace" && !q && (value?.selected?.length ?? 0) > 0) {
                // remove last
                const last = value.selected[value.selected.length - 1];
                toggle(last);
              }
            }}
            aria-expanded={open}
            aria-haspopup="listbox"
          />
        </div>

        {/* menu */}
        {open && (
          <div
            role="listbox"
            className="mt-1 max-h-[240px] overflow-auto rounded-md border bg-neutral-900 text-sm shadow-lg"
            style={{ maxHeight: maxMenuHeight }}
          >
            {filtered.map(o => (
              <div
                key={o.value}
                role="option"
                aria-selected={selectedSet.has(o.value)}
                className={`flex items-center gap-2 px-2 py-1 cursor-pointer hover:bg-neutral-800 ${selectedSet.has(o.value) ? "bg-neutral-800" : ""}`}
                onMouseDown={(e)=>e.preventDefault()}
                onClick={() => toggle(o.value)}
              >
                <input type="checkbox" readOnly checked={selectedSet.has(o.value)} />
                <span>{o.label}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Other text field appears only when Other is selected */}
      {isOtherSelected && (
        <div className="mt-2">
          <label className="text-sm">Other:</label>
          <input
            className="mt-1 block w-full rounded-md border px-2 py-1"
            value={value?.otherText ?? ""}
            onChange={(e)=>onChange({ selected: value?.selected ?? ["__OTHER__"], otherText: e.target.value })}
            placeholder="Specify"
          />
        </div>
      )}
    </div>
  );
}
```

### Example usage in Dimension 2 checklist

```jsx
// inside the Infectious group, for STDs
const STD_OPTIONS = [
  { value:"chlamydia", label:"Chlamydia" },
  { value:"gonorrhea", label:"Gonorrhea" },
  { value:"syphilis", label:"Syphilis" },
  { value:"hsv", label:"Genital herpes (HSV)" },
  { value:"hpv", label:"Human papillomavirus (HPV)" },
  { value:"trich", label:"Trichomoniasis" },
  { value:"mg", label:"Mycoplasma genitalium" },
  { value:"pid", label:"Pelvic inflammatory disease" },
  { value:"__OTHER__", label:"Other…" },
];

// state shape suggestion
// form.physical_health_issues.stds = { selected:[], otherText:"" }

{checked.stds && (
  <div className="mt-2 ml-6">
    <MultiSelectWithOther
      label="Select STI(s)"
      options={STD_OPTIONS}
      value={form.physical_health_issues.stds}
      onChange={(v)=>updateForm({ path:["physical_health_issues","stds"], value:v })}
    />
  </div>
)}
```

Repeat with different option arrays for Cancer, Infection(s), Allergies, and Other.

---

## Micro interactions

* When a dropdown opens, auto scroll it so the first checked item is visible.
* Keep a small counter on the parent checkbox label, for example “Allergies (3)”.
* In your “Selected” drawer, show the child selections as sub chips, for example “Allergies: Penicillin, Latex”.

---

## Data model

```ts
type WithOther = { selected: string[]; otherText?: string };

physical_health_issues: {
  cancer?: WithOther;
  stds?: WithOther;
  infections?: WithOther;
  allergies?: WithOther & { reactions?: string[] };
  other_conditions?: WithOther;
}
```

This model is stable, serializes cleanly, and works with analytics.

---

If you want, I can plug this component into your current D2 screen and return the exact JSX blocks for the five fields.
