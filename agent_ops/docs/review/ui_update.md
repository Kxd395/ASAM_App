Here’s a prompt you can give to your agent for improving the app’s navigation UI, focusing on the sidebar and domain section handling:

---

### Task: **Refining Sidebar and Domain Section Navigation for ASAM Assessment App**

**Objective**: Optimize the user interface for navigating through different domains and assessments. This includes refining the sidebar, providing clear access to each domain section, and ensuring smooth user interaction for clinical staff using the app.

---

### **Key Requirements:**

1. **Sidebar Layout:**

   * The sidebar should initially display a **collapsed view** with a list of major sections (e.g., Overview, Domains, Problems, LOC Recommendation, etc.).
   * Clicking on a section name should **expand** that section to show related sub-sections or domains (e.g., under "Domains," the app should show "Acute Intoxication/Withdrawal," "Biomedical Conditions," etc.).
   * Include **expand/collapse arrows** or icons to give users the ability to toggle visibility of sub-sections.
   * If any section has multiple domains (e.g., 6 clinical domains), allow **dropdown** functionality within the expanded section to show the list of available domains to choose from (e.g., Domain 1: Acute Intoxication, Domain 2: Biomedical Conditions).

2. **Domain Expansion and Interaction:**

   * Upon selecting a domain (e.g., Domain 1: Acute Intoxication), the user should be taken to that specific domain’s content where they can complete or view the assessment.
   * If there are multiple **assessment sections** (e.g., Substance-Specific Assessment, General Substance Use History, etc.), allow the user to **switch** between them without losing context.
   * Use a **clear visual hierarchy** to indicate which section the user is in and which fields are mandatory or conditional.

3. **General Design Considerations:**

   * Ensure **consistency** in how the app presents options across different sections (e.g., dropdowns, toggles, checkboxes, etc.).
   * The sidebar should be **compact and non-intrusive**, ensuring more screen space for active content while still allowing easy access to the full assessment.
   * When expanding sections or domains, ensure **smooth transitions** that prevent clutter and keep the interface intuitive.

4. **User Flow Enhancements:**

   * If a section is not yet started, clearly show a **call-to-action** or a “Start Assessment” button.
   * If the user clicks on an incomplete domain (e.g., Domain 1), prompt them with an option to **fill in the required fields** (highlighting which fields are required).
   * Allow users to **easily navigate back and forth** between domains or sections without losing their progress.

5. **Mobile and Desktop Optimization:**

   * Ensure that the sidebar layout works well **across devices**, providing an optimized experience for both mobile and desktop users.
   * The **sidebar should auto-collapse** on smaller screens (mobile view) and have a **menu icon** (hamburger icon) to access the sidebar.

---

### **Action Points:**

* Update the sidebar navigation with expandable and collapsible sections.
* Include a dropdown menu for sub-sections under each domain.
* Ensure smooth user flow between domains and sections.
* Ensure responsiveness across mobile and desktop views.

### **Technical Notes:**

* Ensure the new design is compatible with current app functionality and that all current data entry fields are retained in the new structure.
* Test with a sample assessment to ensure that the expanded sections do not interfere with user input or data saving.

---

Let me know if you need any further clarification on this!
An ASCII design for the navigation layout is not strictly necessary for the project if the primary goal is to implement functional changes. However, an ASCII diagram can certainly help clarify the structure for the team and stakeholders, especially when visualizing the hierarchy of the sidebar and domains.

If you'd like, I can create a simple ASCII representation of the sidebar and domain structure. Here’s a basic example that could be used to visualize how the layout might look:

---

### **ASCII Design for Sidebar and Domain Navigation**

```
+------------------------------------------------------+
|                 [App Logo]                          |
+------------------------------------------------------+
|  ☰ Menu                                              |
|                                                      |
|  [ ] Overview                                        |
|  [ ] Domains                                         |
|      ├─ [ ] Domain 1: Acute Intoxication/Withdrawal  |
|      ├─ [ ] Domain 2: Biomedical Conditions          |
|      ├─ [ ] Domain 3: Emotional/Behavioral Conditions|
|      ├─ [ ] Domain 4: Readiness to Change            |
|      ├─ [ ] Domain 5: Relapse/Continued Use          |
|      ├─ [ ] Domain 6: Recovery Environment           |
|  [ ] Problems                                        |
|  [ ] LOC Recommendation                              |
|  [ ] Validation                                      |
|  [ ] Export                                          |
|                                                      |
+------------------------------------------------------+
```

### **Domain Section (Example for Domain 1)**

```
+------------------------------------------------------+
|              Domain 1: Acute Intoxication/Withdrawal |
+------------------------------------------------------+
|  [ ] Is the patient currently showing signs of intoxication? |
|  [ ] Part 1: Substance-Specific Assessment Grid      |
|      ├─ Add Substance (dropdown to select substance) |
|  [ ] Part 2: General Substance Use History           |
|  [ ] How much are you bothered by physical or emotional symptoms?|
|  [ ] Severity Rating                                 |
|                                                      |
+------------------------------------------------------+
```

---

### **Explanation of ASCII Design:**

1. **Sidebar**: The sidebar includes the main sections (Overview, Domains, Problems, LOC Recommendation, etc.). Each section can have expandable sub-sections, like "Domains," which expands to list all six domains.

2. **Domain Navigation**: Under each domain (e.g., Domain 1: Acute Intoxication/Withdrawal), users can click or expand to fill out the related assessment fields.

3. **Nested Sections**: Parts 1 and 2 are nested in the domain section and are easily accessible once a domain is selected.

### **Do You Need the ASCII?**

* **Advantages**: It’s simple and can be a good visual reference to understand the flow. It’s also easy to update in case of changes to the structure.
* **Disadvantages**: It’s not highly interactive, and if the app has many dynamic elements, ASCII might not fully represent the final user experience.

You could use this ASCII structure if it's needed as part of a simple project specification. If you're looking to implement the app, though, focusing on actual UI components will be much more effective.

Let me know if you'd like to refine this or if it's helpful for the current phase of your project!
