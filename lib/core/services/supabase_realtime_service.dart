import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

typedef RealtimeChangeCallback = void Function(PostgresChangePayload payload);
typedef RealtimeResyncCallback = void Function();

/// Unique token returned when a listener subscribes.
/// Used to cancel a specific listener safely without tearing down the channel
/// if other components are still listening to the same channel.
class RealtimeSubscriptionToken {
  final String channelKey;
  final String listenerId;

  const RealtimeSubscriptionToken({
    required this.channelKey,
    required this.listenerId,
  });

  /// Cancels this subscription safely.
  void cancel() {
    SupabaseRealtimeService.instance.cancelSubscription(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealtimeSubscriptionToken &&
          runtimeType == other.runtimeType &&
          channelKey == other.channelKey &&
          listenerId == other.listenerId;

  @override
  int get hashCode => channelKey.hashCode ^ listenerId.hashCode;
}

class _ChannelListener {
  final String id;
  final RealtimeChangeCallback onData;
  final RealtimeResyncCallback? onResync;

  _ChannelListener({
    required this.id,
    required this.onData,
    this.onResync,
  });
}

class _ManagedChannel {
  final String key;
  final RealtimeChannel channel;
  final Map<String, _ChannelListener> listeners = {};
  bool isSubscribed = false;
  bool isDisposed = false;

  _ManagedChannel({
    required this.key,
    required this.channel,
  });
}

/// Centralized, production-grade Supabase Realtime Service for Lamma.
/// Features:
/// - Single WebSocket channel per topic (prevents duplicate connections)
/// - Multi-listener dispatching per channel
/// - Automatic lifecycle cleanup and subscription reference counting
/// - Reconnection and resynchronization triggers (for recovering missed events)
/// - Idempotent, safe, and clean error handling
class SupabaseRealtimeService {
  static final SupabaseRealtimeService _instance =
      SupabaseRealtimeService._internal();

  factory SupabaseRealtimeService() => _instance;
  static SupabaseRealtimeService get instance => _instance;

  SupabaseRealtimeService._internal() {
    _initAuthListener();
  }

  void _initAuthListener() {
    if (!isReady) return;
    try {
      _client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        final token = session?.accessToken;
        if (token != null) {
          try {
            _client.realtime.setAuth(token);
            debugPrint('SupabaseRealtime: Synced WebSocket token for ${data.event}');
          } catch (e) {
            debugPrint('SupabaseRealtime: Note on setAuth: $e');
          }
        }
      });
    } catch (_) {}
  }

  SupabaseClient get _client => SupabaseConfig.client;

  final Map<String, _ManagedChannel> _channels = {};
  final Map<String, void Function()> _reconnectListeners = {};
  int _listenerCounter = 0;

  /// Check whether Supabase client is initialized
  bool get isReady => SupabaseConfig.hasClient;

  // ========================================================
  // Generic Subscription Engine
  // ========================================================

  /// Register a callback to be called whenever any channel reconnects after drop
  RealtimeSubscriptionToken onReconnected(void Function() callback) {
    final listenerId = 'rec_${++_listenerCounter}';
    _reconnectListeners[listenerId] = callback;
    return RealtimeSubscriptionToken(
      channelKey: 'system_reconnect',
      listenerId: listenerId,
    );
  }

  /// Convenience wrapper supporting onInserted, onUpdated, onDeleted and string filters (e.g. "user_id=eq.123")
  RealtimeSubscriptionToken subscribeTable({
    required String table,
    String schema = 'public',
    String? filter,
    void Function(Map<String, dynamic> record)? onInserted,
    void Function(Map<String, dynamic> record)? onUpdated,
    void Function(Map<String, dynamic> record)? onDeleted,
    RealtimeResyncCallback? onResync,
  }) {
    PostgresChangeFilter? parsedFilter;
    if (filter != null && filter.contains('=')) {
      final parts = filter.split('=');
      final column = parts[0].trim();
      final opAndVal = parts[1].trim();
      if (opAndVal.startsWith('eq.')) {
        parsedFilter = PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: column,
          value: opAndVal.substring(3),
        );
      } else if (opAndVal.startsWith('neq.')) {
        parsedFilter = PostgresChangeFilter(
          type: PostgresChangeFilterType.neq,
          column: column,
          value: opAndVal.substring(4),
        );
      }
    }

