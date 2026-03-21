import "dart:convert";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:uniso_social_media_app/models/picsum_image.dart";
import "package:flutter_lorem/flutter_lorem.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:chat_bubbles/chat_bubbles.dart";

Future<void> initializeSupabase() async {
  var apiUrl = dotenv.env["API_URL"];
  var anonKey = dotenv.env["ANON_KEY"];

  if (apiUrl != null && anonKey != null) {
    await Supabase.initialize(url: apiUrl, anonKey: anonKey);
  }
}

void main() async {
  try {
    await dotenv.load(isOptional: true);
  } finally {}

  await initializeSupabase();

  runApp(App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _App();
}

class _App extends State<App> {
  int _selectedIndex = 0;
  final PageController _controller = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: const [Home(), Unisons()],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Unisons'),
          ],
        ),
      ),
    );
  }
}

class MemberList extends StatefulWidget {
  const MemberList({super.key});

  @override
  State<MemberList> createState() => _MemberList();
}

class _MemberList extends State<MemberList> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children:
                List.generate(50, (index) {
                      return TextButton(
                        onPressed: () {},
                        child: Row(
                          children: [
                            const Icon(Icons.person),
                            Text(lorem(paragraphs: 1, words: 1)),
                          ],
                        ),
                      );
                    })
                    .expand((widget) => [widget, const SizedBox(height: 8)])
                    .toList()
                  ..removeLast(),
          ),
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
  int? _selectedUnisonIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 250,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Unisons List"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Search unions...",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {},
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 50,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(lorem(paragraphs: 1, words: 1)),
                      selected: _selectedUnisonIndex == index,
                      onTap: () {
                        setState(() {
                          _selectedUnisonIndex = index;
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return const CreateNewUnisonDialog();
                      },
                    );
                  },
                  child: const Text("Create new Unison"),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Material(
                                child: SizedBox(
                                  width: 200,
                                  height: double.infinity,
                                  child: const MemberList(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: const Text("Members List"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Expanded(child: UnisonConversation()),
                Row(
                  children: [
                    const Expanded(child: TextField()),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.send)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CreateNewUnisonDialog extends StatefulWidget {
  const CreateNewUnisonDialog({super.key});

  @override
  State<CreateNewUnisonDialog> createState() => _CreateNewUnisonDialog();
}

class _CreateNewUnisonDialog extends State<CreateNewUnisonDialog> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create new Unison"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Name",
                hintText: "Name",
              ),
              validator: (value) {
                if (value == null || value.length < 4) {
                  return 'Name must be at least 4 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Create
            }
          },
          child: const Text("Create"),
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
        bool isOther = index % 2 == 0;
        return BubbleNormal(
          text: lorem(paragraphs: 1, words: 4),
          isSender: !isOther,
          color: isOther ? Colors.grey[800]! : Colors.blue,
          tail: true,
          textStyle: const TextStyle(color: Colors.white),
        );
      },
    );
  }
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
    return Stack(
      alignment: Alignment.center,
      children: [
        _images.isEmpty
            ? const CenteredCircularProgress()
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
                  return PostPage(image: image);
                },
              ),
        if (kDebugMode) Positioned(top: 16, child: Text("Page $_currentPage")),
        Positioned(
          right: 16,
          child: Column(
            children: [
              if (_currentPage > 0)
                TextButton(
                  onPressed: previousPage,
                  style: TextButton.styleFrom(shape: const CircleBorder()),
                  child: const Icon(Icons.keyboard_arrow_up),
                ),
              TextButton(
                onPressed: nextPage,
                style: TextButton.styleFrom(shape: const CircleBorder()),
                child: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0.0,
          left: 0.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _isLoggedIn
                    ? Pressable(
                        onPressed: () {
                          setState(() {
                            _isLoggedIn = !_isLoggedIn;
                          });
                        },
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(
                            "https://avatars.githubusercontent.com/u/64018564?v=4",
                          ),
                          radius: 24,
                        ),
                      )
                    : IconButton(
                        onPressed: () {
                          setState(() {
                            _isLoggedIn = !_isLoggedIn;
                          });
                        },
                        style: IconButton.styleFrom(
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.person, color: Colors.white),
                      ),
                const SizedBox(width: 16),
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
            ),
          ),
        ),
      ],
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
      child: CircularProgressIndicator(value: progress),
    );
  }
}

class PostPage extends StatefulWidget {
  final PicsumImage image;

  const PostPage({super.key, required this.image});

  @override
  State<PostPage> createState() => _PostPage();
}

class _PostPage extends State<PostPage> {
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
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
                padding: const EdgeInsets.all(16.0),
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
    );
  }
}
