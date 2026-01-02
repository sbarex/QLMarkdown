# Mermaid Diagram Test

This file tests Mermaid diagram rendering in Quick Look.

## Flowchart

```mermaid
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Do Something]
    B -->|No| D[Do Something Else]
    C --> E[End]
    D --> E
```

## Sequence Diagram

```mermaid
sequenceDiagram
    Alice->>Bob: Hello Bob, how are you?
    Bob-->>Alice: I'm good thanks!
    Alice->>Bob: Great to hear!
```

## Pie Chart

```mermaid
pie title Pets Adopted
    "Dogs" : 45
    "Cats" : 35
    "Birds" : 15
    "Other" : 5
```

## Regular Markdown Content

This is regular markdown content that should render normally:

- Item 1
- Item 2
- Item 3

### Code Block (non-Mermaid)

```javascript
function hello() {
    console.log("Hello World");
}
```

## State Diagram

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Processing : Start
    Processing --> Complete : Success
    Processing --> Error : Failure
    Complete --> [*]
    Error --> Idle : Retry
```
