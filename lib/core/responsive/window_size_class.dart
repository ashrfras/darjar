enum WindowSizeClass { compact, medium, expanded }

WindowSizeClass windowSizeClassFor(double width) {
  if (width < 600) {
    return WindowSizeClass.compact;
  }
  if (width < 1024) {
    return WindowSizeClass.medium;
  }
  return WindowSizeClass.expanded;
}
