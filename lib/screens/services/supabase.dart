import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:uniso_social_media_app/models/message.dart";
import "package:uniso_social_media_app/models/profile.dart";
import "package:uniso_social_media_app/models/unison_group.dart";

class SupabaseService {
  SupabaseService._();

  static Profile? currentSignedInUser;

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: "supabase/.env", isOptional: true);
    } finally {}

    final supabaseApiUrl = dotenv.env["API_URL"];
    final supabaseAnonKey = dotenv.env["ANON_KEY"];

    if (supabaseApiUrl != null && supabaseAnonKey != null) {
      await Supabase.initialize(url: supabaseApiUrl, anonKey: supabaseAnonKey);
    }
  }

  static Future<List<UnisonGroup>> fetchUnisonGroups() async {
    final rows = await Supabase.instance.client.from("unions").select("*");
    return UnisonGroup.fromList(rows);
  }

  static RealtimeChannel? openMessageChannel(String? groupId) {
    if (groupId == null) return null;
    return Supabase.instance.client.channel(
      "room:$groupId:messages",
      opts: RealtimeChannelConfig(self: true),
    );
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String content,
    required String groupId,
  }) async {
    return await Supabase.instance.client
        .from("messages")
        .insert({"content": content, "union_id": groupId})
        .select()
        .single();
  }

  static void broadcastMessage({
    required RealtimeChannel channel,
    required Map<String, dynamic> messageData,
  }) {
    channel.sendBroadcastMessage(event: "message_sent", payload: messageData);
  }

  static Future<List<Message>> fetchMessages({
    required String unisonId,
    required int alreadyLoaded,
    int pageSize = 20,
  }) async {
    final rows = await Supabase.instance.client
        .from("messages")
        .select(
          "id, content, created_at, ...profiles!inner(user_id:id, username, avatar_url)",
        )
        .eq("union_id", unisonId)
        .order("created_at", ascending: false)
        .range(alreadyLoaded, alreadyLoaded + pageSize);

    return Message.fromList(rows).reversed.toList();
  }

  static Future<List<Profile>> fetchMembers({required String unisonId}) async {
    final rows = await Supabase.instance.client
        .from("union_members")
        .select("...profiles!inner(id, username, avatar_url)")
        .eq("union_id", unisonId)
        .order("profiles(username)", ascending: true);

    return Profile.fromList(rows);
  }

  static Future<void> signUp({
    required String username,
    required String? avatarUrl,
    required String emailAddress,
    required String password,
  }) async {
    var response = await Supabase.instance.client.auth.signUp(
      email: emailAddress,
      password: password,
      data: {"username": username, "avatar_url": avatarUrl},
    );

    var user = response.user;
    if (user != null) {
      currentSignedInUser = Profile.fromUser(user);
    }
  }

  static Future<bool> isUsernameExist(String username) async {
    var usernames = await Supabase.instance.client
        .from("profiles")
        .select("username")
        .eq("username", username);
    return usernames.isNotEmpty;
  }

  static Future<void> signIn({
    required String emailAddress,
    required String password,
  }) async {
    var response = await Supabase.instance.client.auth.signInWithPassword(
      email: emailAddress,
      password: password,
    );

    var user = response.user;
    if (user != null) {
      currentSignedInUser = Profile.fromUser(user);
    }
  }

  static Future<void> signOut() async {
    var _ = await Supabase.instance.client.auth.signOut();
    currentSignedInUser = null;
  }
}
