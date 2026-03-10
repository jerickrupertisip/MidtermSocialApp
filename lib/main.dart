import "dart:convert";
import "dart:ui";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:shadcn_flutter/shadcn_flutter.dart";
import "package:uniso_social_media_app/models/picsum_image.dart";
import "package:flutter_lorem/flutter_lorem.dart";

void main() {
  runApp(App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _App();
}

class _App extends State<App> {
  Key? _selected = ValueKey(0);
  final PageController _controller = PageController();

  void _goToPage(int index) {
    final newKey = ValueKey(index);
    if (_selected == newKey) return;

    setState(() {
      _selected = newKey;
    });

    // _controller.jumpToPage(index);
    _controller.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  NavigationItem buildButton(String label, IconData icon, Key key) {
    return NavigationItem(
      key: key,
      style: ButtonStyle.muted(density: ButtonDensity.icon),
      selectedStyle: ButtonStyle.fixed(density: ButtonDensity.icon),
      label: Text(label),
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = ThemeData.dark(radius: 0.75);
    return ShadcnApp(
      darkTheme: theme,
      theme: theme,
      themeMode: ThemeMode.system,
      // scaling: const AdaptiveScaling(1),
      home: Scaffold(
        footers: [
          NavigationBar(
            selectedKey: _selected,
            alignment: .spaceEvenly,
            onSelected: (key) {
              var index = (key as ValueKey<int>).value;
              _goToPage(index);
            },
            children: [
              buildButton("Home", BootstrapIcons.house, ValueKey(0)),
              buildButton("Unisons", BootstrapIcons.people, ValueKey(1)),
            ],
          ),
        ],
        child: PageView(
          controller: _controller,
          physics: NeverScrollableScrollPhysics(),
          scrollDirection: .horizontal,
          children: [Home(), Unisons()],
        ),
      ),
    );
  }
}

class Unisons extends StatefulWidget {
  const Unisons({super.key});

  @override
  State<Unisons> createState() => _Unisons();
}

class _Unisons extends State<Unisons> {
  Key? _selectedUnison = null;

  @override
  Widget build(BuildContext context) {
    var padding = Theme.of(context).density.baseContentPadding;
    return Row(
      crossAxisAlignment: .stretch,
      children: [
        NavigationRail(
          labelPosition: .end,
          labelType: .all,
          header: [Text("Unisons List")],
          footer: [
            PrimaryButton(
              // onPressed: () {
              //   openSheet(
              //     context: context,
              //     builder: (context) {
              //       return MemberList();
              //     },
              //     position: .right,
              //   );
              // },
              child: Text("Members List"),
            ),
          ],
          spacing: Theme.of(context).density.baseGap,
          alignment: .center,
          onSelected: (key) {
            setState(() {
              _selectedUnison = key;
            });
          },
          selectedKey: _selectedUnison,
          children: [
            SingleChildScrollView(
              child: Column(
                children: List.generate(50, (index) {
                  return NavigationItem(
                    key: ValueKey(index),
                    selectedStyle: ButtonStyle.secondary(),
                    style: ButtonStyle.ghost(),
                    label: Text(lorem(paragraphs: 1, words: 1)),
                    child: Icon(RadixIcons.person),
                  );
                }),
              ),
            ),
          ],
        ),
        Expanded(
          child: Column(
            spacing: Theme.of(context).density.baseGap,
            children: [
              Expanded(child: UnisonConversation()),
              Row(
                spacing: Theme.of(context).density.baseGap,
                children: [
                  Expanded(child: TextField()),
                  IconButton.primary(
                    onPressed: () {},
                    icon: Icon(LucideIcons.sendHorizontal),
                  ),
                ],
              ),
            ],
          ).withPadding(all: padding),
        ),
      ],
    );
  }
}

class UnisonConversation extends StatefulWidget {
  const UnisonConversation({super.key});

  @override
  State<UnisonConversation> createState() => _UnisonConversation();
}

class _UnisonConversation extends State<UnisonConversation> {
  final ScrollController _chatScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _chatScrollController,
      itemCount: 20,
      reverse: true,
      itemBuilder: (context, index) {
        var isOther = index % 2 == 0;

        return Column(
          children: [
            ChatBubble(
              color: isOther ? Colors.gray : Colors.blue,
              type: ChatBubbleType.tail.copyWith(
                tailAlignment: () => AxisAlignmentDirectional.end,
                position: () =>
                    isOther ? AxisDirectional.start : AxisDirectional.end,
              ),
              alignment: isOther
                  ? AxisAlignmentDirectional.start
                  : AxisAlignmentDirectional.end,
              child: Text(lorem(paragraphs: 1, words: 4)),
            ).withPadding(
              horizontal: isOther
                  ? 0
                  : Theme.of(context).density.baseContainerPadding,
            ),
            Gap(Theme.of(context).density.baseGap),
          ],
        );
      },
    );
  }
}

class Scroller extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> {
  final _pageController = PageController(initialPage: 0);
  final List<PicsumImage> _images = [];

  int _currentPage = 0;
  int _currentPicsumPage = 0;
  bool _isLoading = false;

  static const Curve _pageAnimation = Curves.easeOutCubic;

  // Debug
  bool _isLoggedIn = true;

  Future<List<PicsumImage>> fetchImages(int page, {int? limit = 4}) async {
    final response = await http.get(
      Uri.parse("https://picsum.photos/v2/list?page=$page&limit=$limit"),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => PicsumImage.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load images");
    }
  }

  Future<void> _fetchNextPage() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      var newImages = await fetchImages(_currentPicsumPage);

      setState(() {
        _images.addAll(newImages);
        _currentPicsumPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _fetchNextPage();
    _pageController.addListener(() {
      if (_currentPage > _images.length - 2) {
        _fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void nextPage() {
    int targetPage = (_currentPage + 1).clamp(0, _images.length - 1);
    _currentPage = targetPage;
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 300),
      curve: _pageAnimation,
    );
  }

  void previousPage() {
    int targetPage = (_currentPage - 1).clamp(0, _images.length - 1);
    _currentPage = targetPage;
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 300),
      curve: _pageAnimation,
    );
  }

  @override
  Widget build(BuildContext context) {
    var padding = Theme.of(context).density.baseContentPadding;
    return ScrollConfiguration(
      behavior: Scroller(),
      child: Stack(
        alignment: .center,
        children: [
          _images.isEmpty
              ? CenteredCircularProgress()
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: _images.length,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    var image = _images[index];
                    var theme = Theme.of(context);

                    return PostPage(image: image, theme: theme);
                  },
                ),
          if (kDebugMode)
            Positioned(top: padding, child: Text("Page $_currentPage")),
          Positioned(
            right: padding,
            child: Column(
              spacing: Theme.of(context).density.baseGap,
              children: [
                if (_currentPage > 0)
                  GhostButton(
                    onPressed: () {
                      previousPage();
                    },
                    shape: .circle,
                    child: Icon(RadixIcons.chevronUp),
                  ),
                GhostButton(
                  onPressed: () {
                    nextPage();
                  },
                  shape: .circle,
                  child: Icon(RadixIcons.chevronDown),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0.0,
            left: 0.0,
            child: Row(
              spacing: padding,
              children: [
                _isLoggedIn
                    ? Pressable(
                        onPressed: () {
                          setState(() {
                            _isLoggedIn = !_isLoggedIn;
                          });
                        },
                        child: Avatar(
                          initials: Avatar.getInitials("unison"),
                          provider: CachedNetworkImageProvider(
                            "https://avatars.githubusercontent.com/u/64018564?v=4",
                          ),
                          size: Theme.of(context).typography.h1.fontSize,
                        ),
                      )
                    : IconButton.primary(
                        onPressed: () {
                          setState(() {
                            _isLoggedIn = !_isLoggedIn;
                          });
                        },
                        shape: .circle,
                        icon: Icon(
                          RadixIcons.person,
                          color: Theme.of(context).colorScheme.background,
                        ),
                      ),
                Text(
                  "Your name",
                  style: TextStyle(
                    shadows: [
                      Shadow(
                        offset: Offset.fromDirection(10, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ).withPadding(all: padding),
          ),
        ],
      ),
    ).withPadding(all: padding);
  }
}

class MemberList extends StatefulWidget {
  MemberList({super.key});

  @override
  State<MemberList> createState() => _MemberList();
}

class _MemberList extends State<MemberList> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(50, (index) {
          return SecondaryButton(
            child: Row(
              children: [
                Icon(RadixIcons.person),
                Text(lorem(paragraphs: 1, words: 1)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class Pressable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final HitTestBehavior behavior;
  final SystemMouseCursor cursor;

  const Pressable({
    super.key,
    required this.child,
    this.onPressed,
    this.behavior = HitTestBehavior.opaque, // Makes empty space clickable
    this.cursor = SystemMouseCursors.click, // Shows the "hand" icon
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onTap: onPressed,
        behavior: behavior,
        child: child,
      ),
    );
  }
}

class CenteredCircularProgress extends StatelessWidget {
  final double? progress;

  const CenteredCircularProgress({super.key, this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        size: Theme.of(context).typography.x4Large.fontSize,
        value: progress,
      ),
    );
  }
}

class PostPage extends StatefulWidget {
  final PicsumImage image;
  final ThemeData theme;

  const PostPage({super.key, required this.image, required this.theme});

  @override
  State<PostPage> createState() => _PostPage();
}

class _PostPage extends State<PostPage> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.theme.radiusMd),
      child: CachedNetworkImage(
        fadeInDuration: Duration.zero,
        imageUrl: widget.image.downloadUrl,
        fit: BoxFit.cover,
        progressIndicatorBuilder: (context, url, progress) {
          return CenteredCircularProgress(progress: progress.progress);
        },
        imageBuilder: (context, imageProvider) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image(image: imageProvider, fit: BoxFit.cover),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Padding(
                  padding: EdgeInsets.all(
                    widget.theme.density.baseContentPadding,
                  ),
                  child: Text(
                    widget.image.author,
                    style: TextStyle(
                      shadows: [
                        Shadow(
                          offset: Offset.fromDirection(10, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
