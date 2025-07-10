// 🛠 FINAL FIXED VERSION: Currency Converter with Clean Chart and Flip Cards

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final List<String> currencies = ['USD', 'PKR', 'EUR', 'GBP', 'INR', 'CAD', 'AUD', 'JPY', 'CNY', 'SAR'];
  final Map<String, String> currencyFlags = {
    'USD': '🇺🇸', 'PKR': '🇵🇰', 'EUR': '🇪🇺', 'GBP': '🇬🇧', 'INR': '🇮🇳',
    'CAD': '🇨🇦', 'AUD': '🇦🇺', 'JPY': '🇯🇵', 'CNY': '🇨🇳', 'SAR': '🇸🇦',
  };

  String from = 'USD';
  String to = 'PKR';
  String result = '';
  double trendingRate = 0;
  bool isLoading = false;
  bool isDarkMode = false;

  final TextEditingController controller = TextEditingController();
  List<FlSpot> chartSpots = [];

  late final AnimationController _animationController;
  late final Animation<double> _fadeIn;
  bool showFront = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> convertCurrency() async {
    final input = double.tryParse(controller.text);
    if (input == null || input <= 0) {
      showMessage('❗ Please enter a valid amount.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = 'https://open.er-api.com/v6/latest/$from';
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['rates'] != null) {
        final rate = data['rates'][to];
        final converted = rate * input;

        setState(() {
          result = converted.toStringAsFixed(2);
          trendingRate = rate;
          chartSpots.add(FlSpot(chartSpots.length.toDouble() + 1, converted));
        });

        _animationController.forward(from: 0);
      } else {
        showMessage('⚠️ Conversion failed.');
      }
    } catch (e) {
      showMessage('❌ Network/API error.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  ThemeData get currentTheme => isDarkMode ? ThemeData.dark() : ThemeData.light();

  Widget buildTrendingCard(String code, String price) {
    return GestureDetector(
      onTap: () => setState(() => showFront = !showFront),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, anim) => RotationYTransition(turns: anim, child: child),
        child: showFront
            ? Container(
          key: const ValueKey(true),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.teal[800] : Colors.teal[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(currencyFlags[code] ?? '', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text('$code → \$$price',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        )
            : Container(
          key: const ValueKey(false),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 25),
          decoration: BoxDecoration(
            color: Colors.deepPurpleAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Most Traded\nMerchant Coin',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: currentTheme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Currency Converter'),
          centerTitle: true,
          actions: [
            Row(
              children: [
                const Icon(Icons.dark_mode),
                Switch(
                  value: isDarkMode,
                  onChanged: (val) => setState(() => isDarkMode = val),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Enter amount',
                        hintText: 'e.g. 100',
                        prefixIcon: const Icon(Icons.attach_money),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: from,
                            decoration: InputDecoration(
                              labelText: 'From',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: currencies
                                .map((code) => DropdownMenuItem(
                              value: code,
                              child: Text('${currencyFlags[code]} $code'),
                            ))
                                .toList(),
                            onChanged: (val) => setState(() => from = val!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.swap_horiz),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: to,
                            decoration: InputDecoration(
                              labelText: 'To',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: currencies
                                .map((code) => DropdownMenuItem(
                              value: code,
                              child: Text('${currencyFlags[code]} $code'),
                            ))
                                .toList(),
                            onChanged: (val) => setState(() => to = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : convertCurrency,
                      icon: const Icon(Icons.currency_exchange),
                      label: const Text('Convert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.tealAccent[700] : const Color(0xFF00B4DB),
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 35),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              if (isLoading)
                const CircularProgressIndicator()
              else if (result.isNotEmpty)
                FadeTransition(
                  opacity: _fadeIn,
                  child: Text(
                    'Converted Amount: $result $to',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.tealAccent : const Color(0xFF0083B0),
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              if (chartSpots.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 User Conversion Attempts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, _) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('${value.toInt()}', style: const TextStyle(fontSize: 11)),
                                ),
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: chartSpots,
                              isCurved: true,
                              color: Colors.deepPurpleAccent,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.3)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 30),
              const Text('Trending Market Currencies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              buildTrendingCard("USD", "1.00"),
              buildTrendingCard("EUR", "0.91"),
              buildTrendingCard("JPY", "110.43"),
            ],
          ),
        ),
      ),
    );
  }
}

class RotationYTransition extends AnimatedWidget {
  final Widget child;
  const RotationYTransition({super.key, required Animation<double> turns, required this.child}) : super(listenable: turns);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    final angle = animation.value * pi;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(angle),
      child: animation.value <= 0.5 ? child : Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(pi),
        child: child,
      ),
    );
  }
}
