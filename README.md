//
//  AllowanceIQ Testing Setup Guide.md
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 11/24/25.
//

# AllowanceIQ Testing Setup Guide

## Overview
This guide will help you set up and run unit tests and UI tests for the AllowanceIQ app.

## Test Structure

### Unit Tests (AllowanceIQTests)
- **DataManagerTests.swift** - Tests for data persistence and business logic
- **ChildTests.swift** - Tests for Child model and calculations
- **TransactionTests.swift** - Tests for Transaction model
- **UtilitiesTests.swift** - Tests for utility functions

### UI Tests (AllowanceIQUITests)
- **AllowanceIQUITests.swift** - End-to-end user interface tests

## Setup Instructions

### 1. Create Test Targets

If you don't already have test targets:

1. In Xcode, go to **File > New > Target**
2. Select **Unit Testing Bundle** and click **Next**
3. Name it `AllowanceIQTests`
4. Repeat for **UI Testing Bundle** named `AllowanceIQUITests`

### 2. Add Test Files

1. Right-click on the `AllowanceIQTests` group
2. Select **New File > Swift File**
3. Add each unit test file (DataManagerTests, ChildTests, etc.)
4. Repeat for UI test files in `AllowanceIQUITests`

### 3. Configure Test Targets

In your test target settings:
- Ensure **Host Application** is set to AllowanceIQ
- Add `@testable import AllowanceIQ` to unit test files

### 4. Add UI Testing Launch Argument

In your main app file (AllowanceIQApp.swift):

```swift
@main
struct AllowanceIQApp: App {
    @StateObject private var dataManager = DataManager()
    
    init() {
        // Clear data for UI testing
        if ProcessInfo.processInfo.arguments.contains("UI-Testing") {
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
```

## Running Tests

### Running All Tests
- Press `Cmd + U` to run all tests

### Running Specific Test Suite
1. Click the test navigator (diamond icon) in the left sidebar
2. Click the play button next to the test suite name

### Running Individual Tests
1. Open the test file
2. Click the diamond icon in the gutter next to the test method

### Running Tests from Command Line
```bash
# Run all tests
xcodebuild test -scheme AllowanceIQ -destination 'platform=iOS Simulator,name=iPhone 15'

# Run only unit tests
xcodebuild test -scheme AllowanceIQ -only-testing:AllowanceIQTests

# Run only UI tests
xcodebuild test -scheme AllowanceIQ -only-testing:AllowanceIQUITests
```

## Test Coverage

### What's Covered

#### DataManager Tests
- ✅ Adding children
- ✅ Deleting children
- ✅ Adding deposit transactions
- ✅ Adding withdrawal transactions
- ✅ Tithing calculations
- ✅ Paying tithing
- ✅ Data persistence (save/load)
- ✅ Sorting children by age
- ✅ Edge cases (negative balance, zero tithing, etc.)

#### Child Model Tests
- ✅ Age calculation
- ✅ Net balance calculation
- ✅ JSON encoding/decoding
- ✅ Tithing balance handling

#### Transaction Tests
- ✅ Transaction types
- ✅ JSON encoding/decoding
- ✅ Transaction arrays

#### Utility Tests
- ✅ Currency formatting
- ✅ Date formatting
- ✅ Edge cases (negative numbers, large amounts, etc.)

#### UI Tests
- ✅ App launch
- ✅ Empty state
- ✅ Adding children
- ✅ Form validation
- ✅ Navigation flows
- ✅ Adding transactions
- ✅ Tithing functionality
- ✅ Deleting children
- ✅ Alert dialogs

## Continuous Integration

### GitHub Actions Example

Create `.github/workflows/tests.yml`:

```yaml
name: Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.0.app
    
    - name: Run tests
      run: |
        xcodebuild test \
          -scheme AllowanceIQ \
          -destination 'platform=iOS Simulator,name=iPhone 15' \
          -enableCodeCoverage YES
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
```

## Troubleshooting

### Common Issues

#### "No such module 'AllowanceIQ'"
- Make sure test target has the main app as a dependency
- Add `@testable import AllowanceIQ` at the top of test files

#### UI Tests Can't Find Elements
- Check accessibility identifiers
- Use `print(app.debugDescription)` to see available elements
- Add delays with `sleep()` or `waitForExistence(timeout:)`

#### Tests Failing Due to Existing Data
- Make sure UI testing launch argument clears UserDefaults
- Add tearDown methods to clean up after tests

#### Simulator Issues
- Reset simulator: Device > Erase All Content and Settings
- Clean build folder: Cmd + Shift + K

## Best Practices

### Unit Tests
- Test one thing per test method
- Use descriptive test names: `test[MethodName][Scenario][ExpectedResult]`
- Follow Arrange-Act-Assert pattern
- Keep tests independent (no shared state)
- Clean up in `tearDown()`

### UI Tests
- Use accessibility identifiers for reliable element selection
- Add helper methods for common flows
- Use `XCTContext.runActivity` to group related actions
- Handle asynchronous operations with `waitForExistence`
- Keep tests focused and independent

### Code Coverage
- Aim for 80%+ coverage on business logic
- Don't worry about 100% coverage on UI code
- Review coverage reports regularly
- Add tests for uncovered critical paths

## Viewing Test Results

### In Xcode
1. Open **Test Navigator** (Cmd + 6)
2. View passed/failed tests
3. Click failed test to see error details
4. View code coverage: **Report Navigator** (Cmd + 9) > Coverage tab

### Code Coverage Report
1. Enable code coverage in scheme settings
2. After running tests, go to Report Navigator
3. Click on the test report
4. Select **Coverage** tab
5. See line-by-line coverage for each file

## Additional Resources

- [Apple's Testing Documentation](https://developer.apple.com/documentation/xctest)
- [WWDC Testing Videos](https://developer.apple.com/videos/testing)
- [XCTest Expectations](https://developer.apple.com/documentation/xctest/asynchronous_tests_and_expectations)
