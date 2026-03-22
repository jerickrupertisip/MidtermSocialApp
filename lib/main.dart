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

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _kPostPageAnimationDuration = Duration(milliseconds: 300);
const _kScrollAnimationDuration = Duration(milliseconds: 300);
const _kNavAnimationDuration = Duration(milliseconds: 300);
const _kSidebarWidth = 250.0;
const _kMemberPanelWidth = 200.0;
const _kAvatarRadius = 24.0;
const _kDropShadow = Shadow(offset: Offset(1.9, -0.4), blurRadius: 6);
const _kOverlayTextStyle = TextStyle(
  color: Colors.white,
  shadows: [_kDropShadow],
);

// ---------------------------------------------------------------------------
// Initialisation
// ---------------------------------------------------------------------------

Future<void> initializeSupabaseClient() async {
  final supabaseApiUrl = dotenv.env["API_URL"];
  final supabaseAnonKey = dotenv.env["ANON_KEY"];

  if (supabaseApiUrl != null && supabaseAnonKey != null) {
    await Supabase.initialize(url: supabaseApiUrl, anonKey: supabaseAnonKey);
  }
}

void main() async {
  try {
    await dotenv.load(fileName: "supabase/.env", isOptional: true);
  } finally {}

  await initializeSupabaseClient();

  runApp(const SocialMediaApp());
}

// ---------------------------------------------------------------------------
// Root application
// ---------------------------------------------------------------------------

class SocialMediaApp extends StatefulWidget {
  const SocialMediaApp({super.key});

  @override
  State<SocialMediaApp> createState() => _SocialMediaAppState();
}

class _SocialMediaAppState extends State<SocialMediaApp> {
  int _activeBottomNavIndex = 0;
  final PageController _bottomNavPageController = PageController();

  void _onBottomNavItemTapped(int tappedIndex) {
    setState(() => _activeBottomNavIndex = tappedIndex);
    _bottomNavPageController.animateToPage(
      tappedIndex,
      duration: _kNavAnimationDuration,
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
        body: _buildPageView(),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView(
      controller: _bottomNavPageController,
      physics: const NeverScrollableScrollPhysics(),
      children: const [HomeFeedScreen(), UnisonsScreen()],
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _activeBottomNavIndex,
      onTap: _onBottomNavItemTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: "Unisons"),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Unisons screen — top-level layout
// ---------------------------------------------------------------------------

class UnisonsScreen extends StatelessWidget {
  const UnisonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: _kSidebarWidth, child: UnisonGroupSidebar()),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: UnisonChatInputScreen(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Unison group sidebar
// ---------------------------------------------------------------------------

class UnisonGroupSidebar extends StatefulWidget {
  const UnisonGroupSidebar({super.key});

  @override
  State<UnisonGroupSidebar> createState() => _UnisonGroupSidebarState();
}

class _UnisonGroupSidebarState extends State<UnisonGroupSidebar> {
  int? _selectedGroupIndex;
  final List<String> _unisonGroupNames = List.generate(
    50,
    (_) => lorem(paragraphs: 1, words: 1),
  );

  void _onGroupTapped(int groupIndex) {
    setState(() => _selectedGroupIndex = groupIndex);
  }

  void _openCreateUnisonDialog() {
    showDialog(context: context, builder: (_) => const CreateNewUnisonDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SidebarHeader(onCreateUnison: _openCreateUnisonDialog),
        Expanded(child: _buildGroupList()),
      ],
    );
  }

  Widget _buildGroupList() {
    return ListView.builder(
      itemCount: _unisonGroupNames.length,
      itemBuilder: (listContext, groupIndex) {
        final isSelected = _selectedGroupIndex == groupIndex;
        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(_unisonGroupNames[groupIndex]),
          selected: isSelected,
          selectedTileColor: Theme.of(listContext).colorScheme.primary,
          selectedColor: Theme.of(listContext).colorScheme.onPrimary,
          onTap: () => _onGroupTapped(groupIndex),
        );
      },
    );
  }
}

/// The fixed header section of [UnisonGroupSidebar], containing the title,
/// actions menu, and search field.
class _SidebarHeader extends StatelessWidget {
  final VoidCallback onCreateUnison;

  const _SidebarHeader({required this.onCreateUnison});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).canvasColor,
      child: Column(children: [_buildTitleRow(), _buildSearchField()]),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Unisons List"),
        ),
        _UnisonActionsMenu(onCreateUnison: onCreateUnison),
      ],
    );
  }

  Widget _buildSearchField() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search unions...",
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }
}

/// The [MenuAnchor] button that exposes sidebar actions such as creating a
/// new Unison group.
class _UnisonActionsMenu extends StatelessWidget {
  final VoidCallback onCreateUnison;

