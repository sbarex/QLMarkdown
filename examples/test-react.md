# React Component Preview Test

This markdown file contains inline React components rendered via QuickLook.

## Simple Component

```react
const Hello = () => {
    return (
        <div style={{
            padding: '20px',
            borderRadius: '12px',
            backgroundColor: '#f0f9ff',
            border: '1px solid #bae6fd',
            fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
            textAlign: 'center'
        }}>
            <h2 style={{ color: '#0284c7', margin: '0 0 8px 0' }}>Hello from React!</h2>
            <p style={{ color: '#64748b', margin: 0 }}>This component is rendered inside QuickLook.</p>
        </div>
    );
};

export default Hello;
```

## Status Cards

```react
const StatusCards = () => {
    const cards = [
        { label: 'Build', status: 'passing', color: '#22c55e' },
        { label: 'Tests', status: '142 passed', color: '#3b82f6' },
        { label: 'Coverage', status: '87%', color: '#f59e0b' },
    ];

    return (
        <div style={{ display: 'flex', gap: '8px', fontFamily: '-apple-system, sans-serif' }}>
            {cards.map((c, i) => (
                <div key={i} style={{
                    padding: '12px 20px',
                    borderRadius: '8px',
                    backgroundColor: c.color + '15',
                    border: `1px solid ${c.color}40`,
                    flex: 1,
                    textAlign: 'center'
                }}>
                    <div style={{ fontSize: '11px', opacity: 0.6, marginBottom: '4px' }}>{c.label}</div>
                    <div style={{ fontSize: '14px', fontWeight: '600', color: c.color }}>{c.status}</div>
                </div>
            ))}
        </div>
    );
};

export default StatusCards;
```

## Regular Markdown Still Works

- **Bold text** and *italic text*
- [Links work too](https://example.com)
- `inline code` renders normally

| Column A | Column B |
|----------|----------|
| Data 1   | Data 2   |
