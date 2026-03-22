import "dart:convert";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:uniso_social_media_app/models/message.dart";
import "package:uniso_social_media_app/models/picsum_image.dart";
import "package:flutter_lorem/flutter_lorem.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:intl/intl.dart";

Future<void> initializeSupabaseClient() async {
  var supabaseApiUrl = dotenv.env["API_URL"];
  var supabaseAnonKey = dotenv.env["ANON_KEY"];

  if (supabaseApiUrl != null && supabaseAnonKey != null) {
    await Supabase.initialize(url: supabaseApiUrl, anonKey: supabaseAnonKey);
  }
}

void main() async {
  try {
    await dotenv.load(fileName: "supabase/.env", isOptional: true);
  } finally {}

  await initializeSupabaseClient();

  runApp(SocialMediaApp());
}

class SocialMediaApp extends StatefulWidget {
  const SocialMediaApp({super.key});

  @override
  State<SocialMediaApp> createState() => _SocialMediaAppState();
}

class _SocialMediaAppState extends State<SocialMediaApp> {
  int _activeBottomNavIndex = 0;
  final PageController _bottomNavPageController = PageController();

  void _onBottomNavItemTapped(int tappedIndex) {
    setState(() {
      _activeBottomNavIndex = tappedIndex;
    });
    _bottomNavPageController.animateToPage(
      tappedIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _bottomNavPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: PageView(
          controller: _bottomNavPageController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [HomeFeedScreen(), UnisonsScreen()],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _activeBottomNavIndex,
          onTap: _onBottomNavItemTapped,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: "Unisons"),
          ],
        ),
      ),
    );
  }
}

class UnisonMemberList extends StatefulWidget {
  const UnisonMemberList({super.key});

  @override
  State<UnisonMemberList> createState() => _UnisonMemberListState();
}

class _UnisonMemberListState extends State<UnisonMemberList> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children:
                List.generate(50, (memberIndex) {
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
                    .expand(
                      (memberWidget) => [
                        memberWidget,
                        const SizedBox(height: 8),
                      ],
                    )
                    .toList()
                  ..removeLast(),
          ),
        ),
      ),
    );
  }
}

class UnisonGroupSidebar extends StatefulWidget {
  const UnisonGroupSidebar({super.key});

  @override
  State<UnisonGroupSidebar> createState() => _UnisonGroupSidebarState();
}

