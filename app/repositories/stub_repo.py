class StubRepository:
    """A stub repository to demonstrate the repository pattern.

    Replace with a real implementation (e.g., DynamoDBRepository, RDSRepository)
    when adding a database layer.
    """

    def get_value(self) -> str:
        return "stubbed-value"
