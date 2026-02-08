import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const GeminiVisionApp());
}

class GeminiVisionApp extends StatelessWidget {
  const GeminiVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.lexendTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
      ),
      home: const VisionPage(),
    );
  }
}

class VisionPage extends StatefulWidget {
  const VisionPage({super.key});
  @override
  State<VisionPage> createState() => _VisionPageState();
}

class _VisionPageState extends State<VisionPage> {
  final ImagePicker _picker = ImagePicker();
  String _displayText = "# Ready to Scan\nAdjust the slider and tap the camera to begin.";
  bool _isLoading = false;
  double _complexityLevel = 1.0;
  final List<String> _levelLabels = ["Quick Focus", "Guided Reading", "Deep Study"];

  String _detailInstruction() {
    switch (_complexityLevel.toInt()) {
      case 0:
        return "MODE: Quick Summary. Use bullets. Final formulas only.";
      case 1:
        return "MODE: Simple Explanation. Use plain language and basic examples.";
      case 2:
      default:
        return "MODE: Comprehensive Study Guide. Detailed concepts and essential derivations.";
    }
  }

  Future<void> _analyzePage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      _isLoading = true;
      _displayText = "### Processing...\nOptimizing LaTeX output...";
    });

    try {
      final bytes = await image.readAsBytes();

      final model = GenerativeModel(
        model: 'gemini-2.0-flash', // Using 2.0 Flash for maximum stability
        apiKey: dotenv.env['API_KEY']!,
        generationConfig: GenerationConfig(temperature: 0.1), // Lower temp = stricter formatting
      );

      final prompt = TextPart(
        "Analyze the image and provide a study guide. ${_detailInstruction()}\n\n"
        "STRICT MATH FORMATTING:\n"
        "1. Use single \$ for inline math: \$E=mc^2\$.\n"
        "2. Use double \$\$ for blocks: \$\$E=mc^2\$\$.\n"
        "3. NEVER use backslashes before dollar signs (NO \\\$).\n"
        "4. NEVER wrap math in parentheses like (\$x\$). Just write \$x\$.\n"
        "5. NEVER use \\( or \\) delimiters."
      );

      final response = await model.generateContent([
        Content.multi([prompt, DataPart('image/jpeg', bytes)])
      ]);

      String cleanedText = response.text ?? "Error: Empty response.";
      
      // SANITIZATION: This regex strips backslashes from dollar signs if the AI slips up.
      // It effectively fixes the "Can't use function $" error by ensuring raw dollar signs.
      cleanedText = cleanedText.replaceAll(r'\$', r'$').replaceAll(r'\(', r'$').replaceAll(r'\)', r'$');

      setState(() => _displayText = cleanedText);
    } catch (e) {
      setState(() => _displayText = "## Connection Error\n$e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDFCFB), Color(0xFFE2D1F9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildComplexitySlider(),
              Expanded(child: _buildMainContent()),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _analyzePage,
        label: const Text("Scan Textbook", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.camera_rounded),
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Vision Tutor", style: GoogleFonts.lexend(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF4A3A75))),
          const Icon(Icons.auto_fix_high, color: Color(0xFF4A3A75)),
        ],
      ),
    );
  }

  Widget _buildComplexitySlider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6), // Warning fixed
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)), // Warning fixed
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Detail Level", style: GoogleFonts.lexend(fontWeight: FontWeight.w500)),
              Text(_levelLabels[_complexityLevel.toInt()], 
                style: GoogleFonts.lexend(color: const Color(0xFF6750A4), fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _complexityLevel,
            min: 0, max: 2, divisions: 2,
            activeColor: const Color(0xFF6750A4),
            onChanged: (v) => setState(() => _complexityLevel = v),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), // Warning fixed
              blurRadius: 20, 
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Markdown(
              data: _displayText,
              selectable: true,
              builders: {'latex': LatexElementBuilder()},
              extensionSet: md.ExtensionSet(
                [LatexBlockSyntax()],
                [md.EmojiSyntax(), LatexInlineSyntax()],
              ),
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.lexend(fontSize: 18, height: 1.8, color: const Color(0xFF333333)),
                h1: GoogleFonts.lexend(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF6750A4)),
                h2: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF4A3A75)),
              ),
            ),
      ),
    );
  }
}