class _UnisonGroupSidebarState extends State<UnisonGroupSidebar> {
  int? _selectedGroupIndex;
  var unisonGroupNames = List.generate(50, (groupIndex) {
    return lorem(paragraphs: 1, words: 1);
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ColoredBox(
          color: Theme.of(context).canvasColor,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Unisons List"),
                  ),
                  MenuAnchor(
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) {
                              return const CreateNewUnisonDialog();
                            },
                          );
                        },
                        child: const Text("Create new Unison"),
                      ),
                    ],
                    builder: (menuContext, menuController, menuChild) {
                      return IconButton(
                        onPressed: () {
                          if (menuController.isOpen) {
                            menuController.close();
                          } else {
                            menuController.open();
                          }
                        },
                        icon: Icon(Icons.list),
                      );
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Search unions...",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (searchQuery) {},
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: unisonGroupNames.length,
            itemBuilder: (listContext, groupIndex) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(unisonGroupNames[groupIndex]),
                selected: _selectedGroupIndex == groupIndex,
                selectedTileColor: Theme.of(listContext).colorScheme.primary,
                selectedColor: Theme.of(listContext).colorScheme.onPrimary,
                onTap: () {
                  setState(() {
                    _selectedGroupIndex = groupIndex;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class UnisonChatInputScreen extends StatefulWidget {
  const UnisonChatInputScreen({super.key});

  @override
  State<UnisonChatInputScreen> createState() => _UnisonChatInputScreenState();
}

class _UnisonChatInputScreenState extends State<UnisonChatInputScreen> {
  final TextEditingController _outgoingMessageController =
      TextEditingController();
  late RealtimeChannel supabaseRoomChannel;
  var _isMessageSending = false;

  @override
  void initState() {
    super.initState();

    supabaseRoomChannel = Supabase.instance.client.channel(
      "room:messages",
      opts: RealtimeChannelConfig(self: true),
    );
  }

  @override
  void dispose() {
    _outgoingMessageController.dispose();
    supabaseRoomChannel.unsubscribe();

    super.dispose();
  }

  void submitOutgoingMessage() async {
    var messageContent = _outgoingMessageController.text;
    _outgoingMessageController.text = "";
    if (messageContent.isEmpty) {
      return;
    }

    try {
      setState(() {
        _isMessageSending = true;
      });

      var insertedMessageData = await Supabase.instance.client
          .from("messages")
          .insert({"content": messageContent})
          .select()
          .single();

      supabaseRoomChannel.sendBroadcastMessage(
        event: "message_sent",
        payload: insertedMessageData,
      );

      setState(() {
        _isMessageSending = false;
      });
    } catch (sendError) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(sendError.toString())));
      }
      setState(() {
        _outgoingMessageController.text = messageContent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (overlayContext) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        child: SizedBox(
                          width: 200,
                          height: double.infinity,
                          child: const UnisonMemberList(),
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
        Divider(),
        UnisonMessageFeed(realtimeRoomChannel: supabaseRoomChannel),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _outgoingMessageController,
                onSubmitted: (_) => submitOutgoingMessage(),
                decoration: InputDecoration(
                  hintText: "Enter your message...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              onPressed: _isMessageSending ? null : submitOutgoingMessage,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }
}

class UnisonsScreen extends StatefulWidget {
  const UnisonsScreen({super.key});

  @override
  State<UnisonsScreen> createState() => _UnisonsScreenState();
}

class _UnisonsScreenState extends State<UnisonsScreen> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 250, child: UnisonGroupSidebar()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: UnisonChatInputScreen(),
          ),
        ),
      ],
    );
  }
}

class CreateNewUnisonDialog extends StatefulWidget {
  const CreateNewUnisonDialog({super.key});

  @override
  State<CreateNewUnisonDialog> createState() => _CreateNewUnisonDialogState();
}

class _CreateNewUnisonDialogState extends State<CreateNewUnisonDialog> {
  final _createUnisonFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create new Unison"),
      content: Form(
        key: _createUnisonFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Name",
                hintText: "Name",
              ),
              validator: (enteredName) {
                if (enteredName == null || enteredName.length < 4) {
                  return "Name must be at least 4 characters";
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
            if (_createUnisonFormKey.currentState!.validate()) {
              // Create
            }
          },
          child: const Text("Create"),
        ),
      ],
    );
  }
}

class UnisonMessageFeed extends StatefulWidget {
  final RealtimeChannel realtimeRoomChannel;
  const UnisonMessageFeed({super.key, required this.realtimeRoomChannel});

  @override
  State<UnisonMessageFeed> createState() => _UnisonMessageFeedState();
}

class _UnisonMessageFeedState extends State<UnisonMessageFeed> {
  final ScrollController _messageFeedScrollController = ScrollController();
  List<Message> _loadedMessages = [];
  double _messageFeedScrollOffset = 0;
  bool _isFetchingMessages = false;

  Future<List<Message>> fetchMessagesFromDatabase() async {
    final fetchedMessages = await Supabase.instance.client
        .from("messages")
        .select("content, created_at")
        .order("created_at", ascending: true);

    return Message.fromList(fetchedMessages);
  }

