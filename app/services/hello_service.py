class HelloService:
    """Business logic for greeting messages.

    This service can be expanded to include different greeting strategies,
    localization, or even dynamic content fetched from repositories.
    """

    def __init__(self) -> None:
        pass

    def say_hello(self) -> str:
        return "Hello, world"
