// bizorganizer/lib/utils/us_states_data.dart

// Represents a US State with its name and abbreviation.
class USState {
  final String name;
  final String abbr;

  const USState({required this.name, required this.abbr});

  // Optional: for easier use in DropdownButtonFormField if objects are preferred over Maps
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is USState && runtimeType == other.runtimeType && abbr == other.abbr;

  @override
  int get hashCode => abbr.hashCode;
}

const List<USState> usStatesAndAbbreviations = [
  USState(name: 'Alabama', abbr: 'AL'),
  USState(name: 'Alaska', abbr: 'AK'),
  USState(name: 'Arizona', abbr: 'AZ'),
  USState(name: 'Arkansas', abbr: 'AR'),
  USState(name: 'California', abbr: 'CA'),
  USState(name: 'Colorado', abbr: 'CO'),
  USState(name: 'Connecticut', abbr: 'CT'),
  USState(name: 'Delaware', abbr: 'DE'),
  USState(name: 'Florida', abbr: 'FL'),
  USState(name: 'Georgia', abbr: 'GA'),
  USState(name: 'Hawaii', abbr: 'HI'),
  USState(name: 'Idaho', abbr: 'ID'),
  USState(name: 'Illinois', abbr: 'IL'),
  USState(name: 'Indiana', abbr: 'IN'),
  USState(name: 'Iowa', abbr: 'IA'),
  USState(name: 'Kansas', abbr: 'KS'),
  USState(name: 'Kentucky', abbr: 'KY'),
  USState(name: 'Louisiana', abbr: 'LA'),
  USState(name: 'Maine', abbr: 'ME'),
  USState(name: 'Maryland', abbr: 'MD'),
  USState(name: 'Massachusetts', abbr: 'MA'),
  USState(name: 'Michigan', abbr: 'MI'),
  USState(name: 'Minnesota', abbr: 'MN'),
  USState(name: 'Mississippi', abbr: 'MS'),
  USState(name: 'Missouri', abbr: 'MO'),
  USState(name: 'Montana', abbr: 'MT'),
  USState(name: 'Nebraska', abbr: 'NE'),
  USState(name: 'Nevada', abbr: 'NV'),
  USState(name: 'New Hampshire', abbr: 'NH'),
  USState(name: 'New Jersey', abbr: 'NJ'),
  USState(name: 'New Mexico', abbr: 'NM'),
  USState(name: 'New York', abbr: 'NY'),
  USState(name: 'North Carolina', abbr: 'NC'),
  USState(name: 'North Dakota', abbr: 'ND'),
  USState(name: 'Ohio', abbr: 'OH'),
  USState(name: 'Oklahoma', abbr: 'OK'),
  USState(name: 'Oregon', abbr: 'OR'),
  USState(name: 'Pennsylvania', abbr: 'PA'),
  USState(name: 'Rhode Island', abbr: 'RI'),
  USState(name: 'South Carolina', abbr: 'SC'),
  USState(name: 'South Dakota', abbr: 'SD'),
  USState(name: 'Tennessee', abbr: 'TN'),
  USState(name: 'Texas', abbr: 'TX'),
  USState(name: 'Utah', abbr: 'UT'),
  USState(name: 'Vermont', abbr: 'VT'),
  USState(name: 'Virginia', abbr: 'VA'),
  USState(name: 'Washington', abbr: 'WA'),
  USState(name: 'West Virginia', abbr: 'WV'),
  USState(name: 'Wisconsin', abbr: 'WI'),
  USState(name: 'Wyoming', abbr: 'WY'),
  // Consider adding District of Columbia, Puerto Rico, etc. if relevant
];

// Optional: Helper function to get a state name from an abbreviation, useful for stats page
String getUSStateNameFromAbbr(String? abbr) {
  if (abbr == null) return 'N/A';
  try {
    return usStatesAndAbbreviations.firstWhere((state) => state.abbr.toLowerCase() == abbr.toLowerCase()).name;
  } catch (e) {
    return abbr; // Return abbr if not found
  }
}

// Optional: Helper function to get a USState object from an abbreviation
USState? getUSStateFromAbbr(String? abbr) {
  if (abbr == null) return null;
  try {
    return usStatesAndAbbreviations.firstWhere((state) => state.abbr.toLowerCase() == abbr.toLowerCase());
  } catch (e) {
    return null;
  }
}
