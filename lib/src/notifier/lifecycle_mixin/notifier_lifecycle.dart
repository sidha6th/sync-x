part of '../base/base_notifier.dart';

/// A mixin that provides lifecycle hooks for notifiers.
///
/// Use this mixin to add initialization and disposal logic to notifiers.
/// Intended to be used with notifiers that require setup or cleanup, such as resource allocation or event listeners.
mixin NotifierLifecycle {
  void _initialize() {
    WidgetsBinding.instance.addPostFrameCallback((_) => onInit());
  }

  @protected

  /// Called when the notifier is initialized.
  /// Override this to perform setup logic.
  void onInit() {}
}
