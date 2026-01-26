class ApiConfig {
  // GANTI URL INI setiap kali kamu jalankan ngrok baru
  static const String baseUrl = "https://hireable-unelegant-linwood.ngrok-free.dev";

  // Header wajib agar menembus blokade halaman putih ngrok
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };
}