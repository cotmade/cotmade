import 'dart:io';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cotmade/global.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:flutter/services.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _firstNameTextController = TextEditingController();
  TextEditingController _lastNameTextController = TextEditingController();
  TextEditingController _bioTextController = TextEditingController();
  TextEditingController _mobileNumberTextController = TextEditingController();

  // Country and State Variables
  String? selectedCountry;
  String? selectedState;

  // TextEditingController for search input
  TextEditingController _countrySearchController = TextEditingController();
  TextEditingController _stateSearchController = TextEditingController();

  // Map for countries and their respective states
  final Map<String, List<String>> countryStateMap = {
    "Afghanistan": ["Kabul", "Herat", "Mazar-i-Sharif"],
    "Albania": ["Tirana", "Durrës", "Vlorë"],
    "Algeria": ["Algiers", "Oran", "Constantine"],
    "Andorra": ["Andorra la Vella", "Escaldes-Engordany", "Encamp"],
    "Angola": ["Luanda", "Benguela", "Huambo"],
    "Argentina": ["Buenos Aires", "Córdoba", "Rosario"],
    "Armenia": ["Yerevan", "Gyumri", "Vanadzor"],
    "Australia": ["Sydney", "Melbourne", "Brisbane"],
    "Austria": ["Vienna", "Salzburg", "Graz"],
    "Azerbaijan": ["Baku", "Ganja", "Mingachevir"],
    "Bahamas": ["Nassau", "Freeport", "West End"],
    "Bahrain": ["Manama", "Riffa", "Muharraq"],
    "Bangladesh": ["Dhaka", "Chittagong", "Khulna"],
    "Barbados": ["Bridgetown", "Speightstown", "Oistins"],
    "Belarus": ["Minsk", "Gomel", "Mogilev"],
    "Belgium": ["Brussels", "Antwerp", "Ghent"],
    "Belize": ["Belmopan", "Belize City", "San Ignacio"],
    "Benin": ["Cotonou", "Porto-Novo", "Djougou"],
    "Bhutan": ["Thimphu", "Phuntsholing", "Paro"],
    "Bolivia": ["Sucre", "La Paz", "Santa Cruz"],
    "Bosnia and Herzegovina": ["Sarajevo", "Banja Luka", "Tuzla"],
    "Botswana": ["Gaborone", "Francistown", "Molepolole"],
    "Brazil": ["São Paulo", "Rio de Janeiro", "Brasília"],
    "Brunei": ["Bandar Seri Begawan", "Kuala Belait", "Seria"],
    "Bulgaria": ["Sofia", "Plovdiv", "Varna"],
    "Burkina Faso": ["Ouagadougou", "Bobo-Dioulasso", "Koudougou"],
    "Burundi": ["Bujumbura", "Gitega", "Ngozi"],
    "Cabo Verde": ["Praia", "Mindelo", "Santa Maria"],
    "Cambodia": ["Phnom Penh", "Siem Reap", "Battambang"],
    "Cameroon": ["Yaoundé", "Douala", "Bamenda"],
    "Canada": ["Toronto", "Vancouver", "Montreal"],
    "Central African Republic": ["Bangui", "Bimbo", "Berbérati"],
    "Chad": ["N'Djamena", "Moundou", "Sarh"],
    "Chile": ["Santiago", "Valparaíso", "Concepción"],
    "China": ["Beijing", "Shanghai", "Guangzhou"],
    "Colombia": ["Bogotá", "Medellín", "Cali"],
    "Comoros": ["Moroni", "Mutsamudu", "Fomboni"],
    "Congo (Congo-Brazzaville)": ["Brazzaville", "Pointe-Noire", "Dolisie"],
    "Congo (Democratic Republic)": ["Kinshasa", "Lubumbashi", "Mbuji-Mayi"],
    "Costa Rica": ["San José", "Alajuela", "Cartago"],
    "Croatia": ["Zagreb", "Split", "Rijeka"],
    "Cuba": ["Havana", "Santiago de Cuba", "Camagüey"],
    "Cyprus": ["Nicosia", "Limassol", "Larnaca"],
    "Czech Republic": ["Prague", "Brno", "Ostrava"],
    "Denmark": ["Copenhagen", "Aarhus", "Odense"],
    "Djibouti": ["Djibouti", "Ali Sabieh", "Tadjourah"],
    "Dominica": ["Roseau", "Portsmouth", "La Plaine"],
    "Dominican Republic": ["Santo Domingo", "Santiago", "La Romana"],
    "Ecuador": ["Quito", "Guayaquil", "Cuenca"],
    "Egypt": ["Cairo", "Alexandria", "Giza"],
    "El Salvador": ["San Salvador", "Santa Ana", "San Miguel"],
    "Equatorial Guinea": ["Malabo", "Bata", "Ebebiyin"],
    "Eritrea": ["Asmara", "Mendefera", "Keren"],
    "Estonia": ["Tallinn", "Tartu", "Narva"],
    "Eswatini": ["Mbabane", "Manzini", "Lobamba"],
    "Ethiopia": ["Addis Ababa", "Mekelle", "Gondar"],
    "Fiji": ["Suva", "Nadi", "Lautoka"],
    "Finland": ["Helsinki", "Espoo", "Tampere"],
    "France": ["Paris", "Marseille", "Lyon"],
    "Gabon": ["Libreville", "Port-Gentil", "Franceville"],
    "Gambia": ["Banjul", "Serekunda", "Brikama"],
    "Georgia": ["Tbilisi", "Batumi", "Kutaisi"],
    "Germany": ["Berlin", "Munich", "Frankfurt"],
    "Ghana": ["Accra", "Kumasi", "Takoradi"],
    "Greece": ["Athens", "Thessaloniki", "Patras"],
    "Grenada": ["St. George's", "Gouyave", "Victoria"],
    "Guatemala": ["Guatemala City", "Antigua Guatemala", "Quetzaltenango"],
    "Guinea": ["Conakry", "Kankan", "Nzérékoré"],
    "Guinea-Bissau": ["Bissau", "Bafatá", "Cacheu"],
    "Guyana": ["Georgetown", "New Amsterdam", "Linden"],
    "Haiti": ["Port-au-Prince", "Cap-Haïtien", "Les Cayes"],
    "Honduras": ["Tegucigalpa", "San Pedro Sula", "La Ceiba"],
    "Hungary": ["Budapest", "Debrecen", "Szeged"],
    "Iceland": ["Reykjavík", "Reykjanesbær", "Akureyri"],
    "India": ["Delhi", "Mumbai", "Kolkata", "Bangalore"],
    "Indonesia": ["Jakarta", "Surabaya", "Medan"],
    "Iran": ["Tehran", "Mashhad", "Isfahan"],
    "Iraq": ["Baghdad", "Basra", "Erbil"],
    "Ireland": ["Dublin", "Cork", "Galway"],
    "Israel": ["Jerusalem", "Tel Aviv", "Haifa"],
    "Italy": ["Rome", "Milan", "Naples"],
    "Jamaica": ["Kingston", "Montego Bay", "Spanish Town"],
    "Japan": ["Tokyo", "Osaka", "Kyoto"],
    "Jordan": ["Amman", "Irbid", "Zarqa"],
    "Kazakhstan": ["Almaty", "Nur-Sultan", "Shymkent"],
    "Kenya": ["Nairobi", "Mombasa", "Kisumu"],
    "Kiribati": ["Tarawa", "Betio", "Bairiki"],
    "Korea, North": ["Pyongyang", "Hamhung", "Chongjin"],
    "Korea, South": ["Seoul", "Busan", "Incheon"],
    "Kuwait": ["Kuwait City", "Salmiya", "Fahaheel"],
    "Kyrgyzstan": ["Bishkek", "Osh", "Jalal-Abad"],
    "Laos": ["Vientiane", "Luang Prabang", "Savannakhet"],
    "Latvia": ["Riga", "Jurmala", "Jelgava"],
    "Lebanon": ["Beirut", "Tripoli", "Sidon"],
    "Lesotho": ["Maseru", "Teyateyaneng", "Leribe"],
    "Liberia": ["Monrovia", "Gbarnga", "Buchanan"],
    "Libya": ["Tripoli", "Benghazi", "Misrata"],
    "Liechtenstein": ["Vaduz", "Balzers", "Schaan"],
    "Lithuania": ["Vilnius", "Kaunas", "Klaipėda"],
    "Luxembourg": ["Luxembourg City", "Ettelbruck", "Differdange"],
    "Madagascar": ["Antananarivo", "Toamasina", "Antsirabe"],
    "Malawi": ["Lilongwe", "Blantyre", "Mzuzu"],
    "Malaysia": ["Kuala Lumpur", "Penang", "Johor Bahru"],
    "Maldives": ["Malé", "Addu City", "Fuvahmulah"],
    "Mali": ["Bamako", "Segou", "Kayes"],
    "Malta": ["Valletta", "Mosta", "Birkirkara"],
    "Marshall Islands": ["Majuro", "Ebeye", "Kwajalein"],
    "Mauritania": ["Nouakchott", "Nouadhibou", "Kiffa"],
    "Mauritius": ["Port Louis", "Beau Bassin-Rose Hill", "Vacoas-Phoenix"],
    "Mexico": ["Mexico City", "Guadalajara", "Monterrey"],
    "Micronesia": ["Palikir", "Weno", "Colonia"],
    "Moldova": ["Chișinău", "Bălți", "Bender"],
    "Monaco": ["Monaco", "Monte Carlo", "Moneghetti"],
    "Mongolia": ["Ulaanbaatar", "Erdenet", "Darkhan"],
    "Montenegro": ["Podgorica", "Nikšić", "Herceg Novi"],
    "Morocco": ["Rabat", "Casablanca", "Marrakech"],
    "Mozambique": ["Maputo", "Beira", "Nampula"],
    "Myanmar (Burma)": ["Naypyidaw", "Yangon", "Mandalay"],
    "Namibia": ["Windhoek", "Swakopmund", "Rundu"],
    "Nauru": ["Yaren", "Aiwo", "Meneng"],
    "Nepal": ["Kathmandu", "Pokhara", "Lalitpur"],
    "Netherlands": ["Amsterdam", "Rotterdam", "The Hague"],
    "New Zealand": ["Wellington", "Auckland", "Christchurch"],
    "Nicaragua": ["Managua", "León", "Masaya"],
    "Niger": ["Niamey", "Zinder", "Maradi"],
    "Nigeria": [
      'Abia',
      'Abuja',
      'Adamawa',
      'Akwa Ibom',
      "Anambra",
      "Bauchi",
      "Bayelsa",
      "Benue",
      "Borno",
      "Cross River",
      "Delta",
      "Ebonyi",
      "Edo",
      "Ekiti",
      "Enugu",
      "Gombe",
      "Imo",
      "Jigawa",
      "Kaduna",
      "Kano",
      "Katsina",
      "Kebbi",
      "Kogi",
      "Kwara",
      "Lagos",
      "Nasarawa",
      "Niger",
      "Ogun",
      "Ondo",
      "Osun",
      "Oyo",
      "Plateau",
      "Rivers",
      "Sokoto",
      "Taraba",
      "Yobe",
      "Zamfara"
    ],
    "North Macedonia": ["Skopje", "Bitola", "Kumanovo"],
    "Norway": ["Oslo", "Bergen", "Stavanger"],
    "Oman": ["Muscat", "Salalah", "Sohar"],
    "Pakistan": ["Islamabad", "Karachi", "Lahore"],
    "Palau": ["Ngerulmud", "Koror", "Melekeok"],
    "Panama": ["Panama City", "David", "Colón"],
    "Papua New Guinea": ["Port Moresby", "Lae", "Mount Hagen"],
    "Paraguay": ["Asunción", "Ciudad del Este", "San Lorenzo"],
    "Peru": ["Lima", "Arequipa", "Cusco"],
    "Philippines": ["Manila", "Quezon City", "Davao City"],
    "Poland": ["Warsaw", "Kraków", "Wrocław"],
    "Portugal": ["Lisbon", "Porto", "Braga"],
    "Qatar": ["Doha", "Al Rayyan", "Al Wakrah"],
    "Romania": ["Bucharest", "Cluj-Napoca", "Timișoara"],
    "Russia": ["Moscow", "Saint Petersburg", "Novosibirsk"],
    "Rwanda": ["Kigali", "Butare", "Gisenyi"],
    "Saint Kitts and Nevis": ["Basseterre", "Charlestown", "Tabernacle"],
    "Saint Lucia": ["Castries", "Gros Islet", "Vieux Fort"],
    "Saint Vincent and the Grenadines": ["Kingstown", "Georgetown", "Bequia"],
    "Samoa": ["Apia", "Leva", "Fagali'i"],
    "San Marino": ["San Marino", "Serravalle", "Borgo Maggiore"],
    "Sao Tome and Principe": ["São Tomé", "Principe", "Neves"],
    "Saudi Arabia": ["Riyadh", "Jeddah", "Mecca"],
    "Senegal": ["Dakar", "Touba", "Ziguinchor"],
    "Serbia": ["Belgrade", "Novi Sad", "Niš"],
    "Seychelles": ["Victoria", "Anse Royale", "Beau Vallon"],
    "Sierra Leone": ["Freetown", "Bo", "Kenema"],
    "Singapore": ["Singapore", "Sentosa", "Bukit Timah"],
    "Slovakia": ["Bratislava", "Košice", "Nitra"],
    "Slovenia": ["Ljubljana", "Maribor", "Celje"],
    "Solomon Islands": ["Honiara", "Gizo", "Auki"],
    "Somalia": ["Mogadishu", "Hargeisa", "Kismayo"],
    "South Africa": ["Pretoria", "Cape Town", "Durban"],
    "South Sudan": ["Juba", "Malakal", "Wau"],
    "Spain": ["Madrid", "Barcelona", "Valencia"],
    "Sri Lanka": ["Colombo", "Kandy", "Galle"],
    "Sudan": ["Khartoum", "Omdurman", "Port Sudan"],
    "Suriname": ["Paramaribo", "Lelydorp", "Nickerie"],
    "Sweden": ["Stockholm", "Gothenburg", "Malmö"],
    "Switzerland": ["Bern", "Zurich", "Geneva"],
    "Syria": ["Damascus", "Aleppo", "Homs"],
    "Taiwan": ["Taipei", "Kaohsiung", "Taichung"],
    "Tajikistan": ["Dushanbe", "Khujand", "Kulob"],
    "Tanzania": ["Dodoma", "Dar es Salaam", "Arusha"],
    "Thailand": ["Bangkok", "Chiang Mai", "Phuket"],
    "Togo": ["Lomé", "Kara", "Sokodé"],
    "Tonga": ["Nuku'alofa", "Neiafu", "Vava'u"],
    "Trinidad and Tobago": ["Port of Spain", "San Fernando", "Chaguanas"],
    "Tunisia": ["Tunis", "Sfax", "Sousse"],
    "Turkey": ["Ankara", "Istanbul", "Izmir"],
    "Turkmenistan": ["Ashgabat", "Turkmenabat", "Mary"],
    "Tuvalu": ["Funafuti", "Vaitupu", "Nukufetau"],
    "Uganda": ["Kampala", "Entebbe", "Jinja"],
    "Ukraine": ["Kyiv", "Lviv", "Odesa"],
    "United Arab Emirates": ["Abu Dhabi", "Dubai", "Sharjah"],
    "United Kingdom": ["London", "Manchester", "Birmingham"],
    "United States of America": ["California", "Texas", "Florida", "New York"],
    "Uruguay": ["Montevideo", "Salto", "Paysandú"],
    "Uzbekistan": ["Tashkent", "Samarkand", "Bukhara"],
    "Vanuatu": ["Port Vila", "Luganville", "Isangel"],
    "Vatican City": [
      "Vatican City",
      "St. Peter's Basilica",
      "Piazza San Pietro"
    ],
    "Venezuela": ["Caracas", "Maracaibo", "Valencia"],
    "Vietnam": ["Hanoi", "Ho Chi Minh City", "Da Nang"],
    "Yemen": ["Sanaa", "Aden", "Taiz"],
    "Zambia": ["Lusaka", "Kitwe", "Ndola"],
    "Zimbabwe": ["Harare", "Bulawayo", "Mutare"],
  };

  // Available countries for the country dropdown
  List<String> countries = [
    "Afghanistan",
    "Albania",
    "Algeria",
    "Andorra",
    "Angola",
    "Antigua and Barbuda",
    "Argentina",
    "Armenia",
    "Australia",
    "Austria",
    "Azerbaijan",
    "Bahamas",
    "Bahrain",
    "Bangladesh",
    "Barbados",
    "Belarus",
    "Belgium",
    "Belize",
    "Benin",
    "Bhutan",
    "Bolivia",
    "Bosnia and Herzegovina",
    "Botswana",
    "Brazil",
    "Brunei",
    "Bulgaria",
    "Burkina Faso",
    "Burundi",
    "Cabo Verde",
    "Cambodia",
    "Cameroon",
    "Canada",
    "Central African Republic",
    "Chad",
    "Chile",
    "China",
    "Colombia",
    "Comoros",
    "Congo (Congo-Brazzaville)",
    "Congo (Democratic Republic)",
    "Costa Rica",
    "Croatia",
    "Cuba",
    "Cyprus",
    "Czech Republic",
    "Denmark",
    "Djibouti",
    "Dominica",
    "Dominican Republic",
    "Ecuador",
    "Egypt",
    "El Salvador",
    "Equatorial Guinea",
    "Eritrea",
    "Estonia",
    "Eswatini",
    "Ethiopia",
    "Fiji",
    "Finland",
    "France",
    "Gabon",
    "Gambia",
    "Georgia",
    "Germany",
    "Ghana",
    "Greece",
    "Grenada",
    "Guatemala",
    "Guinea",
    "Guinea-Bissau",
    "Guyana",
    "Haiti",
    "Honduras",
    "Hungary",
    "Iceland",
    "India",
    "Indonesia",
    "Iran",
    "Iraq",
    "Ireland",
    "Israel",
    "Italy",
    "Jamaica",
    "Japan",
    "Jordan",
    "Kazakhstan",
    "Kenya",
    "Kiribati",
    "Korea, North",
    "Korea, South",
    "Kuwait",
    "Kyrgyzstan",
    "Laos",
    "Latvia",
    "Lebanon",
    "Lesotho",
    "Liberia",
    "Libya",
    "Liechtenstein",
    "Lithuania",
    "Luxembourg",
    "Madagascar",
    "Malawi",
    "Malaysia",
    "Maldives",
    "Mali",
    "Malta",
    "Marshall Islands",
    "Mauritania",
    "Mauritius",
    "Mexico",
    "Micronesia",
    "Moldova",
    "Monaco",
    "Mongolia",
    "Montenegro",
    "Morocco",
    "Mozambique",
    "Myanmar (Burma)",
    "Namibia",
    "Nauru",
    "Nepal",
    "Netherlands",
    "New Zealand",
    "Nicaragua",
    "Niger",
    "Nigeria",
    "North Macedonia",
    "Norway",
    "Oman",
    "Pakistan",
    "Palau",
    "Panama",
    "Papua New Guinea",
    "Paraguay",
    "Peru",
    "Philippines",
    "Poland",
    "Portugal",
    "Qatar",
    "Romania",
    "Russia",
    "Rwanda",
    "Saint Kitts and Nevis",
    "Saint Lucia",
    "Saint Vincent and the Grenadines",
    "Samoa",
    "San Marino",
    "Sao Tome and Principe",
    "Saudi Arabia",
    "Senegal",
    "Serbia",
    "Seychelles",
    "Sierra Leone",
    "Singapore",
    "Slovakia",
    "Slovenia",
    "Solomon Islands",
    "Somalia",
    "South Africa",
    "South Sudan",
    "Spain",
    "Sri Lanka",
    "Sudan",
    "Suriname",
    "Sweden",
    "Switzerland",
    "Syria",
    "Taiwan",
    "Tajikistan",
    "Tanzania",
    "Thailand",
    "Togo",
    "Tonga",
    "Trinidad and Tobago",
    "Tunisia",
    "Turkey",
    "Turkmenistan",
    "Tuvalu",
    "Uganda",
    "Ukraine",
    "United Arab Emirates",
    "United Kingdom",
    "United States of America",
    "Uruguay",
    "Uzbekistan",
    "Vanuatu",
    "Vatican City",
    "Venezuela",
    "Vietnam",
    "Yemen",
    "Zambia",
    "Zimbabwe"
  ];

  List<String> filteredCountries = [
    "Afghanistan",
    "Albania",
    "Algeria",
    "Andorra",
    "Angola",
    "Antigua and Barbuda",
    "Argentina",
    "Armenia",
    "Australia",
    "Austria",
    "Azerbaijan",
    "Bahamas",
    "Bahrain",
    "Bangladesh",
    "Barbados",
    "Belarus",
    "Belgium",
    "Belize",
    "Benin",
    "Bhutan",
    "Bolivia",
    "Bosnia and Herzegovina",
    "Botswana",
    "Brazil",
    "Brunei",
    "Bulgaria",
    "Burkina Faso",
    "Burundi",
    "Cabo Verde",
    "Cambodia",
    "Cameroon",
    "Canada",
    "Central African Republic",
    "Chad",
    "Chile",
    "China",
    "Colombia",
    "Comoros",
    "Congo (Congo-Brazzaville)",
    "Congo (Democratic Republic)",
    "Costa Rica",
    "Croatia",
    "Cuba",
    "Cyprus",
    "Czech Republic",
    "Denmark",
    "Djibouti",
    "Dominica",
    "Dominican Republic",
    "Ecuador",
    "Egypt",
    "El Salvador",
    "Equatorial Guinea",
    "Eritrea",
    "Estonia",
    "Eswatini",
    "Ethiopia",
    "Fiji",
    "Finland",
    "France",
    "Gabon",
    "Gambia",
    "Georgia",
    "Germany",
    "Ghana",
    "Greece",
    "Grenada",
    "Guatemala",
    "Guinea",
    "Guinea-Bissau",
    "Guyana",
    "Haiti",
    "Honduras",
    "Hungary",
    "Iceland",
    "India",
    "Indonesia",
    "Iran",
    "Iraq",
    "Ireland",
    "Israel",
    "Italy",
    "Jamaica",
    "Japan",
    "Jordan",
    "Kazakhstan",
    "Kenya",
    "Kiribati",
    "Korea, North",
    "Korea, South",
    "Kuwait",
    "Kyrgyzstan",
    "Laos",
    "Latvia",
    "Lebanon",
    "Lesotho",
    "Liberia",
    "Libya",
    "Liechtenstein",
    "Lithuania",
    "Luxembourg",
    "Madagascar",
    "Malawi",
    "Malaysia",
    "Maldives",
    "Mali",
    "Malta",
    "Marshall Islands",
    "Mauritania",
    "Mauritius",
    "Mexico",
    "Micronesia",
    "Moldova",
    "Monaco",
    "Mongolia",
    "Montenegro",
    "Morocco",
    "Mozambique",
    "Myanmar (Burma)",
    "Namibia",
    "Nauru",
    "Nepal",
    "Netherlands",
    "New Zealand",
    "Nicaragua",
    "Niger",
    "Nigeria",
    "North Macedonia",
    "Norway",
    "Oman",
    "Pakistan",
    "Palau",
    "Panama",
    "Papua New Guinea",
    "Paraguay",
    "Peru",
    "Philippines",
    "Poland",
    "Portugal",
    "Qatar",
    "Romania",
    "Russia",
    "Rwanda",
    "Saint Kitts and Nevis",
    "Saint Lucia",
    "Saint Vincent and the Grenadines",
    "Samoa",
    "San Marino",
    "Sao Tome and Principe",
    "Saudi Arabia",
    "Senegal",
    "Serbia",
    "Seychelles",
    "Sierra Leone",
    "Singapore",
    "Slovakia",
    "Slovenia",
    "Solomon Islands",
    "Somalia",
    "South Africa",
    "South Sudan",
    "Spain",
    "Sri Lanka",
    "Sudan",
    "Suriname",
    "Sweden",
    "Switzerland",
    "Syria",
    "Taiwan",
    "Tajikistan",
    "Tanzania",
    "Thailand",
    "Togo",
    "Tonga",
    "Trinidad and Tobago",
    "Tunisia",
    "Turkey",
    "Turkmenistan",
    "Tuvalu",
    "Uganda",
    "Ukraine",
    "United Arab Emirates",
    "United Kingdom",
    "United States of America",
    "Uruguay",
    "Uzbekistan",
    "Vanuatu",
    "Vatican City",
    "Venezuela",
    "Vietnam",
    "Yemen",
    "Zambia",
    "Zimbabwe"
  ];

  List<String> filteredStates = [];

  final _formKey = GlobalKey<FormState>();

  File? imageFileOfUser;

  String password = ''; // Initialize the password variable
  bool showPassword = false; // Initialize the showPassword flag

  void toggleShowPassword() {
    setState(() {
      showPassword = !showPassword; // Toggle the showPassword flag
    });
  }

  // Function to filter countries based on search input
  void filterCountries() {
    setState(() {
      filteredCountries = countries
          .where((country) => country
              .toLowerCase()
              .contains(_countrySearchController.text.toLowerCase()))
          .toList();
    });
  }

  // Function to filter states based on search input
  void filterStates(String query) {
    if (selectedCountry != null) {
      setState(() {
        filteredStates = countryStateMap[selectedCountry]!
            .where((state) => state.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  // Function to show country selection dialog
  void showCountryDialog() {
  showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          // Filter countries based on the search query
          final filteredCountries = countries.where((country) {
            return _countrySearchController.text.isEmpty ||
                country
                    .toLowerCase()
                    .contains(_countrySearchController.text.toLowerCase());
          }).toList();

          return AlertDialog(
            title: Text('Select Country'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _countrySearchController,
                  decoration: InputDecoration(hintText: 'Search country'),
                  onChanged: (query) {
                    setDialogState(() {}); // Rebuild dialog when search changes
                  },
                ),
                SizedBox(
                  height: 300, // fixed height instead of Expanded
                  child: ListView(
                    children: filteredCountries.map((country) {
                      return ListTile(
                        title: Text(country),
                        onTap: () {
                          setState(() {
                            selectedCountry = country;
                            _stateSearchController.clear(); // clear state search when changing country
                            selectedState = null;
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


  void showStateDialog() {
  if (selectedCountry == null) return;

  showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final filteredStates = countryStateMap[selectedCountry]!.where((state) {
            return _stateSearchController.text.isEmpty ||
                state
                    .toLowerCase()
                    .contains(_stateSearchController.text.toLowerCase());
          }).toList();

          return AlertDialog(
            title: Text('Select State'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _stateSearchController,
                  decoration: InputDecoration(hintText: 'Search state'),
                  onChanged: (query) {
                    setDialogState(() {});
                  },
                ),
                SizedBox(
                  height: 300,
                  child: ListView(
                    children: filteredStates.map((state) {
                      return ListTile(
                        title: Text(state),
                        onTap: () {
                          setState(() {
                            selectedState = state;
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white,
              ],
              begin: FractionalOffset(0, 0),
              end: FractionalOffset(1, 0),
              stops: [0, 1],
              tileMode: TileMode.clamp,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.white,
              Colors.white,
              Colors.black12,
            ],
          ),
        ),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 30.0, right: 20.0),
              child: const Text(
                "Get Started!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 25.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30.0, right: 20.0),
              child: const Text(
                "Create an account to continue.",
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 0.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'Email',
                          labelStyle:
                              TextStyle(color: Colors.black, fontSize: 15),
                          prefixIcon: Icon(Icons.email),
                        ),
                        //  style: const TextStyle(
                        // fontSize: 24,
                        // ),
                        controller: _emailTextController,
                        validator: (valueEmail) {
                          if (!valueEmail!.contains("@")) {
                            return "kindly enter valid email";
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 26.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'Password',
                          labelStyle:
                              TextStyle(color: Colors.black, fontSize: 15),
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.visibility_off),
                            selectedIcon: const Icon(Icons.visibility),
                            onPressed: toggleShowPassword,
                            // _textFocusNode.requestFocus();
                            // handlePressed(controller);
                          ),
                        ),
                        obscureText: !showPassword,
                        controller: _passwordTextController,
                        validator: (valuePassword) {
                          if (valuePassword!.length < 5) {
                            return "Password must be at least 6 or more characters.";
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            password =
                                value; // Update the password when input changes
                          });
                        },
                      ),
                    ),
                    Text(
                      "password must be at least 6 or more characters",
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                        fontSize: 12.0,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 26.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'First Name',
                          labelStyle:
                              TextStyle(color: Colors.black, fontSize: 15),
                          prefixIcon: Icon(Icons.person),
                        ),
                        //  style: const TextStyle(
                        // fontSize: 24,
                        // ),
                        controller: _firstNameTextController,
                        validator: (text) {
                          if (text!.isEmpty) {
                            return "please enter first name";
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 26.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'Last Name',
                          labelStyle:
                              TextStyle(color: Colors.black, fontSize: 15),
                          prefixIcon: Icon(Icons.person),
                        ),
                        //  style: const TextStyle(
                        // fontSize: 24,
                        // ),
                        controller: _lastNameTextController,
                        validator: (text) {
                          if (text!.isEmpty) {
                            return "please enter last name";
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    // Ensure this import is present

                    Padding(
                      padding: const EdgeInsets.only(top: 26.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'Mobile Number',
                          labelStyle:
                              TextStyle(color: Colors.black, fontSize: 15),
                          prefixIcon: Icon(Icons.call),
                        ),
                        controller: _mobileNumberTextController,
                        validator: (text) {
                          if (text!.isEmpty) {
                            return "Please enter a mobile number";
                          } else if (text.length < 10) {
                            return "Please enter a valid mobile number";
                          }
                          return null;
                        },
                        //textCapitalization: TextCapitalization.none,
                        keyboardType:
                            TextInputType.phone, // Shows numeric keyboard
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter
                              .digitsOnly, // Only allows digits
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 26.0),
                      child: GestureDetector(
                        onTap: showCountryDialog,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'Country',
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            controller:
                                TextEditingController(text: selectedCountry),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 26.0),
                      child: GestureDetector(
                        onTap: showStateDialog,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              labelText: 'State',
                              prefixIcon: Icon(Icons.place),
                            ),
                            controller:
                                TextEditingController(text: selectedState),
                          ),
                        ),
                      ),
                    ),
                    Padding(
  padding: const EdgeInsets.only(top: 26.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide(color: Colors.black),
          ),
          filled: true,
          fillColor: Colors.white,
          labelText: 'Bio',
          labelStyle: TextStyle(color: Colors.black, fontSize: 15),
          prefixIcon: Icon(Icons.person_2),
        ),
        controller: _bioTextController,
        validator: (text) {
          if (text!.isEmpty) {
            return "Please enter bio";
          }
          return null;
        },
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: 2),
      Row(
        children: const [
          Icon(Icons.info_outline, color: Colors.pinkAccent, size: 18),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Your bio helps others know you better',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    ],
  ),
)

                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                var imageFile =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (imageFile != null) {
                  imageFileOfUser = File(imageFile.path); // Save the image file

                  setState(() {
                    // Trigger UI update when a new image is selected
                  });
                }
              },
              child: CircleAvatar(
                radius: MediaQuery.of(context).size.width *
                    0.10, // Adjust size as needed
                backgroundColor: Colors.grey,
                child: imageFileOfUser == null
                    ? Icon(
                        Icons.add_photo_alternate_sharp,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width *
                            0.10, // Adjust size of the icon
                      )
                    : ClipOval(
                        child: Image.file(
                          imageFileOfUser!,
                          width: MediaQuery.of(context).size.width *
                              0.20, // Adjust the size of the image
                          height: MediaQuery.of(context).size.width * 0.20,
                          fit: BoxFit
                              .cover, // Ensure the image covers the circle
                        ),
                      ),
              ),
            ),

            //keeping for tabs
            //  Padding(
            //    padding: const EdgeInsets.only(top: 22.0),
            //    child: MaterialButton(
            //      onPressed: () async {
            //        var imageFile = await ImagePicker()
            //            .pickImage(source: ImageSource.gallery);
            //        if (imageFile != null) {
            //        imageFileOfUser = File(imageFile.path);

            //        setState(() {
            //          imageFileOfUser;
            //        });
            //      }
            //      },
            //    child: imageFileOfUser == null
            //      ? const Icon(Icons.add_a_photo_rounded)
            //      : CircleAvatar(
            //         backgroundColor: Colors.grey,
            //          radius: MediaQuery.of(context).size.width / 20.0,
            //        child: CircleAvatar(
            //           backgroundImage: FileImage(imageFileOfUser!),
            //          radius: MediaQuery.of(context).size.width / 20.0,
            //         )),
            // ),
            //),
            //end of tabs
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: Color(0xff000000),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate() ||
                        imageFileOfUser == null) {
                      Get.snackbar("field missing",
                          "Please choose image and complete form");
                      return;
                    }
                    if (_emailTextController.text.isEmpty &&
                        _passwordTextController.text.isEmpty) {
                      Get.snackbar("field missing", "Please complete form");
                      return;
                    }
                    userViewModel.signUp(
                      _emailTextController.text.trim(),
                      _passwordTextController.text.trim(),
                      _firstNameTextController.text.trim(),
                      _lastNameTextController.text.trim(),
                      selectedCountry,
                      selectedState,
                      _mobileNumberTextController.text.trim(),
                      _bioTextController.text.trim(),
                      imageFileOfUser,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: const Text(
                    "submit",
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 25.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
