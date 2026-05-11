"""Basic usage example for the Kayak Python SDK."""

from kayak import KayakClient


def main() -> None:
    # Use context manager for automatic cleanup
    with KayakClient(base_url="http://localhost:8080") as client:
        # Login
        success = client.login("admin@kayak.local", "Admin123")
        print(f"Login success: {success}")

        # List workbenches
        workbenches = client.workbenches.list()
        print(f"Workbenches: {len(workbenches)}")
        for wb in workbenches:
            print(f"  - {wb.id}: {wb.name}")

        # List experiments
        experiments = client.experiments.list()
        print(f"Experiments: {len(experiments)}")
        for exp in experiments:
            print(f"  - {exp.id}: {exp.name} ({exp.status})")

        # Get experiment details
        if experiments:
            exp = client.experiments.get(experiments[0].id)
            print(f"First experiment: {exp.name}")

        # Download data (if pandas is installed)
        # data = client.data.download(experiments[0].id)
        # df = data.to_dataframe()
        # print(df.head())

        # Logout is automatic on context exit


if __name__ == "__main__":
    main()
