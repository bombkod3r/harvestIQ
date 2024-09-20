package com.example.tutorialspoint7.harvestiq

import android.graphics.Bitmap
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

    private val _uiState = MutableStateFlow<ImageInterpretationUiState>(ImageInterpretationUiState.Initial)
    val uiState: StateFlow<ImageInterpretationUiState> = _uiState.asStateFlow()

    fun reason(userInput: String, selectedImages: List<Bitmap>) {
        _uiState.value = ImageInterpretationUiState.Loading
        val prompt = "Analyze the following image(s) and answer this question: $userInput"

        viewModelScope.launch(Dispatchers.IO) {
            try {
                val inputContent = content {
                    selectedImages.forEach { bitmap ->
                        image(bitmap)
                    }
                    text(prompt)
                }

                var outputContent = ""

                generativeModel.generateContentStream(inputContent).collect { response ->
                    response.text?.let { text ->
                        outputContent += text
                        _uiState.value = ImageInterpretationUiState.Success(outputContent)
                    }
                }
            } catch (e: Exception) {
                _uiState.value = ImageInterpretationUiState.Error(e.localizedMessage ?: "An unknown error occurred")
            }
        }
    }
}


