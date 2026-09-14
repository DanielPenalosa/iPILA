import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/secrets.dart';

class EmailService {
  static const _clientId = kGmailClientId;
  static const _clientSecret = kGmailClientSecret;
  static const _refreshToken = kGmailRefreshToken;
  static const _senderEmail = kGmailSenderEmail;

  /// Exchange refresh token for a fresh access token.
  static Future<String?> _getAccessToken() async {
    final res = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'refresh_token': _refreshToken,
        'grant_type': 'refresh_token',
      },
    );
    if (res.statusCode != 200) {
      debugPrint('EmailService: token error ${res.body}');
      return null;
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['access_token']
        as String?;
  }

  /// Send a raw HTML email via Gmail API.
  static Future<bool> _send({
    required String to,
    required String subject,
    required String htmlBody,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) return false;

    final raw = [
      'From: iPILA <$_senderEmail>',
      'To: $to',
      'Subject: $subject',
      'MIME-Version: 1.0',
      'Content-Type: text/html; charset=UTF-8',
      '',
      htmlBody,
    ].join('\r\n');

    final encoded = base64Url.encode(utf8.encode(raw)).replaceAll('=', '');

    final res = await http.post(
      Uri.parse('https://gmail.googleapis.com/gmail/v1/users/me/messages/send'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'raw': encoded}),
    );

    debugPrint('EmailService: send status ${res.statusCode}');
    return res.statusCode == 200;
  }

  /// Send account approval notification email.
  static Future<bool> sendApprovalEmail({
    required String toEmail,
    required String fullName,
  }) async {
    final html = '''
<div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;padding:32px;">
  <div style="text-align:center;margin-bottom:24px;">
    <div style="display:inline-block;background:#FFF7E0;border-radius:50%;padding:16px;">
      <span style="font-size:40px;">✅</span>
    </div>
  </div>
  <h2 style="color:#111;font-size:22px;margin-bottom:4px;text-align:center;">
    Account Approved!
  </h2>
  <p style="color:#888;font-size:13px;margin-top:0;text-align:center;">
    Municipality of Pila, Laguna
  </p>
  <p style="color:#444;font-size:15px;margin-top:24px;">
    Hi <b>$fullName</b>,
  </p>
  <p style="color:#444;font-size:15px;line-height:1.6;">
    Great news! Your iPILA account has been reviewed and 
    <b style="color:#2E7D32;">approved</b> by the LGU Admin.
    You can now log in and use the app.
  </p>
  <div style="background:#F1F8E9;border:2px solid #81C784;border-radius:12px;
              padding:20px;text-align:center;margin:24px 0;">
    <p style="margin:0;font-size:15px;color:#2E7D32;font-weight:700;">
      Your account is now active 🎉
    </p>
    <p style="margin:8px 0 0;font-size:13px;color:#555;">
      Open the iPILA app and log in with your registered email.
    </p>
  </div>
  <hr style="border:none;border-top:1px solid #eee;margin:20px 0;">
  <p style="color:#bbb;font-size:11px;text-align:center;">
    iPILA — Integrated Public Information &amp; Local Access<br>
    Municipality of Pila, Laguna
  </p>
</div>''';

    return _send(
      to: toEmail,
      subject: 'Your iPILA Account Has Been Approved',
      htmlBody: html,
    );
  }
}
