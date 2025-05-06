import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cotmade/global.dart';
import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/hostScreens/create_promo_screen.dart';
import 'package:cotmade/view/hostScreens/boost_property_screen.dart';

class HostDashboardScreen extends StatefulWidget {
  @override
  _HostDashboardScreenState createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  String selectedFilter = 'Monthly';
  String userCountry = '';
  String userId = AppConstants.currentUser.id.toString();
  int totalBookings = 0;
  Map<String, String> listingNames = {};
  List<Map<String, dynamic>> postings = [];
  Map<String, String> currencyMap = {
    'Algeria': 'AED', // Algerian Dinar
    'Angola': 'USD', // Angolan Kwanza
    'Benin': 'XOF', // West African CFA Franc
    'Botswana': 'ZAR', // Botswanan Pula
    'Burkina Faso': 'XOF', // West African CFA Franc
    'Burundi': 'USD', // Burundian Franc
    'Cape Verde': 'EUR', // Cape Verdean Escudo
    'Cameroon': 'XAF', // Central African CFA Franc
    'Central African Republic': 'XAF', // Central African CFA Franc
    'Chad': 'XAF', // Central African CFA Franc
    'Comoros': 'USD', // Comorian Franc
    'Congo (Congo-Brazzaville)': 'XAF', // Congolese Franc
    'Congo (Democratic Republic)': 'USD', // Congolese Franc
    'Djibouti': 'USD', // Djiboutian Franc
    'Egypt': 'EGP', // Egyptian Pound
    'Equatorial Guinea': 'XAF', // Central African CFA Franc
    'Eritrea': 'USD', // Eritrean Nakfa
    'Eswatini': 'ZAR', // Swazi Lilangeni
    'Ethiopia': 'USD', // Ethiopian Birr
    'Gabon': 'XAF', // Central African CFA Franc
    'Gambia': 'GMD', // Gambian Dalasi
    'Ghana': 'GHS', // Ghanaian Cedi
    'Guinea': 'GNF', // Guinean Franc
    'Guinea-Bissau': 'GNF', // Guinean Franc
    'Ivory Coast': 'XOF', // West African CFA Franc
    'Kenya': 'KES', // Kenyan Shilling
    'Lesotho': 'ZAR', // Lesotho Loti
    'Liberia': 'USD', // Liberian Dollar
    'Libya': 'EGP', // Libyan Dinar
    'Madagascar': 'USD', // Malagasy Ariary
    'Malawi': 'MWK', // Malawian Kwacha
    'Mali': 'XOF', // West African CFA Franc
    'Mauritania': 'XOF', // Mauritanian Ouguiya
    'Mauritius': 'MUR', // Mauritian Rupee
    'Morocco': 'MAD', // Moroccan Dirham
    'Mozambique': 'ZAR', // Mozambican Metical
    'Namibia': 'ZAR', // Namibian Dollar
    'Niger': 'XOF', // Mauritanian Ouguiya
    'Nigeria': 'NGN', // Nigerian Naira
    'Rwanda': 'RWF', // Rwandan Franc
    'São Tomé and Príncipe': 'STD', // São Tomé and Príncipe Dobra
    'Senegal': 'XOF', // West African CFA Franc
    'Seychelles': 'USD', // Seychellois Rupee
    'Sierra Leone': 'SLL', // Sierra Leonean Leone
    //'Somalia': 'SOS', // Somali Shilling
    'South Africa': 'ZAR', // South African Rand
    'South Sudan': 'USD', // South Sudanese Pound
    'Sudan': 'USD', // Sudanese Pound
    'Togo': 'XOF', // West African CFA Franc
    //'Tunisia': 'TND', // Tunisian Dinar
    'Uganda': 'UGX', // Ugandan Shilling
    'Zambia': 'ZMW', // Zambian Kwacha
    'Zimbabwe': 'ZAR',
  };
  String bestListing = "";
  String trendMessage = "";
  List<FlSpot> earningsTrend = []; // For the graph

  @override
  void initState() {
    super.initState();
    _fetchUserCountry();
    _getBookingsCount(userId).then((bookings) {
      setState(() {
        totalBookings =
            bookings; // Update the totalBookings state after getting the value
      });
    });
  }

  Future<void> _fetchUserCountry() async {
    String? userId = AppConstants.currentUser.id; // Replace with actual user ID
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userSnapshot.exists) {
      setState(() {
        userCountry = userSnapshot['country'] ??
            'United States'; // Default to 'United States' if not available
      });
    }

