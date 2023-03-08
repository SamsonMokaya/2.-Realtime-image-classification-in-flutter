import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';


late List<CameraDescription> _cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  late CameraController controller;
  CameraImage? img;
  bool isBusy = false;
  String result = "";
  dynamic imageLabeler;

  @override
  void initState() {
    super.initState();
    //TODO initialize Labeller


    final ImageLabelerOptions options = ImageLabelerOptions(confidenceThreshold: 0.5);
    imageLabeler = ImageLabeler(options: options);


    //TODO initialize the controller
    //Specifies the camera
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) => {
        if(isBusy == false){
          img = image, doImageLabeling(),isBusy=true
        }
      });
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print("Handle access errors here.");
            break;
          default:
            print("Handle other errors here.");
            break;
        }
      }
    });
  }

  doImageLabeling() async {
    result = "";
    InputImage inputImg = getInputImage();
    final List<ImageLabel> labels = await imageLabeler.processImage(inputImg);
    for (ImageLabel label in labels) {
      final String text = label.label;
      final int index = label.index;
      final double confidence = label.confidence;
      result += "$text   ${confidence.toStringAsFixed(2)}\n";
    }
    setState(() {
      result;
      isBusy = false;
    });
  }

  //Camera related starter code
  InputImage getInputImage() {
    final WriteBuffer allBytes = WriteBuffer();

    for (final Plane plane in img!.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(img!.width.toDouble(), img!.height.toDouble());

    final camera = _cameras[0];
    final imageRotation =
    InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    // if (imageRotation == null) return;

    final inputImageFormat =
    InputImageFormatValue.fromRawValue(img!.format.raw);
    // if (inputImageFormat == null) return null;

    final planeData = img!.planes.map(
          (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation!,
      inputImageFormat: inputImageFormat!,
      planeData: planeData,
    );

    final inputImage =
    InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    return inputImage;
  }



  @override
  void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      home: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),

          Container(
            margin: EdgeInsets.only(left: 10, bottom: 10),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                result,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 25
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