    return subscribeToTable(
      table: table,
      schema: schema,
      filter: parsedFilter,
      onData: (payload) {
        final eventType = payload.eventType;
        if (eventType == PostgresChangeEvent.insert) {
          onInserted?.call(payload.newRecord);
        } else if (eventType == PostgresChangeEvent.update) {
          onUpdated?.call(payload.newRecord);
        } else if (eventType == PostgresChangeEvent.delete) {
          onDeleted?.call(payload.oldRecord);
        }
      },
      onResync: onResync,
    );
  }

  /// Subscribes to a Postgres table with an optional Postgres filter.
  /// Deduplicates channels: multiple callers with the same table/filter share
  /// a single RealtimeChannel under the hood.
  RealtimeSubscriptionToken subscribeToTable({
    required String table,
    String schema = 'public',
    PostgresChangeEvent event = PostgresChangeEvent.all,
    PostgresChangeFilter? filter,
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    if (!isReady) {
      debugPrint('SupabaseRealtimeService: Client not ready, skipping subscription for $table');
      return RealtimeSubscriptionToken(
        channelKey: 'uninitialized_$table',
        listenerId: 'none',
      );
    }

    final filterKey = filter != null
        ? '_${filter.column}_${filter.type.name}_${filter.value}'
        : '_all';
    final channelKey = 'rt_${schema}_${table}_${event.name}$filterKey';
    final listenerId = 'lis_${++_listenerCounter}';

    _ManagedChannel? managed = _channels[channelKey];

    if (managed == null) {
      final channel = _client.channel(channelKey);

      managed = _ManagedChannel(
        key: channelKey,
        channel: channel,
      );
      _channels[channelKey] = managed;

      channel.onPostgresChanges(
        event: event,
        schema: schema,
        table: table,
        filter: filter,
        callback: (payload) {
          final current = _channels[channelKey];
          if (current == null || current.isDisposed) return;

          // Dispatch to all active listeners on this channel
          final activeListeners = List<_ChannelListener>.from(current.listeners.values);
          for (final listener in activeListeners) {
            try {
              listener.onData(payload);
            } catch (err, st) {
              debugPrint('Error in Realtime listener for $channelKey: $err\n$st');
            }
          }
        },
      );

      // Subscribe and handle reconnection
      channel.subscribe((status, error) {
        if (managed == null || managed.isDisposed) return;

        if (status == RealtimeSubscribeStatus.subscribed) {
          final wasSubscribed = managed.isSubscribed;
          managed.isSubscribed = true;
          debugPrint('SupabaseRealtime: Subscribed to $channelKey');

          // If this was a reconnection after a drop, notify listeners to resync
          if (wasSubscribed) {
            debugPrint('SupabaseRealtime: Reconnected to $channelKey -> triggering resync');
            for (final listener in managed.listeners.values) {
              try {
                listener.onResync?.call();
              } catch (e) {
                debugPrint('Error in Realtime resync for $channelKey: $e');
              }
            }
            // Trigger global reconnect listeners
            for (final cb in _reconnectListeners.values) {
              try {
                cb();
              } catch (e) {
                debugPrint('Error in global reconnect callback: $e');
              }
            }
          }
        } else if (status == RealtimeSubscribeStatus.timedOut ||
            status == RealtimeSubscribeStatus.channelError) {
          managed.isSubscribed = false;
          debugPrint('SupabaseRealtime: Warning on $channelKey - status: $status, error: $error');
        } else if (status == RealtimeSubscribeStatus.closed) {
          managed.isSubscribed = false;
        }
      });
    }

    // Register listener on managed channel
    managed.listeners[listenerId] = _ChannelListener(
      id: listenerId,
      onData: onData,
      onResync: onResync,
    );

    return RealtimeSubscriptionToken(
      channelKey: channelKey,
      listenerId: listenerId,
    );
  }

  /// Cancels an individual listener.
  /// If no more listeners remain on the underlying channel, the channel is closed
  /// and removed to avoid memory leaks and unneeded WebSocket traffic.
  void cancelSubscription(RealtimeSubscriptionToken? token) {
    if (token == null) return;
    if (token.channelKey == 'system_reconnect') {
      _reconnectListeners.remove(token.listenerId);
      return;
    }

    final managed = _channels[token.channelKey];
    if (managed == null) return;

    managed.listeners.remove(token.listenerId);

    // If no listeners left, tear down the channel cleanly
    if (managed.listeners.isEmpty) {
      _teardownChannel(managed);
      _channels.remove(token.channelKey);
    }
  }

  void _teardownChannel(_ManagedChannel managed) {
    managed.isDisposed = true;
    managed.isSubscribed = false;
    try {
      _client.removeChannel(managed.channel);
      debugPrint('SupabaseRealtime: Removed channel ${managed.key}');
    } catch (e) {
      debugPrint('SupabaseRealtime: Note on removing channel ${managed.key}: $e');
    }
  }

  /// Close and remove a channel by key
  void unsubscribeChannel(String channelKey) {
    final managed = _channels.remove(channelKey);
    if (managed != null) {
      _teardownChannel(managed);
    }
  }

  /// Disposes all active Realtime subscriptions (e.g. on user logout)
  void disposeAll() {
    for (final managed in _channels.values) {
      _teardownChannel(managed);
    }
    _channels.clear();
    _reconnectListeners.clear();
    debugPrint('SupabaseRealtime: Disposed all channels');
  }

  // ========================================================
  // Domain-Specific Realtime Helper Subscriptions
  // ========================================================

  /// 1. Categories Realtime
  /// Listens for additions, updates, and deletions of categories.
  RealtimeSubscriptionToken subscribeToCategories({
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    return subscribeToTable(
      table: 'categories',
      onData: onData,
      onResync: onResync,
    );
  }

  /// 2. Services Realtime
  /// Listens for additions, updates (price, active/paused), and deletions.
  /// If providerId is given, only filters events for that provider.
  RealtimeSubscriptionToken subscribeToServices({
    String? providerId,
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    PostgresChangeFilter? filter;
    if (providerId != null && providerId.isNotEmpty) {
      filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'provider_id',
        value: providerId,
      );
    }

    return subscribeToTable(
      table: 'services',
      filter: filter,
      onData: onData,
      onResync: onResync,
    );
  }

  /// 3. Bookings Realtime
  /// Listens for new bookings, status changes, cancellations, and completions.
  RealtimeSubscriptionToken subscribeToBookings({
    String? customerId,
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    // Note: Supabase RLS already enforces that users can only receive their own bookings.
    // Subscribing to the table directly ensures that UPDATE and status changes
    // are never dropped due to filter matching issues on modified columns.
    return subscribeToTable(
      table: 'bookings',
      onData: onData,
      onResync: onResync,
    );
  }

  /// 4. Booking Items Realtime
  /// Listens for individual service acceptance / rejection in bookings.
  RealtimeSubscriptionToken subscribeToBookingItems({
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    return subscribeToTable(
      table: 'booking_items',
      onData: onData,
      onResync: onResync,
    );
  }

  /// 5. Notifications Realtime
  /// Listens for newly inserted notifications and read-state updates for a specific user.
  RealtimeSubscriptionToken subscribeToNotifications({
    required String userId,
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    return subscribeToTable(
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      onData: onData,
      onResync: onResync,
    );
  }

  /// 6. Favorites Realtime
  /// Listens for additions and removals of favorites for a specific user.
  RealtimeSubscriptionToken subscribeToFavorites({
    required String userId,
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    return subscribeToTable(
      table: 'favorites',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      onData: onData,
      onResync: onResync,
    );
  }

  /// 7. Provider Profiles Realtime
  /// Listens for provider status changes (pending -> approved -> rejected).
  RealtimeSubscriptionToken subscribeToProviderProfiles({
    String? userId,
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    PostgresChangeFilter? filter;
    if (userId != null && userId.isNotEmpty) {
      filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      );
    }

    return subscribeToTable(
      table: 'provider_profiles',
      filter: filter,
      onData: onData,
      onResync: onResync,
    );
  }

  /// 8. Provider Applications Realtime
  /// Listens for newly submitted applications or status reviews.
  RealtimeSubscriptionToken subscribeToProviderApplications({
    String? userId,
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    PostgresChangeFilter? filter;
    if (userId != null && userId.isNotEmpty) {
      filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      );
    }

    return subscribeToTable(
      table: 'provider_applications',
      filter: filter,
      onData: onData,
      onResync: onResync,
    );
  }

  /// 9. Reviews Realtime
  /// Listens for new reviews and ratings updates.
  RealtimeSubscriptionToken subscribeToReviews({
    String? serviceId,
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    PostgresChangeFilter? filter;
    if (serviceId != null && serviceId.isNotEmpty) {
      filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'service_id',
        value: serviceId,
      );
    }

    return subscribeToTable(
      table: 'reviews',
      filter: filter,
      onData: onData,
      onResync: onResync,
    );
  }

  /// 10. Complaints Realtime
  RealtimeSubscriptionToken subscribeToComplaints({
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    return subscribeToTable(
      table: 'complaints',
      onData: onData,
      onResync: onResync,
    );
  }

  /// 11. User Profiles Realtime
  RealtimeSubscriptionToken subscribeToProfiles({
    String? userId,
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    PostgresChangeFilter? filter;
    if (userId != null && userId.isNotEmpty) {
      filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: userId,
      );
    }

    return subscribeToTable(
      table: 'profiles',
      filter: filter,
      onData: onData,
      onResync: onResync,
    );
  }

  /// 12. Booking Status History Realtime
  /// Listens for booking lifecycle audit events (old_status -> new_status transitions)
  RealtimeSubscriptionToken subscribeToBookingStatusHistory({
    String? bookingId,
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    PostgresChangeFilter? filter;
    if (bookingId != null && bookingId.isNotEmpty) {
      filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'booking_id',
        value: bookingId,
      );
    }

    return subscribeToTable(
      table: 'booking_status_history',
      filter: filter,
      onData: onData,
      onResync: onResync,
    );
  }

  /// 13. Service Availability Realtime
  RealtimeSubscriptionToken subscribeToServiceAvailability({
    String? serviceId,
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    PostgresChangeFilter? filter;
    if (serviceId != null && serviceId.isNotEmpty) {
      filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'service_id',
        value: serviceId,
      );
    }

    return subscribeToTable(
      table: 'service_availability',
      filter: filter,
      onData: onData,
      onResync: onResync,
    );
  }

  /// 14. Complaint Categories Realtime
  RealtimeSubscriptionToken subscribeToComplaintCategories({
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    return subscribeToTable(
      table: 'complaint_categories',
      onData: onData,
      onResync: onResync,
    );
  }
}