  const _UnisonActionsMenu({required this.onCreateUnison});

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed: onCreateUnison,
          child: const Text("Create new Unison"),
        ),
      ],
      builder: (_, menuController, _) {
        return IconButton(
          onPressed: () => menuController.isOpen
              ? menuController.close()
              : menuController.open(),
          icon: const Icon(Icons.list),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Create new Unison dialog
// ---------------------------------------------------------------------------

class CreateNewUnisonDialog extends StatefulWidget {
  const CreateNewUnisonDialog({super.key});

  @override
  State<CreateNewUnisonDialog> createState() => _CreateNewUnisonDialogState();
}

class _CreateNewUnisonDialogState extends State<CreateNewUnisonDialog> {
  final _createUnisonFormKey = GlobalKey<FormState>();

  void _onConfirmCreate() {
    if (_createUnisonFormKey.currentState!.validate()) {
      // Create
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create new Unison"),
      content: _buildForm(),
      actions: _buildActions(context),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _createUnisonFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildNameField()],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      decoration: const InputDecoration(labelText: "Name", hintText: "Name"),
      validator: (enteredName) {
        if (enteredName == null || enteredName.length < 4) {
          return "Name must be at least 4 characters";
        }
        return null;
      },
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text("Cancel"),
      ),
      ElevatedButton(onPressed: _onConfirmCreate, child: const Text("Create")),
    ];
  }
}

// ---------------------------------------------------------------------------
// Chat input screen (wraps the message feed + input bar)
// ---------------------------------------------------------------------------

class UnisonChatInputScreen extends StatefulWidget {
  const UnisonChatInputScreen({super.key});

  @override
  State<UnisonChatInputScreen> createState() => _UnisonChatInputScreenState();
}

class _UnisonChatInputScreenState extends State<UnisonChatInputScreen> {
  final TextEditingController _outgoingMessageController =
      TextEditingController();
  late final RealtimeChannel _supabaseRoomChannel;
  bool _isMessageSending = false;

  @override
  void initState() {
    super.initState();
    _supabaseRoomChannel = Supabase.instance.client.channel(
      "room:messages",
      opts: RealtimeChannelConfig(self: true),
    );
  }

  @override
  void dispose() {
    _outgoingMessageController.dispose();
    _supabaseRoomChannel.unsubscribe();
    super.dispose();
  }

  Future<void> _submitOutgoingMessage() async {
    final messageContent = _outgoingMessageController.text;
    if (messageContent.isEmpty) return;

    _outgoingMessageController.clear();
    setState(() => _isMessageSending = true);

    try {
      final insertedMessageData = await Supabase.instance.client
          .from("messages")
          .insert({"content": messageContent})
          .select()
          .single();

      _supabaseRoomChannel.sendBroadcastMessage(
        event: "message_sent",
        payload: insertedMessageData,
      );
    } catch (sendError) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(sendError.toString())));
        setState(() => _outgoingMessageController.text = messageContent);
      }
    } finally {
      if (mounted) setState(() => _isMessageSending = false);
    }
  }

  void _openMemberListPanel() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Align(
        alignment: Alignment.centerRight,
        child: Material(
          child: SizedBox(
            width: _kMemberPanelWidth,
            height: double.infinity,
            child: UnisonMemberList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMembersListButton(),
        const Divider(),
        UnisonMessageFeed(realtimeRoomChannel: _supabaseRoomChannel),
        _buildMessageInputRow(),
      ],
    );
  }

  Widget _buildMembersListButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _openMemberListPanel,
          child: const Text("Members List"),
        ),
      ],
    );
  }

  Widget _buildMessageInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _outgoingMessageController,
            onSubmitted: (_) => _submitOutgoingMessage(),
            decoration: const InputDecoration(
              hintText: "Enter your message...",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          onPressed: _isMessageSending ? null : _submitOutgoingMessage,
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Member list panel
// ---------------------------------------------------------------------------

class UnisonMemberList extends StatelessWidget {
  const UnisonMemberList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kMemberPanelWidth,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: 50,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, _) => const _MemberListItem(),
        ),
      ),
    );
  }
}

