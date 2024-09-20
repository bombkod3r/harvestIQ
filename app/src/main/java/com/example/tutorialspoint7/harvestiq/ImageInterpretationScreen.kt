package com.example.tutorialspoint7.harvestiq


import android.graphics.drawable.BitmapDrawable
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.ImageLoader
import coil.compose.AsyncImage
import coil.request.ImageRequest
import coil.request.SuccessResult
import coil.size.Precision
import androidx.compose.runtime.saveable.rememberSaveable
import kotlinx.coroutines.launch



@Composable
internal fun ImageInterpretationRoute(
    viewModel: ImageInterpretationViewModel = viewModel(factory = GenerativeViewModelFactory) // Ensure this factory is correct
) {
    val imageInterpretationUiState by viewModel.uiState.collectAsState()

    val coroutineScope = rememberCoroutineScope()
    val imageRequestBuilder = ImageRequest.Builder(LocalContext.current)
    val imageLoader = ImageLoader.Builder(LocalContext.current).build()

    ImageInterpretationScreen(
        uiState = imageInterpretationUiState,
        onReasonClicked = { inputText, selectedItems ->
            coroutineScope.launch {
                val bitmaps = selectedItems.mapNotNull {
                    val imageRequest = imageRequestBuilder
                        .data(it)
                        // Scale the image down to 768px for faster uploads
                        .size(size = 768)
                        .precision(Precision.EXACT)
                        .build()
                    try {
                        val result = imageLoader.execute(imageRequest)
                        if (result is SuccessResult) {
                            return@mapNotNull (result.drawable as BitmapDrawable).bitmap
                        } else {
                            return@mapNotNull null
                        }
                    } catch (e: Exception) {
                        return@mapNotNull null
                    }
                }
                viewModel.reason(inputText, bitmaps)
            }
        }
    )
}

@Composable
fun ImageInterpretationScreen(
    uiState: ImageInterpretationUiState = ImageInterpretationUiState.Loading,
    onReasonClicked: (String, List<Uri>) -> Unit = { _, _ -> }
) {
    val userQuestion = """
    Identify the vegetable/fruit and analyze its current shelf life, ripening period, and ideal market timing post-ripening. Detail the prime harvest season and offer both the present and expected market rates in KES within the Kenyan market after sale. Further, determine the optimal Kenyan county for selling this produce, providing both the county's name and its geographical coordinates for map plotting purposes.

    The output should be presented in the following format separately for each detected fruit/vegetable:

    ## {Fruit/Vegetable Name}

● **Current maturity stage:** {stage}
● **Remaining shelf life:** {time}
● **Optimal harvest window:** {window}
● **Best post-harvest handling practices:** {practices}
● **Ideal storage conditions:** {conditions}
● **Present market rate (KES):** {current_rate}
● **Expected market rate (KES):** {expected_rate}
● **Best county for selling:** {best_county}
● **Value-added processing options:** {options}
● **Immediate vs. delayed selling strategy:** {strategy}
● **Quality grading criteria:** {criteria}
● **Common post-harvest diseases:** {diseases}
● **Transportation recommendations:** {recommendations}
● **Local vs. export market potential:** {potential}
● **Certifications or standards:** {certifications}
● **Nutritional peak:** {peak}
● **Ethylene sensitivity/production:** {ethylene}
● **Sustainable packaging options:** {packaging}
""".trimIndent()

    val imageUris = rememberSaveable(saver = UriSaver()) { mutableStateListOf<Uri>() }

    val pickMedia = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { imageUri ->
        imageUri?.let {
            imageUris.add(it)
        }
    }

    Column(
        modifier = Modifier
            .padding(all = 16.dp)
            .verticalScroll(rememberScrollState())
    ) {
        Button(
            onClick = {
                pickMedia.launch(
                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                )
            },
            modifier = Modifier
                .padding(all = 4.dp)
                .align(Alignment.CenterHorizontally),
            colors = ButtonDefaults.buttonColors(
                containerColor = Color(0xFF005D4A),
                contentColor = Color(0xFFFFFFFF)
            )
        ) {
            Text("Upload Image")
        }

        LazyRow(
            modifier = Modifier.padding(all = 8.dp)
        ) {
            items(imageUris) { imageUri ->
                AsyncImage(
                    model = imageUri,
                    contentDescription = null,
                    modifier = Modifier
                        .padding(4.dp)
                        .requiredSize(300.dp) // Image size: 300x300.
                )
            }
        }

        Button(
            onClick = {
                if (userQuestion.isNotBlank()) {
                    onReasonClicked(userQuestion, imageUris.toList())
                }
            },
            modifier = Modifier
                .padding(all = 4.dp)
                .align(Alignment.CenterHorizontally),
            colors = ButtonDefaults.buttonColors(
                containerColor = Color(0xFF005D4A),
                contentColor = Color(0xFFFFFFFF)
            )
        ) {
            Text("Submit")
        }

        when (uiState) {
            ImageInterpretationUiState.Initial -> {
                // Nothing is shown
            }
            ImageInterpretationUiState.Loading -> {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .padding(all = 8.dp)
                        .align(Alignment.CenterHorizontally)
                ) {
                    CircularProgressIndicator(color = Color(0XFF02D2A8))
                }
            }
            is ImageInterpretationUiState.Success -> {
                Card(
                    modifier = Modifier
                        .padding(vertical = 16.dp)
                        .fillMaxWidth(),
                    shape = MaterialTheme.shapes.large,
                    colors = CardDefaults.cardColors(
                        containerColor = Color(0XFF02D2A8)
                    )
                ) {
                    Row(
                        modifier = Modifier
                            .padding(all = 16.dp)
                            .fillMaxWidth()
                    ) {
                        Text(
                            text = uiState.outputText,
                            color = Color(0xFFF9FFFF),
                            modifier = Modifier
                                .padding(start = 16.dp)
                                .fillMaxWidth()
                        )
                    }
                }
            }
            is ImageInterpretationUiState.Error -> {
                Card(
                    modifier = Modifier
                        .padding(vertical = 16.dp)
                        .fillMaxWidth(),
                    shape = MaterialTheme.shapes.large,
                    colors = CardDefaults.cardColors(
                        containerColor = Color(0XFFFFE28C)
                    )
                ) {
                    Text(
                        text = uiState.errorMessage,
                        color = Color(0XFFFF3D00),
                        modifier = Modifier.padding(all = 16.dp)
                    )
                }
            }
        }
    }
}

@Composable
@Preview(showSystemUi = true)
fun ImageInterpretationScreenPreview() {
    ImageInterpretationScreen()
}