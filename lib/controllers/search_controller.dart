import 'dart:async';

/// Immutable search state for the game list.
/// - query: free-text query (matches title/host/location/sport)
class SearchState {
  final String query;

  const SearchState({
    this.query = '',
  });

  SearchState copyWith({
    String? query,
  }) {
    return SearchState(
      query: query ?? this.query,
    );
  }
}

/// Simple controller that holds search/filter state and exposes a stream.
/// Integration into views is part of later commits.
class SearchController {
  SearchController._internal() {
    // Emit initial state immediately to prevent infinite loading
    _stateController.add(_state);
  }
  
  static final SearchController instance = SearchController._internal();

  final StreamController<SearchState> _stateController =
      StreamController<SearchState>.broadcast();

  SearchState _state = const SearchState();

  /// Current state snapshot.
  SearchState get state => _state;

  /// Listen for state updates.
  /// The stream will emit the current state and then any updates.
  Stream<SearchState> watch() {
    // Return the broadcast stream - initialData in StreamBuilder will handle initial state
    return _stateController.stream;
  }

  void updateQuery(String query) {
    _update(_state.copyWith(query: query));
  }

  /// Reset both query and filters.
  void reset() {
    _update(const SearchState());
  }

  void _update(SearchState next) {
    if (_state.query == next.query) {
      // No change, don't emit
      return;
    }
    _state = next;
    _stateController.add(_state);
  }
  
  void dispose() {
    _stateController.close();
  }
}


