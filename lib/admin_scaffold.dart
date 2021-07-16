import 'package:flutter/material.dart';

import 'src/side_bar.dart';

export 'src/menu_item.dart';
export 'src/side_bar.dart';

class SidebarController extends ChangeNotifier {
  bool? open;

  void openSidebar() {
    open = true;
    notifyListeners();
  }

  void closeSidebar() {
    open = false;
    notifyListeners();
  }
}

class AdminScaffold extends StatefulWidget {
  AdminScaffold({
    Key? key,
    this.appBar,
    this.sideBar,
    required this.body,
    this.backgroundColor,
    this.onSidebarState,
    this.sidebarController,
  }) : super(key: key);

  final AppBar? appBar;
  final SideBar? sideBar;
  final Widget body;
  final Color? backgroundColor;
  final Function(Map<String, dynamic>)? onSidebarState;
  final SidebarController? sidebarController;

  @override
  _AdminScaffoldState createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> with SingleTickerProviderStateMixin {
  static const _mobileThreshold = 768.0;

  late AnimationController _animationController;
  late Animation _animation;
  bool _isMobile = false;
  bool _isOpenSidebar = false;
  bool _canDragged = false;

  @override
  void initState() {
    super.initState();
    SidebarController? _sidebarController = widget.sidebarController;
    if (_sidebarController != null) {
      _sidebarController.addListener(() {
        if (_sidebarController.open == true)
          openSidebar();
        else
          closeSidebar();
      });
    }
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutQuad,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    setState(() {
      _isMobile = mediaQuery.size.width < _mobileThreshold;
      _isOpenSidebar = !_isMobile;
      _animationController.value = _isMobile ? 0 : 1;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void updateSidebarState(String state) {
    if (widget.onSidebarState != null) widget.onSidebarState!({'state': state, 'layout': _isMobile ? 'mobile' : 'web'});
  }

  void openSidebar() {
    setState(() {
      _isOpenSidebar = true;
      _animationController.forward();
      updateSidebarState('opened');
    });
  }

  void closeSidebar() {
    setState(() {
      _isOpenSidebar = false;
      _animationController.reverse();
      updateSidebarState('closed');
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isOpenSidebar = !_isOpenSidebar;
      if (_isOpenSidebar) {
        _animationController.forward();
        updateSidebarState('opened');
      } else {
        _animationController.reverse();
        updateSidebarState('closed');
      }
    });
  }

  void _onDragStart(DragStartDetails details) {
    final isClosed = _animationController.isDismissed;
    final isOpen = _animationController.isCompleted;
    _canDragged = (isClosed && details.globalPosition.dx < 60) || isOpen;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_canDragged) {
      final delta = (details.primaryDelta ?? 0.0) / (widget.sideBar?.width ?? 1.0);
      _animationController.value += delta;
    }
  }

  void _dragCloseDrawer(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0.0;
    if (delta < 0) {
      _isOpenSidebar = false;
      _animationController.reverse();
      updateSidebarState('closed');
    }
  }

  void _onDragEnd(DragEndDetails details) async {
    final minFlingVelocity = 365.0;

    if (details.velocity.pixelsPerSecond.dx.abs() >= minFlingVelocity) {
      final visualVelocity = details.velocity.pixelsPerSecond.dx / (widget.sideBar?.width ?? 1.0);

      await _animationController.fling(velocity: visualVelocity);
      if (_animationController.isCompleted) {
        setState(() {
          _isOpenSidebar = true;
        });
        updateSidebarState('opened');
      } else {
        setState(() {
          _isOpenSidebar = false;
        });
        updateSidebarState('closed');
      }
    } else {
      if (_animationController.value < 0.5) {
        _animationController.reverse();
        setState(() {
          _isOpenSidebar = false;
        });
        updateSidebarState('closed');
      } else {
        _animationController.forward();
        setState(() {
          _isOpenSidebar = true;
        });
        updateSidebarState('opened');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: _buildAppBar(widget.appBar, widget.sideBar),
      body: AnimatedBuilder(
        animation: _animation,
        builder: (_, __) => widget.sideBar == null
            ? Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: widget.body,
                    ),
                  ),
                ],
              )
            : _isMobile
                ? Stack(
                    children: [
                      GestureDetector(
                        onHorizontalDragStart: _onDragStart,
                        onHorizontalDragUpdate: _onDragUpdate,
                        onHorizontalDragEnd: _onDragEnd,
                      ),
                      widget.body,
                      if (_animation.value > 0)
                        Container(
                          color: Colors.black.withAlpha((150 * _animation.value).toInt()),
                        ),
                      if (_animation.value == 1)
                        GestureDetector(
                          onTap: _toggleSidebar,
                          onHorizontalDragUpdate: _dragCloseDrawer,
                        ),
                      ClipRect(
                        child: SizedOverflowBox(
                          size: Size((widget.sideBar?.width ?? 1.0) * _animation.value, double.infinity),
                          child: widget.sideBar,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      widget.sideBar != null
                          ? ClipRect(
                              child: SizedOverflowBox(
                                size: Size((widget.sideBar?.width ?? 1.0) * _animation.value, double.infinity),
                                child: widget.sideBar,
                              ),
                            )
                          : SizedBox(),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: widget.body,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  AppBar? _buildAppBar(AppBar? appBar, SideBar? sideBar) {
    if (appBar == null) {
      return null;
    }

    final leading = sideBar != null
        ? IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _toggleSidebar,
          )
        : appBar.leading;
    final centerTitle = false;
    final shadowColor = Colors.transparent;

    return AppBar(
      leading: leading,
      automaticallyImplyLeading: appBar.automaticallyImplyLeading,
      title: appBar.title,
      actions: appBar.actions,
      flexibleSpace: appBar.flexibleSpace,
      bottom: appBar.bottom,
      elevation: appBar.elevation,
      shadowColor: shadowColor,
      shape: appBar.shape,
      backgroundColor: appBar.backgroundColor,
      brightness: appBar.brightness,
      iconTheme: appBar.iconTheme,
      actionsIconTheme: appBar.actionsIconTheme,
      textTheme: appBar.textTheme,
      primary: appBar.primary,
      centerTitle: centerTitle,
      excludeHeaderSemantics: appBar.excludeHeaderSemantics,
      titleSpacing: appBar.titleSpacing,
      toolbarOpacity: appBar.toolbarOpacity,
      bottomOpacity: appBar.bottomOpacity,
      toolbarHeight: appBar.toolbarHeight,
      leadingWidth: appBar.leadingWidth,
    );
  }
}
