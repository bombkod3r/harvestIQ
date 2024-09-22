package com.example.tutorialspoint7.harvestiq


/**
 * A sealed class describing the state of the image interpretation process.
 */
sealed class ImageInterpretationUiState {
    object Initial : ImageInterpretationUiState()
    object Loading : ImageInterpretationUiState()
    data class Success(val outputText: String, val bestCounty: String, val mapsLink: String) :
        ImageInterpretationUiState()

    data class Error(val errorMessage: String) : ImageInterpretationUiState()
}

