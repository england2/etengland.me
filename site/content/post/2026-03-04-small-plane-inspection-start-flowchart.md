+++
title = "Small Plane Preflight and Start Flowchart"
date = 2026-03-04
categories = ["aviation", "diagram"]
tags = ["mermaid", "flowchart", "checklist"]
+++

This page tests Mermaid rendering with an inspect/start decision flow.

```mermaid
flowchart TD
    A[1. Arrive at aircraft and review maintenance log] --> B{2. Any open discrepancies?}
    B -- Yes --> Z1[Stop: do not fly; contact maintenance]
    B -- No --> C[3. Exterior walkaround and control surface check]
    C --> D{4. Fuel quantity and quality acceptable?}
    D -- No --> Z2[Refuel or drain sample; re-check]
    D -- Yes --> E[5. Oil level and leaks check]
    E --> F{6. Oil within limits?}
    F -- No --> Z3[Add oil or call maintenance]
    F -- Yes --> G[7. Cabin setup: documents, belts, brakes, avionics off]
    G --> H[8. Clear prop area and announce prop start]
    H --> I{9. Engine starts and oil pressure rises in 30s?}
    I -- No --> Z4[Shutdown and troubleshoot]
    I -- Yes --> J[10. Avionics on, radios set, taxi checklist complete]
    J --> K[Ready for run-up]
```
