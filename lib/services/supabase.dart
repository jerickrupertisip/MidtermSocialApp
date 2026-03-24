import "dart:io";

import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:uniso_social_media_app/models/message.dart";
import "package:uniso_social_media_app/models/profile.dart";
import "package:uniso_social_media_app/models/unison_group.dart";

class SupabaseService {
  SupabaseService._();

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
    var id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null) {
      throw "Currenly not logged in";
    }

    final rows = await Supabase.instance.client
        .from("unions")
        .select("id, name, ...union_members!inner()")
        .eq("union_members.user_id", id);
    return UnisonGroup.fromList(rows);
  }

  static RealtimeChannel? openMessageChannel(String? groupId) {
    if (groupId == null) return null;
    return Supabase.instance.client.channel(
      "room:$groupId:messages",
      opts: RealtimeChannelConfig(self: true),
    );
  }

  static Future<void> createUnison({required String name}) async {
    var id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null) {
      throw "Currenly not logged in";
    }

    var unisons = await Supabase.instance.client
        .from("unisons")
        .select("name")
        .eq("name", name);

    if (unisons.isNotEmpty) {
      throw "Unison named '$name' already exists, choose another name.";
    }

    await Supabase.instance.client.from("unisons").insert({
      "name": name,
      "creator_id": id,
    });
  }

  static Future<Message> sendMedia({
    required String mediaPath,
    required String groupId,
  }) async {
    // 1. Insert the message first to get the generated id
    var newMessage = await Supabase.instance.client
        .from("messages")
        .insert({
          "message_type": "media",
          "content": null,
          "media_url": null, // leave null until we have the real URL
          "union_id": groupId,
          "user_id": Supabase.instance.client.auth.currentUser?.id,
        })
        .select()
        .single();

    final messageId = newMessage["id"].toString();

    // 2. Upload the file using the message id as the filename
    final fileExtension = mediaPath.contains(".")
        ? ".${mediaPath.split(".").last}"
        : "";
    final newPath = "$messageId$fileExtension";

    await Supabase.instance.client.storage
        .from("medias")
        .upload(newPath, File(mediaPath));

    // 3. Get the public URL
    final publicUrl = Supabase.instance.client.storage
        .from("medias")
        .getPublicUrl(newPath);

    // 4. Update the message row with the public URL
    newMessage = await Supabase.instance.client
        .from("messages")
        .update({"media_url": publicUrl})
        .eq("id", messageId)
        .select()
        .single();

    final user = Supabase.instance.client.auth.currentUser!;
    final profile = Profile.fromUser(user);

    return Message.fromMap(newMessage, profile: profile);
  }

  static Future<Message> sendMessage({
    required String? content,
    required String groupId,
  }) async {
    var newMessage = await Supabase.instance.client
        .from("messages")
        .insert({
          "message_type": "message",
          "content": content,
          "media_url": null,
          "union_id": groupId,
          "user_id": Supabase.instance.client.auth.currentUser?.id,
        })
        .select()
        .single();
    var user = Supabase.instance.client.auth.currentUser!;
    var profile = Profile.fromUser(user);

    return Message.fromMap(newMessage, profile: profile);
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
          "id, message_type, media_url, content, created_at, ...profiles!inner(user_id:id, username, avatar_url)",
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

    await Supabase.instance.client.from("profiles").insert({
      "id": response.user?.id,
      "username": username,
      "avatar_url": avatarUrl,
    });
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
    await Supabase.instance.client.auth.signInWithPassword(
      email: emailAddress,
      password: password,
    );
  }

  static Future<void> signOut() async {
    var _ = await Supabase.instance.client.auth.signOut();
  }
}
