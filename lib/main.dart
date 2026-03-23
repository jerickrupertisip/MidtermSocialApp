import "dart:convert";
import "package:cached_network_image/cached_network_image.dart";
import "package:easy_refresh/easy_refresh.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:uniso_social_media_app/models/message.dart";
import "package:uniso_social_media_app/models/picsum_image.dart";
import "package:uniso_social_media_app/models/profile.dart";
import "package:uniso_social_media_app/models/unison_group.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:intl/intl.dart";
import "package:uniso_social_media_app/screens/auth/sign_in_screen.dart";
import "package:uniso_social_media_app/screens/profile_screen.dart";
import "package:uniso_social_media_app/screens/services/supabase.dart";
import "package:uniso_social_media_app/utils.dart";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _kPostPageAnimationDuration = Duration(milliseconds: 300);
const _kScrollAnimationDuration = Duration(milliseconds: 300);
const _kNavAnimationDuration = Duration(milliseconds: 300);
const _kSidebarWidth = 250.0;
const _kMemberPanelWidth = 250.0;
const _kDropShadow = Shadow(offset: Offset(1.9, -0.4), blurRadius: 6);
const _kAvatarRadius = 24.0;
const _kOverlayTextStyle = TextStyle(
  color: Colors.white,
  shadows: [_kDropShadow],
);

// ---------------------------------------------------------------------------
// SupabaseService — all Supabase-specific logic lives here
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Initialisation
// ---------------------------------------------------------------------------

