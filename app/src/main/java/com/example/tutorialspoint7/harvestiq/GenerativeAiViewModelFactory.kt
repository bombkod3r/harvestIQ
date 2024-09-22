package com.example.tutorialspoint7.harvestiq


import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.CreationExtras
import com.google.ai.client.generativeai.GenerativeModel
import com.google.ai.client.generativeai.type.generationConfig

val GenerativeViewModelFactory = object : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(
        modelClass: Class<T>, // Renamed parameter for clarity
        extras: CreationExtras
    ): T {
        val config = generationConfig {
            temperature = 0.7f
        }

        return with(modelClass) {
            when {
                isAssignableFrom(ImageInterpretationViewModel::class.java) -> {
                    val generativeModel = GenerativeModel(
                        modelName = "gemini-1.5-flash",
                        apiKey = "", // your actual API key
                        generationConfig = config
                    )
                    @Suppress("UNCHECKED_CAST") // Suppress unchecked cast warning
                    ImageInterpretationViewModel(generativeModel) as T
                }
                else -> throw IllegalArgumentException("Unknown ViewModel class: ${modelClass.name}")
            }
        }
    }
}
