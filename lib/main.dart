import 'package:flutter/material.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Nanti kita bisa tambahkan inisialisasi lain di sini, 
  // seperti Firebase, Env variables, atau service locator.

  runApp(const EcoCashApp());
}