void main() async {
  await SupabaseService.initialize();
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
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: _buildPageView(),
        bottomNavigationBar: SupabaseService.isSignedIn
            ? _buildBottomNavBar()
            : null,
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

class UnisonsScreen extends StatefulWidget {
  const UnisonsScreen({super.key});

  @override
  State<UnisonsScreen> createState() => _UnisonsScreenState();
}

class _UnisonsScreenState extends State<UnisonsScreen> {
  UnisonGroup? _selectedUnisonGroup;

  void _onUnisonGroupSelected(UnisonGroup unisonGroup) {
    setState(() => _selectedUnisonGroup = unisonGroup);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: _kSidebarWidth,
          child: UnisonGroupSidebar(
            onUnisonGroupSelected: _onUnisonGroupSelected,
          ),
        ),
        const VerticalDivider(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: UnisonChatInputScreen(unisonGroup: _selectedUnisonGroup),
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
  final void Function(UnisonGroup) onUnisonGroupSelected;

  const UnisonGroupSidebar({super.key, required this.onUnisonGroupSelected});

  @override
  State<UnisonGroupSidebar> createState() => _UnisonGroupSidebarState();
}

class _UnisonGroupSidebarState extends State<UnisonGroupSidebar> {
  int? _selectedGroupIndex;
  List<UnisonGroup> _unisonGroups = [];
  final ScrollController _unisonGroupsScrollController = ScrollController();

  void _onGroupTapped(int groupIndex) {
    if (_selectedGroupIndex == groupIndex) return;
    setState(() => _selectedGroupIndex = groupIndex);
    widget.onUnisonGroupSelected(_unisonGroups[groupIndex]);
  }

  void _openCreateUnisonDialog() {
    showDialog(context: context, builder: (_) => const CreateNewUnisonDialog());
  }

  /// Delegates the network call to [SupabaseService]; this widget only
  /// handles the resulting state update and error display.
  Future<void> _fetchGroups() async {
    try {
      final groups = await SupabaseService.fetchUnisonGroups();
      setState(() => _unisonGroups = groups);
    } catch (fetchError) {
      if (mounted) debugLog(context, fetchError.toString());
    }
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
    return EasyRefresh(
      header: MaterialHeader(),
      refreshOnStart: true,
      footer: MaterialFooter(
        position: IndicatorPosition.above,
        clamping: false,
      ),
      onRefresh: _fetchGroups,
      child: ListView.builder(
        controller: _unisonGroupsScrollController,
        itemCount: _unisonGroups.length,
        padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
        itemBuilder: _buildGroupListItem,
      ),
    );
  }

  Widget _buildGroupListItem(BuildContext listContext, int groupIndex) {
    final unisonGroup = _unisonGroups[groupIndex];
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(unisonGroup.name),
      selected: _selectedGroupIndex == groupIndex,
      selectedTileColor: Theme.of(listContext).colorScheme.primary,
      selectedColor: Theme.of(listContext).colorScheme.onPrimary,
      onTap: () => _onGroupTapped(groupIndex),
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
  final UnisonGroup? unisonGroup;

  const UnisonChatInputScreen({super.key, required this.unisonGroup});

  @override
  State<UnisonChatInputScreen> createState() => _UnisonChatInputScreenState();
}

class _UnisonChatInputScreenState extends State<UnisonChatInputScreen> {
  final TextEditingController _outgoingMessageController =
      TextEditingController();
  RealtimeChannel? _supabaseRoomChannel;
  bool _isMessageSending = false;

  bool get _isGroupSelected => widget.unisonGroup != null;

  @override
  void didUpdateWidget(UnisonChatInputScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unisonGroup?.id != widget.unisonGroup?.id) {
      _supabaseRoomChannel?.unsubscribe();
      // Delegate channel creation to the service.
      _supabaseRoomChannel = SupabaseService.openMessageChannel(
        widget.unisonGroup?.id,
      );
    }
  }

  @override
  void dispose() {
    _outgoingMessageController.dispose();
    _supabaseRoomChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _submitOutgoingMessage() async {
    final groupId = widget.unisonGroup?.id;
    if (groupId == null) return;

    final channel = _supabaseRoomChannel;
    if (channel == null) return;

    final messageContent = _outgoingMessageController.text;
    if (messageContent.isEmpty) return;

    _outgoingMessageController.clear();
    setState(() => _isMessageSending = true);

    try {
      // Delegate persistence and broadcast to the service.
      final insertedMessageData = await SupabaseService.sendMessage(
        content: messageContent,
        groupId: groupId,
      );
      SupabaseService.broadcastMessage(
        channel: channel,
        messageData: insertedMessageData,
      );
    } catch (sendError) {
      if (mounted) {
        debugLog(context, sendError.toString());
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
      builder: (_) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          child: SizedBox(
            width: _kMemberPanelWidth,
            height: MediaQuery.of(context).size.height,
            child: UnisonMemberList(unisonID: widget.unisonGroup?.id),
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
        _buildFeedArea(),
        _buildMessageInputRow(),
      ],
    );
  }

  Widget _buildMembersListButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _isGroupSelected ? _openMemberListPanel : null,
          child: const Text("Members List"),
        ),
      ],
    );
  }

  Widget _buildFeedArea() {
    final groupId = widget.unisonGroup?.id;
    final channel = _supabaseRoomChannel;

    if (groupId == null || channel == null) {
      return const Expanded(
        child: Center(child: Text("Select a Unison Group on the left")),
      );
    }

    return UnisonMessageFeed(
      key: ValueKey(groupId),
      unisonID: groupId,
      realtimeRoomChannel: channel,
    );
  }

  Widget _buildMessageInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            enabled: _isGroupSelected,
            controller: _outgoingMessageController,
            onSubmitted: (_) => _submitOutgoingMessage(),
            decoration: const InputDecoration(
              hintText: "Enter your message...",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          onPressed: _isGroupSelected
              ? (_isMessageSending ? null : _submitOutgoingMessage)
              : null,
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Member list panel
// ---------------------------------------------------------------------------

class UnisonMemberList extends StatefulWidget {
  final String? unisonID;
  const UnisonMemberList({super.key, required this.unisonID});

  @override
  State<UnisonMemberList> createState() => _UnisonMemberListState();
}

class _UnisonMemberListState extends State<UnisonMemberList> {
  List<Profile> _unisonMembers = [];

  void _fetchMembers() async {
    try {
      var members = await SupabaseService.fetchMembers(
        unisonId: widget.unisonID ?? "",
      );

      setState(() {
        _unisonMembers = members;
      });
    } catch (e) {
      if (mounted) {
        debugLog(context, "Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
      header: MaterialHeader(),
      refreshOnStart: true,
      footer: MaterialFooter(
        position: IndicatorPosition.above,
        clamping: false,
      ),
      onRefresh: _fetchMembers,
      child: ListView.separated(
        itemCount: _unisonMembers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, index) =>
            _MemberListItem(member: _unisonMembers[index]),
      ),
    );
  }
}

class _MemberListItem extends StatelessWidget {
  final Profile member;
  const _MemberListItem({required this.member});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Row(children: [const Icon(Icons.person), Text(member.username)]),
    );
  }
}

// ---------------------------------------------------------------------------
// Message feed
// ---------------------------------------------------------------------------

class UnisonMessageFeed extends StatefulWidget {
  final RealtimeChannel realtimeRoomChannel;
  final String unisonID;

  const UnisonMessageFeed({
    super.key,
    required this.unisonID,
    required this.realtimeRoomChannel,
  });

  @override
  State<UnisonMessageFeed> createState() => _UnisonMessageFeedState();
}

class _UnisonMessageFeedState extends State<UnisonMessageFeed> {
  final ScrollController _messageFeedScrollController = ScrollController();
  final List<Message> _loadedMessages = [];
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

  /// Delegates the database query to [SupabaseService]; this widget only
  /// manages list state and loading/error display.
  Future<void> _fetchMoreMessages() async {
    setState(() => _isFetchingMessages = true);

    try {
      final fetchedMessages = await SupabaseService.fetchMessages(
        unisonId: widget.unisonID,
        alreadyLoaded: _loadedMessages.length,
      );
      setState(() => _loadedMessages.insertAll(0, fetchedMessages));
    } catch (fetchError) {
      if (mounted) debugLog(context, fetchError.toString());
    } finally {
      if (mounted) setState(() => _isFetchingMessages = false);
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
    return EasyRefresh(
      header: MaterialHeader(),
      refreshOnStart: true,
      footer: MaterialFooter(
        position: IndicatorPosition.above,
        clamping: false,
      ),
      onLoad: _fetchMoreMessages,
      onRefresh: _loadedMessages.isEmpty ? _fetchMoreMessages : null,
      child: ListView.builder(
        controller: _messageFeedScrollController,
        itemCount: _loadedMessages.length,
        reverse: true,
        padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
        itemBuilder: _buildMessageListItem,
      ),
    );
  }

  Widget _buildMessageListItem(
    BuildContext feedContext,
    int reversedMessageIndex,
  ) {
    final isMessageFromOtherUser = reversedMessageIndex % 2 == 0;
    final displayedMessage =
        _loadedMessages[_loadedMessages.length - reversedMessageIndex - 1];

    return _MessageBubble(
      message: displayedMessage,
      isFromOtherUser: isMessageFromOtherUser,
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
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          message.sentBy.username,
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

  void _goToProfilePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ProfileScreen();
        },
      ),
    );
  }

  void _goToLoginPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return SignInScreen();
        },
      ),
    );
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
    String? username = SupabaseService.currentSignedInUser?.username;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildUserAvatar(),
          const SizedBox(width: 16),
          Text(username ?? "Sign In", style: _kOverlayTextStyle),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    var username = SupabaseService.currentSignedInUser?.username;
    var avatarUrl = SupabaseService.currentSignedInUser?.avatarUrl;
    return TappableWidget(
      onPressed: SupabaseService.isSignedIn ? _goToProfilePage : _goToLoginPage,
      child: CircleAvatar(
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        radius: _kAvatarRadius,
        child: username != null
            ? Text(getInitials(username))
            : Icon(Icons.person, color: Colors.white),
      ),
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
