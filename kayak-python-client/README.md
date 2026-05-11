# Kayak Python SDK

Python client for the Kayak scientific research platform REST API.

## Installation

```bash
pip install kayak
```

With optional dependencies:

```bash
pip install kayak[pandas]   # For DataFrame conversion
pip install kayak[numpy]    # For ndarray conversion
pip install kayak[all]      # All optional dependencies
```

## Quick Start

```python
from kayak import KayakClient

with KayakClient(base_url="http://localhost:8080") as client:
    client.login("admin@kayak.local", "Admin123")
    
    # List workbenches
    workbenches = client.workbenches.list()
    for wb in workbenches:
        print(f"{wb.id}: {wb.name}")
    
    # List experiments
    experiments = client.experiments.list(status="completed")
    
    # Download experiment data
    data = client.data.download(experiments[0].id)
    df = data.to_dataframe()
    data.save("/path/to/file.h5")
```

## Authentication

The SDK supports automatic token refresh:

```python
client = KayakClient(base_url="http://localhost:8080")
client.login("admin@kayak.local", "Admin123")

# Tokens are automatically refreshed 5 minutes before expiry
workbenches = client.workbenches.list()
```

### Session Persistence

```python
# Save session
client.auth.save_session("session.json")

# Restore session in a new client
client2 = KayakClient(base_url="http://localhost:8080")
client2.auth.load_session("session.json")
```

## Error Handling

```python
from kayak import AuthenticationError, NotFoundError, ServerError

try:
    client.workbenches.list()
except AuthenticationError:
    # Handle auth failure
    pass
except NotFoundError as e:
    # Handle missing resource
    print(e)
except ServerError as e:
    # Handle server errors
    print(f"Server error: {e.status_code}")
```

## Development

```bash
cd kayak-python-client
pip install -e ".[dev]"
pytest tests/
mypy kayak/
```

## License

MIT
