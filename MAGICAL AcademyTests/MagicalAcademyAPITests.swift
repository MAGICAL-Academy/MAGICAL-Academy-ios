import XCTest

@testable import MAGICAL_Academy

class MagicalAcademyAPITests: XCTestCase {

    override func setUpWithError() throws {
        // Perform setup here.
    }

    override func tearDownWithError() throws {
        // Perform teardown here.
    }

    // Test the generateExerciseContent function of MagicalAcademyAPI.
    func testGenerateExerciseContent() {
        // Arrange
        let api = MagicalAcademyAPI()

        let age = "5"
        let difficulty = "1"
        let scenario = "sky"
        let character = "camel"

        let expectation = XCTestExpectation(description: "Generate exercise content")

        // Act
        api.generateExerciseContent(age: age, difficulty: difficulty, scenario: scenario, character: character) { result in
            switch result {
            case .success(let content):
                print("Actual API Response:")
                           print(content)
                // Assert
                XCTAssertNotNil(content.content.exercise, "Generated exercise should not be nil")
                XCTAssertNotNil(content.content.answer, "Generated answer should not be nil")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Error generating exercise content: \(error)")
            }
        }

        // Wait for the asynchronous call to complete.
        wait(for: [expectation], timeout: 10.0)
    }

    // Add more test cases as needed.

}
