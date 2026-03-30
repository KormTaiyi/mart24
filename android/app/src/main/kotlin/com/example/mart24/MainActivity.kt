package com.example.mart24

import android.app.Activity
import android.content.IntentSender.SendIntentException
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import com.google.android.gms.auth.api.identity.GetPhoneNumberHintIntentRequest
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.common.api.ApiException
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pendingPhoneHintResult: MethodChannel.Result? = null

    private val phoneHintLauncher =
        registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { result ->
            val methodResult = pendingPhoneHintResult
            pendingPhoneHintResult = null

            if (methodResult == null) {
                return@registerForActivityResult
            }

            if (result.resultCode != Activity.RESULT_OK || result.data == null) {
                methodResult.success(null)
                return@registerForActivityResult
            }

            try {
                val phoneNumber = Identity.getSignInClient(this)
                    .getPhoneNumberFromIntent(result.data)
                methodResult.success(phoneNumber)
            } catch (error: ApiException) {
                methodResult.error(
                    "PHONE_HINT_READ_FAILED",
                    error.localizedMessage ?: "Unable to read phone number.",
                    null
                )
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mart24/device_phone_hint"
        ).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "getPhoneNumberHint" -> requestPhoneNumberHint(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun requestPhoneNumberHint(result: MethodChannel.Result) {
        if (pendingPhoneHintResult != null) {
            result.error(
                "PHONE_HINT_IN_PROGRESS",
                "Phone number hint request is already running.",
                null
            )
            return
        }

        pendingPhoneHintResult = result

        val request = GetPhoneNumberHintIntentRequest.builder().build()
        val signInClient = Identity.getSignInClient(this)

        signInClient.getPhoneNumberHintIntent(request)
            .addOnSuccessListener { pendingIntent ->
                try {
                    val intentRequest = IntentSenderRequest.Builder(pendingIntent).build()
                    phoneHintLauncher.launch(intentRequest)
                } catch (error: SendIntentException) {
                    pendingPhoneHintResult = null
                    result.error(
                        "PHONE_HINT_LAUNCH_FAILED",
                        error.localizedMessage ?: "Unable to open phone picker.",
                        null
                    )
                }
            }
            .addOnFailureListener {
                pendingPhoneHintResult = null
                result.success(null)
            }
    }
}