# Pele and Mermaid compatibility

Use embedded mode to check this file offline. Expected: all valid diagrams
use Pele, including math, icons, configuration and nested subgraphs. The malformed diagram shows its source
and Pele's error without loading Mermaid, and the final diagram still renders. Repeat in light/dark mode
and with Native Mermaid selected to compare layouts.

## Chinese labels and custom styles (Pele)

```mermaid
flowchart LR
    A[开始] --> B{是否完成？}
    B -->|是| C[结束]
    B -->|否| A
    style A fill:#d4edda,stroke:#287a3d,color:#173f22
```

## Flat subgraph (Pele)

```mermaid
flowchart LR
    subgraph 服务
        A[请求] --> B[响应]
    end
```

## Nested subgraphs (Pele)

```mermaid
flowchart TD
    subgraph Outer
        subgraph Inner
            A[Start] --> B[Process]
        end
        B --> C[Finish]
    end
    C --> D[Outside]
```

## Explicit configuration (Pele, using its own theme)

```mermaid
%%{init: {"theme": "forest"}}%%
graph LR
    A[Configuration accepted] --> B[Pele theme]
```

## HTML label (Pele)

```mermaid
flowchart LR
    A["Line one<br/>Line two"] --> B[Done]
```

## Math and icons (Pele)

```mermaid
flowchart LR
    A["$$\frac{a}{b} + x^2$$"] --> B["fa:fa-car"]
    B --> C["fa:fa-unknown-icon"]
```

Unknown icons are omitted, as in the Playground.

## Image (Pele)

```mermaid
flowchart LR
    A@{ img: "https://pele.run/favicon.ico", label: "Pele" }
```

This remote image requires a connection, even when libraries are embedded.

## Malformed input (Pele error, no fallback)

```mermaid
flowchart LR
    A[Unclosed
```

## Rendering continues after an error (Pele)

```mermaid
sequenceDiagram
    Alice->>Bob: Still rendering
    Bob-->>Alice: Yes
```
