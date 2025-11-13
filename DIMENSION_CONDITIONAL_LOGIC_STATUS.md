# Dimension Conditional Logic Status

## ✅ Dimension 2 - Biomedical Conditions
**Status: COMPLETE** - Already has smart conditional logic throughout

### Implemented Conditionals:
- ✅ Primary care provider = "Yes" → Shows provider name/contact
- ✅ Marijuana = "Yes" → Shows type/frequency/purpose  
- ✅ Contraception = "Yes" → Shows contraception type
- ✅ Medical concerns = "Yes" → Shows "Please describe"
- ✅ Infectious to others = "Yes" → Shows "Please describe"
- ✅ Pregnant = "Yes" → Shows trimester/pregnancy care questions
- ✅ All "Please describe" fields only show when relevant

**User Experience:** Clean, minimal - only see questions you need to answer

---

## ✅ Dimension 3 - Emotional/Behavioral/Cognitive
**Status: COMPLETE** - Just updated with smart conditional logic

### Implemented Conditionals:
- ✅ Disorientation = "Yes" → Shows "Please describe"
- ✅ MH diagnosis = "Yes" → Shows diagnosis details + symptom stability
- ✅ Treatment history = "Yes" → Shows treatment details
- ✅ MH provider = "Yes" → Shows provider name/contact
- ✅ Marijuana for psych = "Yes" → Shows type/frequency/purpose
- ✅ Suicidal ideation = "Yes" → Shows describe/today/acted on
- ✅ Homicidal ideation = "Yes" → Shows describe/today/acted on
- ✅ Further assessment = "Yes" → Shows "Please describe"

**Safety Impact:** SI/HI questions don't overwhelm users unless they answer "Yes"

---

## ⚠️ Dimension 1 - Withdrawal Potential
**Status: PLACEHOLDER** - Needs full implementation

### Current State:
- Simple placeholder questionnaire
- No real ASAM D1 questions yet
- No conditional logic (not needed for placeholder)

### TODO:
- Replace with actual ASAM D1 questions
- Add conditional logic as needed

---

## Summary

| Domain | Conditional Logic | User-Friendly | Notes |
|--------|------------------|---------------|-------|
| **D1** | ❌ Placeholder | N/A | Needs full implementation |
| **D2** | ✅ Complete | ✅ Excellent | Already optimized |
| **D3** | ✅ Complete | ✅ Excellent | Just updated |
| **D4** | ❓ Unknown | ❓ Unknown | Not yet reviewed |
| **D5** | ❓ Unknown | ❓ Unknown | Not yet reviewed |
| **D6** | ❓ Unknown | ❓ Unknown | Not yet reviewed |

---

## Benefits of Conditional Logic

### For Users:
- **Shorter forms** - Only see relevant questions
- **Less overwhelming** - Complex sections hidden until needed
- **Faster completion** - Skip entire branches by answering "No"
- **Clearer flow** - Progressive disclosure of related questions

### For Data Quality:
- **Reduced errors** - Can't answer follow-ups for N/A items
- **Better validation** - Follow-up questions require parent answer
- **Consistent data** - No orphaned answers

### Technical Implementation:
```json
{
  "id": "follow_up_question",
  "text": "Please describe:",
  "type": "textarea",
  "visible_if": {
    "question": "parent_question_id",
    "operator": "equals",
    "value": "yes"
  }
}
```

---

## Recommendations

1. **D1**: Implement full ASAM questions first, then add conditionals
2. **D4-D6**: Review and add conditional logic similar to D2/D3
3. **Testing**: Verify conditional logic works on iPad across all domains
4. **Documentation**: Update user guide with progressive disclosure notes

---

*Last Updated: November 12, 2025*
