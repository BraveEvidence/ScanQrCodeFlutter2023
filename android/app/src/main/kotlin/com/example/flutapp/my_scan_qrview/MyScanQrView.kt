package com.example.flutapp.my_scan_qrview


import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.view.Choreographer
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MyScanQrView(
    private val context: Context, messenger: BinaryMessenger, id: Int, creationParams: Map<String?, Any?>?,
    private val activity: FlutterActivity
) : PlatformView {

    private var mCameraProvider: ProcessCameraProvider? = null

    private var preview: PreviewView = PreviewView(context)
    private var methodChannel: MethodChannel = MethodChannel(messenger, "scanQrView")

    private lateinit var cameraExecutor: ExecutorService
    private lateinit var options: BarcodeScannerOptions
    private lateinit var scanner: BarcodeScanner

    private var analysisUseCase: ImageAnalysis = ImageAnalysis.Builder()
//        .setTargetAspectRatio(AspectRatio.RATIO_16_9)
        .build()

    companion object {
        private val REQUEST_CODE_PERMISSIONS = 10
        private val REQUIRED_PERMISSIONS = mutableListOf(Manifest.permission.CAMERA).toTypedArray()
    }


    init {
//        preview.scaleType = PreviewView.ScaleType.FILL_CENTER
        preview.layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
//        preview.layoutParams.height = 700
//        preview.layoutParams.width = 700
//        setupLayoutHack()
        setUpCamera()
    }

//    private fun setupLayoutHack() {
//        Choreographer.getInstance().postFrameCallback(object : Choreographer.FrameCallback {
//            override fun doFrame(frameTimeNanos: Long) {
//                manuallyLayoutChildren()
//                preview.viewTreeObserver.dispatchOnGlobalLayout()
//                Choreographer.getInstance().postFrameCallback(this)
//            }
//        })
//    }
//
//    private fun manuallyLayoutChildren() {
//        for (i in 0 until preview.childCount) {
//            val child = preview.getChildAt(i)
//            child.measure(
//                View.MeasureSpec.makeMeasureSpec(preview.measuredWidth, View.MeasureSpec.EXACTLY),
//                View.MeasureSpec.makeMeasureSpec(preview.measuredHeight, View.MeasureSpec.EXACTLY)
//            )
//            child.layout(0, 0, child.measuredWidth, child.measuredHeight)
//        }
//    }

    private fun setUpCamera() {
        if (allPermissionsGranted()) {
            startCamera()
        } else {
            ActivityCompat.requestPermissions(
                context as FlutterActivity, REQUIRED_PERMISSIONS, REQUEST_CODE_PERMISSIONS
            )
        }
        cameraExecutor = Executors.newSingleThreadExecutor()

        options = BarcodeScannerOptions.Builder()
            .setBarcodeFormats(
                Barcode.FORMAT_QR_CODE
            )
            .build()
        scanner = BarcodeScanning.getClient(options)
        analysisUseCase.setAnalyzer(
            // newSingleThreadExecutor() will let us perform analysis on a single worker thread
            Executors.newSingleThreadExecutor()
        ) { imageProxy ->
            processImageProxy(scanner, imageProxy)
        }
    }

    override fun getView(): View {
        return preview
    }



    override fun dispose() {
        cameraExecutor.shutdown()
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun processImageProxy(
        barcodeScanner: BarcodeScanner,
        imageProxy: ImageProxy
    ) {
        imageProxy.image?.let { image ->
            val inputImage =
                InputImage.fromMediaImage(
                    image,
                    imageProxy.imageInfo.rotationDegrees
                )
            barcodeScanner.process(inputImage)
                .addOnSuccessListener { barcodeList ->
                    val barcode = barcodeList.getOrNull(0)
                    // `rawValue` is the decoded value of the barcode
                    barcode?.rawValue?.let { value ->
                        methodChannel.invokeMethod("sendFromNative", value)
                        Toast.makeText(context, value, Toast.LENGTH_LONG).show()
                        mCameraProvider?.unbindAll()

                    }
                }
                .addOnFailureListener {
                    // This failure will happen if the barcode scanning model
                    // fails to download from Google Play Services
                }
                .addOnCompleteListener {
                    // When the image is from CameraX analysis use case, must
                    // call image.close() on received images when finished
                    // using them. Otherwise, new images may not be received
                    // or the camera may stall.
                    imageProxy.image?.close()
                    imageProxy.close()
                }
        }
    }

    private fun allPermissionsGranted() = REQUIRED_PERMISSIONS.all {
        ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

        cameraProviderFuture.addListener({
            // Used to bind the lifecycle of cameras to the lifecycle owner
            val cameraProvider: ProcessCameraProvider = cameraProviderFuture.get()
            mCameraProvider = cameraProvider
            // Preview
            val surfacePreview = Preview.Builder().setTargetAspectRatio(AspectRatio.RATIO_16_9)
                .setTargetRotation(preview.display.rotation)
                .build()
                .also {
                    it.setSurfaceProvider(preview.surfaceProvider)
                }
            // Select back camera as a default
            val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
            try {
                // Unbind use cases before rebinding
                cameraProvider.unbindAll()
                // Bind use cases to camera
                cameraProvider.bindToLifecycle(
                    activity,
                    cameraSelector,
                    surfacePreview,
                    analysisUseCase,
                )
            } catch (exc: Exception) {
                // Do nothing on exception
            }
        }, ContextCompat.getMainExecutor(context))
    }




}