  @override
  void initState() {
    super.initState();

    _messageFeedScrollController.addListener(() {
      setState(() {
        _messageFeedScrollOffset = _messageFeedScrollController.offset;
      });
    });

    widget.realtimeRoomChannel
        .onBroadcast(
          event: "message_sent",
          callback: (broadcastPayload) {
            setState(() {
              _loadedMessages.add(Message.fromMap(broadcastPayload));
              _scrollFeedToLatestMessage();
            });
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    widget.realtimeRoomChannel.unsubscribe();
    super.dispose();
  }

  void fetchAndDisplayMessages() async {
    var scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      _isFetchingMessages = true;
    });

    try {
      var fetchedMessages = await fetchMessagesFromDatabase();

      setState(() {
        _loadedMessages = fetchedMessages;
      });
    } catch (fetchError) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(fetchError.toString())),
      );
    }

    setState(() {
      _isFetchingMessages = false;
    });
  }

  void _scrollFeedToLatestMessage() {
    _messageFeedScrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListView.builder(
            controller: _messageFeedScrollController,
            itemCount: _loadedMessages.length + 1,
            reverse: true,
            padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
            itemBuilder: (feedContext, reversedMessageIndex) {
              if (reversedMessageIndex == _loadedMessages.length) {
                return Center(
                  child: _isFetchingMessages
                      ? CircularProgressIndicator()
                      : TextButton(
                          onPressed: () {
                            fetchAndDisplayMessages();
                          },
                          child: const Text("Load more messages"),
                        ),
                );
              }

              bool isMessageFromOtherUser = reversedMessageIndex % 2 == 0;
              var displayedMessage =
                  _loadedMessages[_loadedMessages.length -
                      reversedMessageIndex -
                      1];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    CircleAvatar(
                      backgroundColor: isMessageFromOtherUser
                          ? Colors.orange
                          : Colors.indigo,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    // Message Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Username and Timestamp
                          Row(
                            children: [
                              Text(
                                isMessageFromOtherUser ? "User A" : "User B",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  "M/d/yy, h:mm a",
                                ).format(displayedMessage.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    feedContext,
                                  ).textTheme.bodySmall?.color?.withValues(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Message Body
                          Text(
                            displayedMessage.content,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_messageFeedScrollOffset > 0)
            Positioned(
              bottom: 16,
              child: IconButton.filled(
                onPressed: _scrollFeedToLatestMessage,
                icon: Icon(Icons.arrow_downward),
              ),
            ),
        ],
      ),
    );
  }
}

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final _verticalPostPageController = PageController(initialPage: 0);
  final List<PicsumImage> _fetchedPostImages = [];

  int _visiblePostPageIndex = 0;
  int _nextPicsumApiPage = 0;
  bool _isFetchingPostImages = false;

  static const Curve _postPageScrollAnimation = Curves.easeOutCubic;

  // Debug
  bool _isCurrentUserLoggedIn = true;

  Future<List<PicsumImage>> fetchPicsumImages(
    int picsumPage, {
    int? limit = 4,
  }) async {
    final httpResponse = await http.get(
      Uri.parse("https://picsum.photos/v2/list?page=$picsumPage&limit=$limit"),
    );

    if (httpResponse.statusCode == 200) {
      List<dynamic> decodedImageData = jsonDecode(httpResponse.body);
      return decodedImageData
          .map((imageJson) => PicsumImage.fromJson(imageJson))
          .toList();
    } else {
      throw Exception("Failed to load images");
    }
  }

  Future<void> _fetchNextBatchOfPostImages() async {
    if (_isFetchingPostImages) return;

    setState(() => _isFetchingPostImages = true);

    try {
      var newlyFetchedImages = await fetchPicsumImages(_nextPicsumApiPage);

      setState(() {
        _fetchedPostImages.addAll(newlyFetchedImages);
        _nextPicsumApiPage++;
        _isFetchingPostImages = false;
      });
    } catch (fetchError) {
      setState(() => _isFetchingPostImages = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _fetchNextBatchOfPostImages();
    _verticalPostPageController.addListener(() {
      if (_visiblePostPageIndex > _fetchedPostImages.length - 2) {
        _fetchNextBatchOfPostImages();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _verticalPostPageController.dispose();
  }

  void navigateToNextPost() {
    int targetPostIndex = (_visiblePostPageIndex + 1).clamp(
      0,
      _fetchedPostImages.length - 1,
    );
    _visiblePostPageIndex = targetPostIndex;
    _verticalPostPageController.animateToPage(
      targetPostIndex,
      duration: const Duration(milliseconds: 300),
      curve: _postPageScrollAnimation,
    );
  }

  void navigateToPreviousPost() {
    int targetPostIndex = (_visiblePostPageIndex - 1).clamp(
      0,
      _fetchedPostImages.length - 1,
    );
    _visiblePostPageIndex = targetPostIndex;
    _verticalPostPageController.animateToPage(
      targetPostIndex,
      duration: const Duration(milliseconds: 300),
      curve: _postPageScrollAnimation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _fetchedPostImages.isEmpty
            ? const FullScreenLoadingIndicator()
            : PageView.builder(
                controller: _verticalPostPageController,
                scrollDirection: Axis.vertical,
                itemCount: _fetchedPostImages.length,
                onPageChanged: (newPageIndex) {
                  setState(() {
                    _visiblePostPageIndex = newPageIndex;
                  });
                },
                itemBuilder: (feedContext, postIndex) {
                  var currentPostImage = _fetchedPostImages[postIndex];
                  return FullScreenPostPage(postImage: currentPostImage);
                },
              ),
        if (kDebugMode)
          Positioned(
            top: 16,
            child: Text(
              "Page $_visiblePostPageIndex",
              style: TextStyle(color: Colors.white),
            ),
          ),
        Positioned(
          right: 16,
          child: Column(
            children: [
              if (_visiblePostPageIndex > 0)
                TextButton(
                  onPressed: navigateToPreviousPost,
                  style: TextButton.styleFrom(shape: const CircleBorder()),
                  child: const Icon(Icons.keyboard_arrow_up),
                ),
              TextButton(
                onPressed: navigateToNextPost,
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
                _isCurrentUserLoggedIn
                    ? TappableWidget(
                        onPressed: () {
                          setState(() {
                            _isCurrentUserLoggedIn = !_isCurrentUserLoggedIn;
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
                            _isCurrentUserLoggedIn = !_isCurrentUserLoggedIn;
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
                    color: Colors.white,
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

class TappableWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final HitTestBehavior hitTestBehavior;
  final SystemMouseCursor mouseCursorStyle;

  const TappableWidget({
    super.key,
    required this.child,
    this.onPressed,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.mouseCursorStyle = SystemMouseCursors.click,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: mouseCursorStyle,
      child: GestureDetector(
        onTap: onPressed,
        behavior: hitTestBehavior,
        child: child,
      ),
    );
  }
}

class FullScreenLoadingIndicator extends StatelessWidget {
  final double? loadingProgress;

  const FullScreenLoadingIndicator({super.key, this.loadingProgress});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: CircularProgressIndicator(value: loadingProgress),
    );
  }
}

class FullScreenPostPage extends StatefulWidget {
  final PicsumImage postImage;

  const FullScreenPostPage({super.key, required this.postImage});

  @override
  State<FullScreenPostPage> createState() => _FullScreenPostPageState();
}

class _FullScreenPostPageState extends State<FullScreenPostPage> {
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fadeInDuration: Duration.zero,
      imageUrl: widget.postImage.downloadUrl,
      fit: BoxFit.cover,
      progressIndicatorBuilder: (imageContext, imageUrl, downloadProgress) {
        return FullScreenLoadingIndicator(
          loadingProgress: downloadProgress.progress,
        );
      },
      imageBuilder: (imageContext, resolvedImageProvider) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image(image: resolvedImageProvider, fit: BoxFit.cover),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.postImage.author,
                  style: TextStyle(
                    color: Colors.white,
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
