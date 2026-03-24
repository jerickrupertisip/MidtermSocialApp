import "dart:convert";
import "dart:io";
import "dart:ui";
import "package:cached_network_image/cached_network_image.dart";
import "package:easy_refresh/easy_refresh.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:http/http.dart" as http;
import "package:uniso_social_media_app/components/glass_overlay.dart";
import "package:uniso_social_media_app/models/message.dart";
import "package:uniso_social_media_app/models/picsum_image.dart";
import "package:uniso_social_media_app/models/post.dart";
import "package:uniso_social_media_app/models/profile.dart";
import "package:uniso_social_media_app/models/unison_group.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:intl/intl.dart";
import "package:uniso_social_media_app/screens/auth/sign_in_screen.dart";
import "package:uniso_social_media_app/screens/profile_screen.dart";
import "package:uniso_social_media_app/services/supabase.dart";
import "package:uniso_social_media_app/utils.dart";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

final _kPostPageAnimationDuration = Duration(milliseconds: 300);
final _kScrollAnimationDuration = Duration(milliseconds: 300);
final _kNavAnimationDuration = Duration(milliseconds: 300);
final _kSidebarWidth = 250.0;
final _kMemberPanelWidth = 250.0;
final _kAvatarRadius = 24.0;
final _kOverlayTextStyle = TextStyle(
  color: Colors.white,
  shadows: [Shadow(offset: Offset.fromDirection(5), blurRadius: 6)],
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
      home: StreamBuilder<AuthState>(
        // Listening directly to Supabase auth changes
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // The session contains the current user data
          final session = snapshot.data?.session;
          final bool isLoggedIn = session != null;

          return Scaffold(
            body: _buildPageView(session?.user),
            bottomNavigationBar: isLoggedIn ? _buildBottomNavBar() : null,
          );
        },
      ),
    );
  }

  Widget _buildPageView(User? user) {
    return PageView(
      controller: _bottomNavPageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        HomeFeedScreen(user: user),
        UnisonsScreen(),
      ],
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

  void _onUnionCreationSucess() async {
    await _fetchGroups();
  }

  void _openCreateUnisonDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          CreateNewUnisonDialog(onUnionCreationSucess: _onUnionCreationSucess),
    );
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
  final void Function() onUnionCreationSucess;
  const CreateNewUnisonDialog({super.key, required this.onUnionCreationSucess});

  @override
  State<CreateNewUnisonDialog> createState() => _CreateNewUnisonDialogState();
}

class _CreateNewUnisonDialogState extends State<CreateNewUnisonDialog> {
  final _createUnisonFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  void _onConfirmCreate() async {
    if (_createUnisonFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await SupabaseService.createUnison(name: _nameController.text);
        if (mounted) {
          Navigator.of(context).pop();
          widget.onUnionCreationSucess();
        }
      } catch (e) {
        if (mounted) debugLog(context, e.toString());
      } finally {
        setState(() => _isLoading = false);
      }
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
    return SizedBox(
      width: 300,
      child: Form(
        key: _createUnisonFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_buildNameField()],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(labelText: "Name", hintText: "Name"),
      validator: FormBuilderValidators.minLength(6),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text("Cancel"),
      ),
      ElevatedButton(
        onPressed: _isLoading ? null : _onConfirmCreate,
        child: _isLoading ? CircularProgressIndicator() : Text("Create"),
      ),
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
  final List<PlatformFile> _selectedFiles = [];

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

    final messageContent = _outgoingMessageController.text.trim();
    final hasFiles = _selectedFiles.isNotEmpty;
    final hasText = messageContent.isNotEmpty;

    // Abort if there's nothing to send
    if (!hasFiles && !hasText) return;

    _outgoingMessageController.clear();
    setState(() => _isMessageSending = true);

    try {
      if (hasFiles) {
        for (var file in _selectedFiles) {
          final insertedMessageData = await SupabaseService.sendMedia(
            file: file,
            groupId: groupId,
          );

          SupabaseService.broadcastMessage(
            channel: channel,
            messageData: insertedMessageData.toMap(),
          );
        }

        _selectedFiles.clear();
      }

      if (hasText) {
        final insertedMessageData = await SupabaseService.sendMessage(
          content: messageContent,
          groupId: groupId,
        );
        SupabaseService.broadcastMessage(
          channel: channel,
          messageData: insertedMessageData.toMap(),
        );
      }
    } catch (sendError) {
      if (mounted) {
        debugLog(context, sendError.toString());
        setState(() => _outgoingMessageController.text = messageContent);
      }
    } finally {
      if (mounted) setState(() => _isMessageSending = false);
    }
  }