class _MemberListItem extends StatelessWidget {
  const _MemberListItem();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Row(
        children: [
          const Icon(Icons.person),
          Text(lorem(paragraphs: 1, words: 1)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message feed
// ---------------------------------------------------------------------------

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

  @override
  void initState() {
    super.initState();
    _messageFeedScrollController.addListener(_onScrollOffsetChanged);
    widget.realtimeRoomChannel
        .onBroadcast(
          event: "message_sent",
          callback: (broadcastPayload) => setState(() {
            _loadedMessages.add(Message.fromMap(broadcastPayload));
            _scrollFeedToLatestMessage();
          }),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _messageFeedScrollController.dispose();
    widget.realtimeRoomChannel.unsubscribe();
    super.dispose();
  }

  void _onScrollOffsetChanged() {
    setState(() {
      _messageFeedScrollOffset = _messageFeedScrollController.offset;
    });
  }

  Future<List<Message>> _fetchMessagesFromDatabase() async {
    final fetchedMessages = await Supabase.instance.client
        .from("messages")
        .select("content, created_at")
        .order("created_at", ascending: true);

    return Message.fromList(fetchedMessages);
  }

  Future<void> _fetchAndDisplayMessages() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isFetchingMessages = true);

    try {
      final fetchedMessages = await _fetchMessagesFromDatabase();
      setState(() => _loadedMessages = fetchedMessages);
    } catch (fetchError) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(fetchError.toString())),
      );
    } finally {
      setState(() => _isFetchingMessages = false);
    }
  }

  void _scrollFeedToLatestMessage() {
    _messageFeedScrollController.animateTo(
      0.0,
      duration: _kScrollAnimationDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildMessageList(),
          if (_messageFeedScrollOffset > 0) _buildScrollToBottomButton(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _messageFeedScrollController,
      itemCount: _loadedMessages.length + 1,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
      itemBuilder: _buildMessageListItem,
    );
  }

  Widget _buildMessageListItem(
    BuildContext feedContext,
    int reversedMessageIndex,
  ) {
    if (reversedMessageIndex == _loadedMessages.length) {
      return _buildLoadMoreFooter();
    }

    final isMessageFromOtherUser = reversedMessageIndex % 2 == 0;
    final displayedMessage =
        _loadedMessages[_loadedMessages.length - reversedMessageIndex - 1];

    return _MessageBubble(
      message: displayedMessage,
      isFromOtherUser: isMessageFromOtherUser,
    );
  }

  Widget _buildLoadMoreFooter() {
    return Center(
      child: _isFetchingMessages
          ? const CircularProgressIndicator()
          : TextButton(
              onPressed: _fetchAndDisplayMessages,
              child: const Text("Load more messages"),
            ),
    );
  }

  Positioned _buildScrollToBottomButton() {
    return Positioned(
      bottom: 16,
      child: IconButton.filled(
        onPressed: _scrollFeedToLatestMessage,
        icon: const Icon(Icons.arrow_downward),
      ),
    );
  }
}

