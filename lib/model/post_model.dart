import 'dart:convert';
import 'dart:io';

//Post postFromJson(String str) {
//  final jsonData = json.decode(str);
//  return Post.fromJson(jsonData);
//}
//
//String postToJson(Post data) {
//  final dyn = data.toJson();
//  return json.encode(dyn);
//}

class Post {
  String imageUrl;
  String counties;



//  factory Post.fromJson(Map<String, dynamic> json) => new Post(
//    userId: json["userId"],
//    id: json["id"],
//    title: json["title"],
//    body: json["body"],
//  );
//
//  Map<String, dynamic> toJson() => {
//    "userId": userId,
//    "id": id,
//    "title": title,
//    "body": body,
//  };

//  Future getcdogs() async {
//    HttpClient http = HttpClient();
//    try {
//      var uri = Uri.http('dog.ceo', '/api/breeds/image/random');
//      var request = await http.getUrl(uri);
//      var response = await request.close();
//      var responseBody = await response.transform(utf8.decoder).join();
//      imageUrl = json.decode(responseBody)['message'];
//      return imageUrl;
//    } catch (exception) {
//      print(exception);
//    }
//  }

  Future getcounties() async {
    HttpClient http = HttpClient();
    try {
      var uri = Uri.http('roloca.coldfuse.io', '/judete');
      var request = await http.getUrl(uri);
      var response = await request.close();
      var responseBody = await response.transform(utf8.decoder).join();

      return json.decode(responseBody);
    } catch (exception) {
      print(exception);
    }
  }

  Future getcities([String county]) async {
    HttpClient http = HttpClient();
    try {
      var uri = Uri.http('roloca.coldfuse.io', '/orase/' + county);
      var request = await http.getUrl(uri);
      var response = await request.close();
      var responseBody = await response.transform(utf8.decoder).join();

      return json.decode(responseBody);
    } catch (exception) {
      print(exception);
    }
  }
}

//Post postFromJson(String str) {
//  final jsonData = jsson.decode(str);
//  return Post.fromJson(jsonData);
//}
//
//Future<Post> getPost() async {
//  final response = await http.get('https://roloca.coldfuse.io/judete');
//}