  void _onUploadPressed() async {
    var selectedFile = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    var path = selectedFile?.files.single;
    if (path != null) {
      setState(() {
        _selectedFiles.add(path);
      });
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
        _buildMediaList(),
        SizedBox(height: 8),
        _buildMessageInputRow(),
      ],
    );
  }

  Widget _buildMediaList() {
    return Row(
      spacing: 8,
      children: _selectedFiles.asMap().entries.map((entry) {
        int index = entry.key;
        var file = entry.value;

        return MediaItem(
          index: index,
          file: file,
          onRemove: (index) => setState(() {
            _selectedFiles.removeAt(index);
          }),
        );
      }).toList(), // Converts the Map iterable back into a List<Widget>
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
      spacing: 8,
      children: [
        IconButton.filled(
          onPressed: _isGroupSelected ? _onUploadPressed : null,
          icon: Icon(Icons.add),
        ),
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
        IconButton.filled(
          onPressed: _isGroupSelected
              ? (_isMessageSending ? null : _submitOutgoingMessage)
              : null,
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }
}

class MediaItem extends StatefulWidget {
  final int index;
  final PlatformFile file;
  final void Function(int) onRemove;

  const MediaItem({
    super.key,
    required this.index,
    required this.file,
    required this.onRemove,
  });

  @override
  State<MediaItem> createState() => _MediaItemState();
}

class _MediaItemState extends State<MediaItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildImage(),
          if (_isHovered)
            IconButton(
              onPressed: () => widget.onRemove(widget.index),
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final bytes = widget.file.bytes;
    final path = widget.file.path;

    // 1. Always prefer bytes if available (Works on Web and Mobile)
    if (bytes != null) {
      return Image.memory(bytes, width: 60, height: 60, fit: BoxFit.cover);
    }

    // 2. Fallback to File path for Mobile/Desktop if bytes weren't loaded
    if (path != null) {
      return Image.file(File(path), width: 60, height: 60, fit: BoxFit.cover);
    }

    return const SizedBox(
      width: 60,
      height: 60,
      child: Icon(Icons.broken_image),
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
        const SizedBox(height: 4),
        // Switch between Text and Image based on the message type
        switch (message.messageType) {
          MessageType.message => Text(
            message.content ?? '',
            style: const TextStyle(fontSize: 15),
          ),
          MessageType.media => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.mediaUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image),
            ),
          ),
        },
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
  final User? user;
  const HomeFeedScreen({super.key, required this.user});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final _verticalPostPageController = PageController(initialPage: 0);
  final List<Post> _fetchedPosts = [];

  int _visiblePostPageIndex = 0;
  bool _isFetchingPosts = false;
  bool _hasNoMorePosts = false;

  @override
  void initState() {
    super.initState();
    _fetchNextBatchOfPosts();
    _verticalPostPageController.addListener(_onPostPageScrolled);
  }

  @override
  void dispose() {
    _verticalPostPageController.dispose();
    super.dispose();
  }

  void _onPostPageScrolled() {
    if (_visiblePostPageIndex > _fetchedPosts.length - 2) {
      _fetchNextBatchOfPosts();
    }
  }

  Future<void> _fetchNextBatchOfPosts() async {
    if (_isFetchingPosts) return;
    if (!mounted) return;

    setState(() {
      _isFetchingPosts = true;
      _hasNoMorePosts = false;
    });

    try {
      final newPosts = await SupabaseService.fetchPosts(
        unisonId: '', // business logic TBD
        alreadyLoaded: _fetchedPosts.length,
      );
      if (!mounted) return;
      if (newPosts.isEmpty) {
        setState(() => _hasNoMorePosts = true);
      } else {
        setState(() => _fetchedPosts.addAll(newPosts));
      }
    } finally {
      if (mounted) setState(() => _isFetchingPosts = false);
    }
  }

  void _navigateToNextPost() {
    // If we're at the last real post and showing "no more posts", try fetching
    if (_hasNoMorePosts && _visiblePostPageIndex >= _fetchedPosts.length - 1) {
      _fetchNextBatchOfPosts();
      return;
    }

    final targetPostIndex = (_visiblePostPageIndex + 1).clamp(
      0,
      _fetchedPosts.length - 1,
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
      _fetchedPosts.length - 1,
    );
    _visiblePostPageIndex = targetPostIndex;
    _verticalPostPageController.animateToPage(
      targetPostIndex,
      duration: _kPostPageAnimationDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _goToProfilePage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ProfileScreen()));
  }

  void _goToLoginPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => SignInScreen()));
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
    if (_fetchedPosts.isEmpty && _isFetchingPosts) {
      return const FullScreenLoadingIndicator();
    }

    if (_fetchedPosts.isEmpty && _hasNoMorePosts) {
      return const _NoMorePostsIndicator();
    }

    // +1 item count when _hasNoMorePosts to show the end screen as last "page"
    final itemCount = _fetchedPosts.length + (_hasNoMorePosts ? 1 : 0);

    return PageView.builder(
      controller: _verticalPostPageController,
      scrollDirection: Axis.vertical,
      itemCount: itemCount,
      onPageChanged: (newPageIndex) {
        setState(() => _visiblePostPageIndex = newPageIndex);
        // User swiped to the "no more posts" page — attempt a re-fetch
        if (_hasNoMorePosts && newPageIndex == _fetchedPosts.length) {
          _fetchNextBatchOfPosts();
        }
      },
      itemBuilder: (_, postIndex) {
        if (postIndex == _fetchedPosts.length) {
          return _isFetchingPosts
              ? const FullScreenLoadingIndicator()
              : const _NoMorePostsIndicator();
        }
        return FullScreenPostPage(post: _fetchedPosts[postIndex]);
      },
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
    String? username;
    User? user = widget.user;
    if (user != null) {
      username = Profile.fromUser(user).username;
    }

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
    String? username;
    String? avatarUrl;
    User? user = widget.user;
    if (user != null) {
      var profile = Profile.fromUser(user);
      username = profile.username;
      avatarUrl = profile.avatarUrl;
    }

    return TappableWidget(
      onPressed: user != null ? _goToProfilePage : _goToLoginPage,
      child: CircleAvatar(
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        radius: _kAvatarRadius,
        child: username != null
            ? Text(getInitials(username))
            : const Icon(Icons.person, color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen post page
// ---------------------------------------------------------------------------

class FullScreenPostPage extends StatelessWidget {
  final Post post;

  const FullScreenPostPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fadeInDuration: Duration.zero,
      imageUrl: post.mediaUrl,
      fit: BoxFit.cover,
      progressIndicatorBuilder: (_, _, downloadProgress) =>
          FullScreenLoadingIndicator(
            loadingProgress: downloadProgress.progress,
          ),
      imageBuilder: (_, resolvedImageProvider) =>
          PostImageStack(imageProvider: resolvedImageProvider, post: post),
    );
  }
}

class PostImageStack extends StatefulWidget {
  final ImageProvider imageProvider;
  final Post post;

  const PostImageStack({
    super.key,
    required this.imageProvider,
    required this.post,
  });

  @override
  State<PostImageStack> createState() => _PostImageStackState();
}

class _PostImageStackState extends State<PostImageStack> {
  bool? _isJoined; // null = not yet loaded

  Future<bool> _checkIsJoined() async {
    final result = await SupabaseService.isJoined(unionId: widget.post.unionId);
    _isJoined = result;
    return result;
  }

  void _onJoiningUnison() async {
    await SupabaseService.joinUnion(unionId: widget.post.unionId);
    setState(() => _isJoined = true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image(image: widget.imageProvider, fit: BoxFit.cover),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: GlassOverlay(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.authorName,
                    style: _kOverlayTextStyle.merge(
                      const TextStyle(fontSize: 24),
                    ),
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Text(
                        "From ${widget.post.unionName}",
                        style: _kOverlayTextStyle,
                      ),
                      if (Supabase.instance.client.auth.currentUser != null)
                        FutureBuilder<bool>(
                          future: _checkIsJoined(),
                          builder: (context, snapshot) {
                            if (_isJoined == true) {
                              return const SizedBox.shrink();
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox.shrink();
                            }
                            if (snapshot.hasData && snapshot.data == false) {
                              return ElevatedButton(
                                onPressed: _onJoiningUnison,
                                child: const Text("Join Union"),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// No more posts indicator
// ---------------------------------------------------------------------------

class _NoMorePostsIndicator extends StatelessWidget {
  const _NoMorePostsIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.white54, size: 48),
          SizedBox(height: 12),
          Text(
            "You're all caught up!",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          SizedBox(height: 4),
          Text(
            "Swipe down to check for new posts",
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
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