/// A single chat message row, showing an avatar, sender name, timestamp,
/// and message body.
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromOtherUser;

  const _MessageBubble({required this.message, required this.isFromOtherUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(child: _buildMessageContent(context)),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      backgroundColor: isFromOtherUser ? Colors.orange : Colors.indigo,
      child: const Icon(Icons.person, color: Colors.white),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMessageHeader(context),
        const SizedBox(height: 2),
        Text(message.content, style: const TextStyle(fontSize: 15)),
      ],
    );
  }

  Widget _buildMessageHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          isFromOtherUser ? "User A" : "User B",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 8),
        Text(
          DateFormat("M/d/yy, h:mm a").format(message.createdAt),
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Home feed screen
// ---------------------------------------------------------------------------

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

  // Debug
  bool _isCurrentUserLoggedIn = true;

  @override
  void initState() {
    super.initState();
    _fetchNextBatchOfPostImages();
    _verticalPostPageController.addListener(_onPostPageScrolled);
  }

  @override
  void dispose() {
    _verticalPostPageController.dispose();
    super.dispose();
  }

  void _onPostPageScrolled() {
    if (_visiblePostPageIndex > _fetchedPostImages.length - 2) {
      _fetchNextBatchOfPostImages();
    }
  }

  Future<List<PicsumImage>> _fetchPicsumImages(
    int picsumPage, {
    int? limit = 4,
  }) async {
    final httpResponse = await http.get(
      Uri.parse("https://picsum.photos/v2/list?page=$picsumPage&limit=$limit"),
    );

    if (httpResponse.statusCode == 200) {
      final decodedImageData = jsonDecode(httpResponse.body) as List<dynamic>;
      return decodedImageData
          .map((imageJson) => PicsumImage.fromJson(imageJson))
          .toList();
    }
    throw Exception("Failed to load images");
  }

  Future<void> _fetchNextBatchOfPostImages() async {
    if (_isFetchingPostImages) return;
    setState(() => _isFetchingPostImages = true);

    try {
      final newlyFetchedImages = await _fetchPicsumImages(_nextPicsumApiPage);
      setState(() {
        _fetchedPostImages.addAll(newlyFetchedImages);
        _nextPicsumApiPage++;
      });
    } finally {
      setState(() => _isFetchingPostImages = false);
    }
  }

  void _navigateToNextPost() {
    final targetPostIndex = (_visiblePostPageIndex + 1).clamp(
      0,
      _fetchedPostImages.length - 1,
    );
    _visiblePostPageIndex = targetPostIndex;
    _verticalPostPageController.animateToPage(
      targetPostIndex,
      duration: _kPostPageAnimationDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _navigateToPreviousPost() {
    final targetPostIndex = (_visiblePostPageIndex - 1).clamp(
      0,
      _fetchedPostImages.length - 1,
    );
    _visiblePostPageIndex = targetPostIndex;
    _verticalPostPageController.animateToPage(
      targetPostIndex,
      duration: _kPostPageAnimationDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleLoginState() {
    setState(() => _isCurrentUserLoggedIn = !_isCurrentUserLoggedIn);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildPostPageView(),
        if (kDebugMode) _buildDebugPageLabel(),
        Positioned(right: 16, child: _buildPostNavigationButtons()),
        Positioned(top: 0.0, left: 0.0, child: _buildUserHeader()),
      ],
    );
  }

  Widget _buildPostPageView() {
    if (_fetchedPostImages.isEmpty) return const FullScreenLoadingIndicator();

    return PageView.builder(
      controller: _verticalPostPageController,
      scrollDirection: Axis.vertical,
      itemCount: _fetchedPostImages.length,
      onPageChanged: (newPageIndex) =>
          setState(() => _visiblePostPageIndex = newPageIndex),
      itemBuilder: (_, postIndex) =>
          FullScreenPostPage(postImage: _fetchedPostImages[postIndex]),
    );
  }

  Widget _buildDebugPageLabel() {
    return Positioned(
      top: 16,
      child: Text(
        "Page $_visiblePostPageIndex",
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildPostNavigationButtons() {
    return Column(
      children: [
        if (_visiblePostPageIndex > 0)
          TextButton(
            onPressed: _navigateToPreviousPost,
            style: TextButton.styleFrom(shape: const CircleBorder()),
            child: const Icon(Icons.keyboard_arrow_up),
          ),
        TextButton(
          onPressed: _navigateToNextPost,
          style: TextButton.styleFrom(shape: const CircleBorder()),
          child: const Icon(Icons.keyboard_arrow_down),
        ),
      ],
    );
  }

  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildUserAvatar(),
          const SizedBox(width: 16),
          const Text("Your name", style: _kOverlayTextStyle),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    if (_isCurrentUserLoggedIn) {
      return TappableWidget(
        onPressed: _toggleLoginState,
        child: const CircleAvatar(
          backgroundImage: NetworkImage(
            "https://avatars.githubusercontent.com/u/64018564?v=4",
          ),
          radius: _kAvatarRadius,
        ),
      );
    }

    return IconButton(
      onPressed: _toggleLoginState,
      style: IconButton.styleFrom(shape: const CircleBorder()),
      icon: const Icon(Icons.person, color: Colors.white),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen post page
// ---------------------------------------------------------------------------

class FullScreenPostPage extends StatelessWidget {
  final PicsumImage postImage;

  const FullScreenPostPage({super.key, required this.postImage});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fadeInDuration: Duration.zero,
      imageUrl: postImage.downloadUrl,
      fit: BoxFit.cover,
      progressIndicatorBuilder: (_, _, downloadProgress) =>
          FullScreenLoadingIndicator(
            loadingProgress: downloadProgress.progress,
          ),
      imageBuilder: (_, resolvedImageProvider) => _PostImageStack(
        imageProvider: resolvedImageProvider,
        author: postImage.author,
      ),
    );
  }
}

/// The [Stack] that overlays the author credit on top of the full-screen
/// post image.
class _PostImageStack extends StatelessWidget {
  final ImageProvider imageProvider;
  final String author;

  const _PostImageStack({required this.imageProvider, required this.author});

  @override
  Widget build(BuildContext context) {
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
            child: Text(author, style: _kOverlayTextStyle),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared utility widgets
// ---------------------------------------------------------------------------

/// A full-screen black container with a centred [CircularProgressIndicator].
/// Used both for initial image loading and per-image download progress.
class FullScreenLoadingIndicator extends StatelessWidget {
  final double? loadingProgress;

  const FullScreenLoadingIndicator({super.key, this.loadingProgress});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(child: CircularProgressIndicator(value: loadingProgress)),
    );
  }
}

/// Wraps any [child] widget with mouse-click semantics: a pointer cursor on
/// desktop and a tap gesture recogniser on all platforms.
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
