import 'dart:async';
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

/// Centralized, production-grade Supabase Realtime Service for Lamma Customer App.
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

  SupabaseRealtimeService._internal();

  SupabaseClient get _client => SupabaseConfig.client;

  final Map<String, _ManagedChannel> _channels = {};
  int _listenerCounter = 0;

  /// Check whether Supabase client is initialized
  bool get isReady => SupabaseConfig.isConfigured;

  // ========================================================
  // Generic Subscription Engine
  // ========================================================

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
      debugPrint('SupabaseRealtimeService: Client not configured, skipping subscription for $table');
      return RealtimeSubscriptionToken(
        channelKey: 'unconfigured_$table',
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
    debugPrint('SupabaseRealtime: Disposed all channels');
  }

  // ========================================================
  // Domain-Specific Realtime Helper Subscriptions
  // ========================================================

  /// 1. Categories Realtime
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
  RealtimeSubscriptionToken subscribeToServices({
    String? categoryId,
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    PostgresChangeFilter? filter;
    if (categoryId != null && categoryId.isNotEmpty) {
      filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'category_id',
        value: categoryId,
      );
    }

    return subscribeToTable(
      table: 'services',
      filter: filter,
      onData: onData,
      onResync: onResync,
    );
  }

  /// 3. Customer Bookings Realtime
  RealtimeSubscriptionToken subscribeToMyBookings({
    required String customerId,
    required RealtimeChangeCallback onData,
    RealtimeResyncCallback? onResync,
  }) {
    return subscribeToTable(
      table: 'bookings',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'customer_id',
        value: customerId,
      ),
      onData: onData,
      onResync: onResync,
    );
  }

  /// 4. Booking Items Realtime
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

  /// 5. Customer Notifications Realtime
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

  /// 6. Customer Favorites Realtime
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

  /// 7. Reviews Realtime
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
}
