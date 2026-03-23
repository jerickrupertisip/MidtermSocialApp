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
        .select("content, created_at")
        .eq("union_id", unisonId)
        .limit(pageSize)
        .order("created_at", ascending: false)
        .range(alreadyLoaded, alreadyLoaded + pageSize);

    return Message.fromList(rows).reversed.toList();
  }

  static bool get isSignedIn => currentSignedInUser != null;

  static Future<void> signUp({
    required String username,
    required String? avatarUrl,
  }) async {
    if (currentSignedInUser != null) {
      throw "Already Signed In";
    }

    var profile = await Supabase.instance.client
        .from("profiles")
        .insert({"username": username, "avatar_url": avatarUrl})
        .select()
        .single();

    currentSignedInUser = Profile.fromJson(profile);
  }

  static Future<void> signIn({
    required String username,
    required String password,
  }) async {
    if (currentSignedInUser != null) {
      throw "Already Signed In";
    }

    var profiles = await Supabase.instance.client
        .from("profiles")
        .select("*")
        .eq("username", username);

    if (profiles.isEmpty) {
      throw "Account with $username, not found";
    }

    currentSignedInUser = Profile.fromJson(profiles[0]);
    return;
  }
}
