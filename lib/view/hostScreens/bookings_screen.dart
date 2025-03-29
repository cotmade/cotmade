import 'package:cotmade/model/app_constants.dart';
import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/widgets/calendar_ui.dart';
import 'package:cotmade/view/widgets/posting_list_tile_ui.dart';
import 'package:flutter/material.dart';
import 'package:cotmade/view/hostScreens/Guests_Screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<DateTime> _bookedDates = [];
  List<DateTime> _allBookedDates = [];
  PostingModel? _selectedPosting;

  List<DateTime> _getSelectedDates() {
    return [];
  }

  _selectDate(DateTime date) {}

  _selectAPosting(PostingModel posting) {
    setState(() {
      _selectedPosting = posting;
      _bookedDates = posting.getAllBookedDates(); // Update booked dates
    });
  }

  _clearSelectedPosting() {
    setState(() {
      _bookedDates = _allBookedDates;
      _selectedPosting = null; // Clear selected posting
    });
  }

  @override
  void initState() {
    super.initState();
    _bookedDates = AppConstants.currentUser.getAllBookedDates();
    _allBookedDates = AppConstants.currentUser.getAllBookedDates();
  }

  void _navigateToGuestsPage(PostingModel posting) {
    // Navigate to the GuestsPage and pass the selected posting.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuestsPage(posting: posting),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter out listings with status 0.0 and remove duplicates by ID
    var activePostings = AppConstants.currentUser.myPostings!
        .where((posting) => posting.status != 0)
        .toList();

    // Remove duplicates based on posting ID (use a Set to avoid duplicates)
    var uniquePostings = <PostingModel>[];
    var seenIds = <String?>{}; // Store seen posting IDs

    for (var posting in activePostings) {
      if (!seenIds.contains(posting.id)) {
        seenIds.add(posting.id);
        uniquePostings.add(posting);
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text('Sun'),
                  Text('Mon'),
                  Text('Tues'),
                  Text('Wed'),
                  Text('Thur'),
                  Text('Fri'),
                  Text('Sat'),
                ],
              ),

              // Calendar
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 1),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height / 2.5,
                  child: PageView.builder(
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      return CalenderUI(
                        monthIndex: index,
                        bookedDates: _bookedDates,
                        selectDate: _selectDate,
                        getSelectedDates: _getSelectedDates,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 0, 0, 5),
                child: Row(
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: const ColoredBox(color: Colors.pinkAccent),
                    ),
                    SizedBox(
                      width: 2,
                    ),
                    Text('-'),
                    SizedBox(
                      width: 2,
                    ),
                    Text('These dates have been booked'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 0, 0, 0),
                child: Row(
                  children: [
                    Text('Note:'),
                    SizedBox(
                      width: 2,
                    ),
                    Text('double click on a listing to see more details'),
                  ],
                ),
              ),
              // Reset
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 0, 0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter by Listing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    MaterialButton(
                      onPressed: () {
                        _clearSelectedPosting();
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 25, bottom: 25),
                      child: Container(),
                    ),
                  ],
                ),
              ),

              // Display host listings
              ListView.builder(
                shrinkWrap: true,
                physics: const ScrollPhysics(),
                itemCount: uniquePostings.length, // Use filtered postings
                itemBuilder: (context, index) {
                  var posting = uniquePostings[index];

                  // Use a key to ensure proper widget re-use
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 26.0),
                    child: GestureDetector(
                      onDoubleTap: () {
                        _navigateToGuestsPage(posting);
                      },
                      child: InkResponse(
                        onTap: () {
                          _selectAPosting(posting);
                        },
                        child: Container(
                          key: ValueKey(
                              posting.id), // Use a key based on posting ID
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedPosting == posting
                                  ? Colors.pinkAccent
                                  : Colors.black,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: PostingListTileUI(
                            posting: posting, // Use filtered postings
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
