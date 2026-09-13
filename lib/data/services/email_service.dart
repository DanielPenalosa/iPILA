import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/config/secrets.dart';

/// Sends email notifications via Gmail API using OAuth2.
/// Credentials are stored in lib/core/config/secrets.dart (git-ignored).
class EmailService {
  static const _tokenUrl = 'https://oauth2.googleapis.com/token';
  static const _gmailSendUrl =
      'https://gmail.googleapis.com/gmail/v1/users/me/messages/send';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Get a fresh access token ──────────────────────────────────────────────

  Future<String?> _getAccessToken() async {
    try {
      final res = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id':     kGmailClientId,
          'client_secret': kGmailClientSecret,
          'refresh_token': kGmailRefreshToken,
          'grant_type':    'refresh_token',
        },
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['access_token'] as String?;
      }
      debugPrint('[EmailService] Token error: ${res.body}');
      return null;
    } catch (e) {
      debugPrint('[EmailService] Token exception: $e');
      return null;
    }
  }

  // ── Build & send a raw Gmail message ─────────────────────────────────────

  Future<bool> sendEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String htmlBody,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) return false;

      final message = [
        'From: iPILA Notifications <$kGmailSenderEmail>',
        'To: $toName <$toEmail>',
        'Subject: $subject',
        'MIME-Version: 1.0',
        'Content-Type: text/html; charset=UTF-8',
        '',
        htmlBody,
      ].join('\r\n');

      final encoded = base64Url
          .encode(utf8.encode(message))
          .replaceAll('+', '-')
          .replaceAll('/', '_')
          .replaceAll('=', '');

      final res = await http.post(
        Uri.parse(_gmailSendUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'raw': encoded}),
      );

      debugPrint('[EmailService] Send: ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[EmailService] Send error: $e');
      return false;
    }
  }

  // ── Lookup user email by userId ───────────────────────────────────────────

  Future<Map<String, String>?> _getUserInfo(String userId) async {
    try {
      final doc = await _db
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      final email = data['email'] as String?;
      final name  = data['fullName'] as String? ?? 'Citizen';
      if (email == null || email.isEmpty) return null;
      return {'email': email, 'name': name};
    } catch (_) {
      return null;
    }
  }

  // ── Send notification email to a user ────────────────────────────────────

  Future<void> sendNotificationEmail({
    required String userId,
    required String title,
    required String body,
    String? reportId,
  }) async {
    final userInfo = await _getUserInfo(userId);
    if (userInfo == null) return;

    final html = _buildNotificationHtml(
      name:     userInfo['name']!,
      title:    title,
      body:     body,
      reportId: reportId,
    );

    await sendEmail(
      toEmail:  userInfo['email']!,
      toName:   userInfo['name']!,
      subject:  'iPILA: $title',
      htmlBody: html,
    );
  }

  // ── HTML template ─────────────────────────────────────────────────────────

  String _buildNotificationHtml({
    required String name,
    required String title,
    required String body,
    String? reportId,
  }) {
    final reportSection = reportId != null
        ? '''<p style="text-align:center;margin-top:20px;">
             <a href="https://ipila-9016a.web.app/home"
                style="background:#F2B705;color:#111;padding:12px 28px;
                       border-radius:8px;text-decoration:none;font-weight:700;
                       font-size:14px;">
               View Report
             </a>
           </p>'''
        : '';

    return '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#FFFDF5;font-family:Arial,sans-serif;">
  <div style="max-width:520px;margin:32px auto;background:#fff;
              border-radius:14px;overflow:hidden;
              box-shadow:0 2px 12px rgba(0,0,0,0.06);">

    <!-- Header -->
    <div style="background:#F2B705;padding:24px 32px;">
      <h1 style="margin:0;color:#111;font-size:20px;font-weight:800;">iPILA</h1>
      <p style="margin:4px 0 0;color:#333;font-size:12px;">
        Municipality of Pila, Laguna
      </p>
    </div>

    <!-- Body -->
    <div style="padding:28px 32px;">
      <p style="color:#555;font-size:14px;margin:0 0 16px;">
        Hello, <strong>$name</strong>
      </p>

      <div style="background:#FFF7E0;border-left:4px solid #F2B705;
                  border-radius:0 8px 8px 0;padding:16px 20px;margin-bottom:20px;">
        <h2 style="margin:0 0 8px;color:#111;font-size:16px;
                   font-weight:700;">$title</h2>
        <p style="margin:0;color:#444;font-size:14px;line-height:1.6;">
          $body
        </p>
      </div>

      $reportSection
    </div>

    <!-- Footer -->
    <div style="background:#F9F9F9;padding:16px 32px;text-align:center;">
      <p style="margin:0;color:#aaa;font-size:11px;">
        This is an automated notification from iPILA — Municipality of Pila, Laguna.<br>
        Do not reply to this email.
      </p>
    </div>

  </div>
</body>
</html>
''';
  }
}
