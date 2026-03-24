import "dart:io";

import "package:mime/mime.dart";
import "package:path/path.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:uniso_social_media_app/models/message.dart";
import "package:uniso_social_media_app/models/post.dart";
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

  static Future<void> joinUnion({required String unionId}) async {
    var id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null) {
      throw "Currenly not logged in";
    }

    await Supabase.instance.client.from("union_members").insert({
      "union_id": unionId,
      "user_id": id,
    });
  }

  static Future<bool> isJoined({required String unionId}) async {
    var id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null) {
      throw "Currenly not logged in";
    }

    var result = await Supabase.instance.client
        .from("union_members")
        .select("*")
        .eq("union_id", unionId)
        .eq("user_id", id)
        .maybeSingle();

    return result != null;
  }

  static Future<void> createUnison({required String name}) async {
    var id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null) {
      throw "Currenly not logged in";
    }

    var unisons = await Supabase.instance.client
        .from("unions")
        .select("name")
        .eq("name", name)
        .maybeSingle();

    if (unisons != null) {
      throw "Unison named '$name' already exists, choose another name.";
    }

    var newUnion = await Supabase.instance.client
        .from("unions")
        .insert({"name": name, "creator_id": id})
        .select()
        .maybeSingle();

    if (newUnion == null) {
      throw "Union wasn't created successfully";
    }
    await joinUnion(unionId: newUnion["id"]);
  }

  static Future<Message> sendMedia({
    required PlatformFile file,
    required String groupId,
  }) async {
    var newMessage = await Supabase.instance.client
        .from("messages")
        .insert({
          "message_type": "media",
          "content": null,
          "media_url": null,
          "union_id": groupId,
          "user_id": Supabase.instance.client.auth.currentUser?.id,
        })
        .select()
        .single();

    var messageId = newMessage["id"].toString();

    var mimeType = lookupMimeType(file.name)!;

    var ext = extension(mimeType);
    var fileId = "$messageId.$ext";

    var bytes = file.bytes;
    if (bytes != null) {
      await Supabase.instance.client.storage
          .from("medias")
          .uploadBinary(fileId, bytes);
    } else {
      await Supabase.instance.client.storage
          .from("medias")
          .upload(fileId, File(file.path!));
    }

    var publicUrl = Supabase.instance.client.storage
        .from("medias")
        .getPublicUrl(fileId);

    newMessage = await Supabase.instance.client
        .from("messages")
        .update({"media_url": publicUrl})
        .eq("id", messageId)
        .select()
        .single();

    var user = Supabase.instance.client.auth.currentUser!;
    var profile = Profile.fromUser(user);

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

  static Future<List<Post>> fetchPosts({
    required String unisonId,
    required int alreadyLoaded,
    int pageSize = 3,
  }) async {
    final posts = await Supabase.instance.client
        .from("messages")
        .select("""
          id,
          media_url,
          created_at,
          ...unions!inner(
            union_id:id,
            union_name:name
          ),
          ...profiles!inner(
            author_name:username,
            avatar_url
          )
          """)
        .eq("message_type", "media")
        .range(alreadyLoaded, alreadyLoaded + pageSize - 1);

    return Post.fromList(posts).reversed.toList();
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
        .range(alreadyLoaded, alreadyLoaded + pageSize - 1);

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
