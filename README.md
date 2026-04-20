# HelloVapor

💧 A project built with the Vapor web framework.

## Getting Started

To build the project using the Swift Package Manager, run the following command in the terminal from the root of the project:
```bash
swift build
```

To run the project and start the server, use the following command:
```bash
swift run
```

To execute tests, use the following command:
```bash
swift test
```

## Curl Request Testing

To test the create acronym endpoint with curl, first start the server:
```bash
swift run
```

Then run the helper script:
```bash
./scripts/test-create-acronym.sh OMG "Oh My God"
```

If your server is not running on the default host, override `BASE_URL`:
```bash
BASE_URL=http://127.0.0.1:8080 ./scripts/test-create-acronym.sh API "Application Programming Interface"
```

### See more

- [Vapor Website](https://vapor.codes)
- [Vapor Documentation](https://docs.vapor.codes)
- [Vapor GitHub](https://github.com/vapor)
- [Vapor Community](https://github.com/vapor-community)
