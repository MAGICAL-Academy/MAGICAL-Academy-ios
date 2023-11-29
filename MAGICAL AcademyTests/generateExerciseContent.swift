import XCTest

// Import your module or project target where ExerciseGenerator is defined
@testable import MAGICAL_Academy

class ExerciseGeneratorTests: XCTestCase {

    // Create a mock MagicalAcademyAPI for testing
    class MockMagicalAcademyAPI: MagicalAcademyAPI {
        override func generateExerciseContent(
            age: String,
            difficulty: String,
            scenario: String,
            character: String,
            completionHandler: @escaping (Result<ExerciseContentResponse, Error>) -> Void
        ) {
            // Simulate a successful API response for testing
            let content = ExerciseContentResponse(
                content: ExerciseContentResponse.Content(
                    exercise: "How many legs does a camel have?",
                    answer: "4"
                )
            )

            completionHandler(.success(content))
        }
    }

    var exerciseGenerator: ExerciseGenerator!

    override func setUp() {
        super.setUp()
        let mockAPI = MockMagicalAcademyAPI()
        exerciseGenerator = ExerciseGenerator(api: mockAPI)
    }

    override func tearDown() {
        exerciseGenerator = nil
        super.tearDown()
    }

    func testGenerateExerciseContent() {
        let expectation = XCTestExpectation(description: "Generate exercise content")

        exerciseGenerator.generateExerciseContent(
            age: "10",
            difficulty: "easy",
            scenario: "story",
            character: "wizard"
        ) { result in
            switch result {
            case .success(let content):
                // Assert that the content matches the expected structure
                XCTAssertEqual(content.content.exercise, "How many legs does a camel have?")
                XCTAssertEqual(content.content.answer, "4")
                expectation.fulfill()
            case .failure(let error):
                // Handle the failure or fail the test
                XCTFail("Failed to generate exercise content with error: \(error.localizedDescription)")
            }
        }

        wait(for: [expectation], timeout: 5.0) // Adjust the timeout as needed
    }
}
