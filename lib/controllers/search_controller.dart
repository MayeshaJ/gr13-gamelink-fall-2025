import 'dart:async';

/// Immutable search/filter state for the game list.
/// - query: free-text query (matches title/hostName in later commits)
/// - selectedSports: set of selected sport types (e.g., 'football', 'basketball')
class SearchState {
  final String query;
  final Set<String> selectedSports;

  const SearchState({
    this.query = '',
    this.selectedSports = const <String>{},
  });

  SearchState copyWith({
    String? query,
    Set<String>? selectedSports,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedSports: selectedSports ?? this.selectedSports,
    );
  }
}

/// Simple controller that holds search/filter state and exposes a stream.
/// Integration into views is part of later commits.
class SearchController {
  SearchController._internal();
  static final SearchController instance = SearchController._internal();

  final StreamController<SearchState> _stateController =
      StreamController<SearchState>.broadcast();

  SearchState _state = const SearchState();

  /// Current state snapshot.
  SearchState get state => _state;

  /// Listen for state updates.
  Stream<SearchState> watch() => _stateController.stream;

  void updateQuery(String query) {
    _update(_state.copyWith(query: query));
  }

  /// Replace the entire selected sports set.
  void setSelectedSports(Set<String> sports) {
    _update(_state.copyWith(selectedSports: Set<String>.from(sports)));
  }

  /// Toggle a single sport (case-sensitive; normalize at call site if needed).
  void toggleSport(String sport) {
    final Set<String> next = Set<String>.from(_state.selectedSports);
    if (next.contains(sport)) {
      next.remove(sport);
    } else {
      next.add(sport);
    }
    _update(_state.copyWith(selectedSports: next));
  }

  /// Clear all filters but keep the current query.
  void clearFilters() {
    _update(_state.copyWith(selectedSports: <String>{}));
  }

  /// Reset both query and filters.
  void reset() {
    _update(const SearchState());
  }

  void _update(SearchState next) {
    _state = next;
    _stateController.add(_state);
  }
}


