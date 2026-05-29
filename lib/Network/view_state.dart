
import 'package:flutter/material.dart';

import '../Shared/widgets/states_widgets/emtpy_widget.dart';
import '../Shared/widgets/states_widgets/error_loading_widget.dart';
import '../Shared/widgets/states_widgets/loader_widget.dart';

enum ViewState { initial, loading, empty, error, loaded, submit }

extension ViewStateHandling on ViewState {
  Widget handleViewState({
    required void Function() fetchRequest,
    required String emptyMessage,
    required Widget child,
    bool showLoading = true,
  }) {
    switch (this) {
      case ViewState.initial:
        fetchRequest();
        return showLoading ? LoaderWidget() : Container();

      case ViewState.loading:
        return showLoading ? LoaderWidget() : Container();

      case ViewState.empty:
        return EmptyWidget(text: emptyMessage);

      case ViewState.error:
        return const ErrorLoadingWidget();

      default:
        return child;
    }
  }
}
