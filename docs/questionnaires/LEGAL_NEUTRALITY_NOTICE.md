# Legal Neutrality Notice

## Questionnaire Content IP-Safety

### Neutral Design Approach

The questionnaires in this kit are designed using **neutral clinical assessment principles** and do not contain ASAM-proprietary content. They follow general substance use assessment practices that are widely available in clinical literature.

### Content Sources

- Clinical assessment best practices from public health resources
- Neutral terminology derived from general addiction medicine principles  
- Generic question structures commonly used in healthcare assessments
- Public domain clinical evaluation frameworks

### ASAM Compliance Strategy

While these questionnaires are neutral, they can be mapped to ASAM criteria through:

1. **Configurable Scoring Rules**: The `severity_rules.json` file allows mapping neutral responses to ASAM severity levels
2. **Breadcrumb Mapping**: Question breadcrumbs can be mapped to licensed ASAM field references  
3. **Customizable Terminology**: All text can be updated to match licensed vocabulary
4. **Extensible Schema**: Additional fields can be added for licensed assessments

### Legal Safeguards

#### ✅ What This Kit Provides (Safe to Use)

- Generic clinical assessment questions
- Neutral severity scoring framework
- Open-source question renderer
- Extensible data models

#### ⚠️ What You Must Add (License Required)

- ASAM-specific terminology and language
- Official ASAM domain definitions
- Proprietary ASAM scoring algorithms
- Licensed assessment protocols

### Implementation Recommendations

1. **Use as Foundation**: Start with neutral questionnaires for development and testing
2. **License ASAM Content**: Obtain proper licensing for production deployment  
3. **Map Systematically**: Use breadcrumbs to map neutral questions to licensed content
4. **Validate Compliance**: Ensure final implementation meets ASAM licensing requirements

### Development vs. Production

| Environment | Content Type | Legal Status |
|-------------|--------------|--------------|
| Development | Neutral questionnaires | ✅ Safe to use |
| Testing | Neutral + mock data | ✅ Safe to use |  
| Production | Licensed ASAM content | ⚠️ Requires license |

### Disclaimer

This questionnaire kit provides a neutral foundation for clinical assessments and is not intended to replace licensed ASAM materials. Organizations using this kit are responsible for:

- Obtaining appropriate ASAM licensing for production use
- Ensuring content compliance with local regulations
- Validating clinical appropriateness of assessment questions
- Meeting professional standards for substance use evaluation

### Next Steps for Compliance

1. **T-0051**: Implement CI token guard for ASAM compliance  
2. **T-0053**: Add legal screens and PDF footer fields
3. **T-0055**: Create licensed mode toggle and validation checks

For questions about ASAM licensing, contact [ASAM](https://www.asam.org) directly.