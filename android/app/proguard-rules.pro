# ML Kit (google_mlkit_text_recognition): o app só usa o reconhecedor latino; os outros
# alfabetos são referenciados pelo plugin mas não estão no APK.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