    _fetchPostings(); // Fetch postings after fetching the country
    _fetchTrendMessage(); // Fetch trend message after fetching the country
    _fetchEarningsTrend(); // Fetch earnings trend after fetching the country
  }

  Future<void> _fetchPostings() async {
    String userId =
        AppConstants.currentUser.id.toString(); // Get the current user ID
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    // Fetch the list of posting IDs associated with the user
    List<String> postingIds =
        List<String>.from(userSnapshot['myPostingIDs'] ?? []);

    if (postingIds.isEmpty) return;

    // Initialize a variable to track the posting with the most bookings
    String bestPostingId = '';
    int maxBookings = 0;

    // Temporary list to hold all the postings
    List<Map<String, dynamic>> tempPostings = [];

    // Loop through each posting ID and fetch details
    for (var postingId in postingIds) {
      int bookingsCount = await _getBookingsCountForPosting(postingId);

      // Check if this posting has the most bookings
      if (bookingsCount > maxBookings) {
        maxBookings = bookingsCount;
        bestPostingId = postingId;
      }

      // Fetch details for each posting
      DocumentSnapshot postingSnapshot = await FirebaseFirestore.instance
          .collection('postings')
          .doc(postingId)
          .get();
      tempPostings.add({
        'id': postingId,
        'name': postingSnapshot['name'],
        'createdAt': postingSnapshot['createdAt'].toDate(),
        'bookings': bookingsCount,
        'premium': postingSnapshot['premium'] ?? 1,
        'reviews': List<String>.from(postingSnapshot['reviews'] ?? []),
      });
    }

    // Set the best listing name using the posting ID with the most bookings
    setState(() {
      postings = tempPostings;
      bestListing = bestPostingId.isNotEmpty
          ? tempPostings
              .firstWhere((post) => post['id'] == bestPostingId)['name']
          : "No data available";
    });
  }

// This method counts the bookings for a given postingID
  Future<int> _getBookingsCountForPosting(String postingId) async {
    QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
        .collection('postings')
        .doc(postingId)
        .collection('bookings')
        .get();

    return bookingsSnapshot.size; // Return the number of bookings
  }

  Future<int> _getBookingsCount(String userId) async {
    QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bookings')
        .get();
    return bookingsSnapshot.size;
  }

  Future<void> _fetchTrendMessage() async {
    QuerySnapshot trendsSnapshot = await FirebaseFirestore.instance
        .collection('trend')
        .where('country', isEqualTo: userCountry)
        .limit(1)
        .get();
    setState(() {
      trendMessage = trendsSnapshot.docs.isNotEmpty
          ? trendsSnapshot.docs.first['message']
          : "";
    });
  }

  // Fetching earnings trend (for the graph) using bookings data
  Future<void> _fetchEarningsTrend() async {
    List<FlSpot> trendData = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      DateTime startOfMonth = DateTime(now.year, now.month - i, 1);
      DateTime endOfMonth = DateTime(now.year, now.month - i + 1, 0);

      QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
          .collection('postings')
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('createdAt', isLessThanOrEqualTo: endOfMonth)
          .get();

      int monthlyBookings = bookingsSnapshot.size;
      double earnings =
          monthlyBookings * 50.0; // Assuming $50 per booking for earnings

      trendData.add(FlSpot(i.toDouble(), earnings));
    }

    setState(() {
      earningsTrend = trendData.reversed
          .toList(); // Reverse to display the latest month first
    });
  }

  @override
  Widget build(BuildContext context) {
    String currency = currencyMap[userCountry] ?? 'USD';
    int totalBooking = totalBookings;
    int totalEarnings = totalBooking * 50;

    return Scaffold(
      //  appBar: AppBar(title: Text('Host Dashboard')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: selectedFilter,
              onChanged: (value) {
                setState(() {
                  selectedFilter = value!;
                });
              },
              items: ['Daily', 'Weekly', 'Monthly'].map((filter) {
                return DropdownMenuItem(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            _buildAnalyticsCard(
                'Total Bookings', NumberFormat("###,###").format(totalBooking)),
            _buildAnalyticsCard('Total Earnings',
                NumberFormat("###,###").format(totalEarnings)),
            _buildAnalyticsCard('Best Performing Listing', bestListing),
            if (trendMessage.isNotEmpty)
              Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      'Market Trend',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
    SizedBox(height: 4),
    _buildAnalyticsCard('', trendMessage), // Pass empty title
  ],
),
            if (earningsTrend.isNotEmpty) _buildGraph(),
            SizedBox(height: 20),
            Text('Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Column(
              children:
                  postings.map((post) => _buildPostingActions(post)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostingActions(Map<String, dynamic> post) {
    bool shouldSuggestBoost = post['bookings'] < 7 &&
        DateTime.now().difference(post['createdAt']).inDays >= 15;
    bool shouldSuggestReview = post['reviews'].length < 3;
    bool shouldSuggestPromo = post['premium'] != 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Listing: ${post['name']}',
            style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton('Create & run promo', Icons.price_change, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          CreatePromoCodeScreen(postingId: post['id'])));
            }),
            if (shouldSuggestPromo)
              _buildActionButton('Promote Listing', Icons.campaign, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            BoostPropertyPage(postingId: post['id'])));
              }),
          ],
        ),
        if (shouldSuggestBoost)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "Your listing is underperforming. Try promoting it or adding a video!",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        if (shouldSuggestReview)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "Encourage guests to leave reviews to boost bookings!",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        Divider(),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value) {
    return Card(
      color: Color(0xcaf6f6f6),
      shadowColor: Colors.black12,
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
        trailing: Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildGraph() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: earningsTrend.length.toDouble(),
          minY: 0,
          maxY: earningsTrend.isNotEmpty
              ? earningsTrend.map((e) => e.y).reduce((a, b) => a > b ? a : b) +
                  10
              : 0,
          lineBarsData: [
            LineChartBarData(
              spots: earningsTrend,
              isCurved: true,
              color: Colors.pinkAccent,
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
