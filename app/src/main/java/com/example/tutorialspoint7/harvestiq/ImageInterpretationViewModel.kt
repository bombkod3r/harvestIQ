package com.example.tutorialspoint7.harvestiq

import android.graphics.Bitmap
import android.net.Uri
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.ai.client.generativeai.GenerativeModel
import com.google.ai.client.generativeai.type.content
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ImageInterpretationViewModel(
    private val generativeModel: GenerativeModel
) : ViewModel() {

    private val _uiState =
        MutableStateFlow<ImageInterpretationUiState>(ImageInterpretationUiState.Initial)
    val uiState: StateFlow<ImageInterpretationUiState> = _uiState.asStateFlow()

    fun reason(userInput: String, selectedImages: List<Bitmap>) {
        _uiState.value = ImageInterpretationUiState.Loading
        val prompt = "Analyze the following image(s) and answer this question: $userInput"

        viewModelScope.launch(Dispatchers.IO) {
            try {
                val inputContent = content {
                    selectedImages.forEach { bitmap -> image(bitmap) }
                    text(prompt)
                }

                var outputContent = ""
                var bestCounty = ""
                var mapsLink = ""

                generativeModel.generateContentStream(inputContent).collect { response ->
                    response.text?.let { text ->
                        outputContent += text

                        // Log the full response text for debugging
                        Log.d("ImageInterpretation", "Response Text: $text")

                        // Extract bestCounty and coordinates (latitude, longitude) from the text
                        val countyRegex = Regex("Best county for selling: (.+)")
                        val coordinatesRegex = Regex("Coordinates: (\\d+\\.\\d+),(\\d+\\.\\d+)")

                        countyRegex.find(text)?.groups?.get(1)?.let { bestCounty = it.value }
                        coordinatesRegex.find(text)?.let { match ->
                            val latitude = match.groups[1]?.value
                            val longitude = match.groups[2]?.value
                            if (latitude != null && longitude != null) {
                                mapsLink =
                                    "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude"
                            }
                        }
                    }
                }

                _uiState.value =
                    ImageInterpretationUiState.Success(outputContent, bestCounty, mapsLink)

            } catch (e: Exception) {
                _uiState.value = ImageInterpretationUiState.Error(
                    e.localizedMessage ?: "An unknown error occurred"
                )
            }
        }
    }
}