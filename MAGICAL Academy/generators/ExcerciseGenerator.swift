import Foundation

class ExerciseGenerator {
    private var api: MagicalAcademyAPI

    /**
     Initializes the ExerciseGenerator with the MagicalAcademyAPI instance.

     - Parameters:
        - api: The MagicalAcademyAPI instance to use for generating exercise content.
     */
    init(api: MagicalAcademyAPI) {
        self.api = api
    }

    /**
     Generates exercise content using the specified parameters.

     - Parameters:
        - age: The age for exercise content generation.
        - difficulty: The difficulty level for exercise content generation.
        - scenario: The scenario for exercise content generation.
        - character: The character for exercise content generation.
        - completionHandler: A completion handler with the generated exercise content.
     */
    func generateExerciseContent(
        age: String,
        difficulty: String,
        scenario: String,
        character: String,
        completionHandler: @escaping (Result<ExerciseContentResponse, Error>) -> Void
    ) {
        api.generateExerciseContent(
            age: age,
            difficulty: difficulty,
            scenario: scenario,
            character: character
        ) { result in
            switch result {
            case .success(let content):
                // Assuming the API response is of type ExerciseContentResponse
                completionHandler(.success(content))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}
