import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final String userName;
  final double radius;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;

  const UserAvatar({
    super.key,
    this.profileImageUrl,
    required this.userName,
    required this.radius,
    this.fontSize,
    this.backgroundColor = const Color(0xff26A69A), // Default teal
    this.textColor = Colors.white,
  });

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "U";

    List<String> nameParts = name.trim().split(" ");
    if (nameParts.isEmpty) return "U";

    String initials = "";
    if (nameParts.length > 1) {
      initials = "${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}";
    } else {
      String firstWord = nameParts[0];
      if (firstWord.length >= 2) {
        initials = firstWord.substring(0, 2);
      } else {
        initials = firstWord;
      }
    }
    return initials.toUpperCase();
  }

  Color _getBackgroundColor(String name) {
    if (backgroundColor != null && backgroundColor != const Color(0xff26A69A)) {
      return backgroundColor!;
    }
    // Generate a consistent color based on the name
    final List<Color> colors = [
      Colors.red.shade400,
      Colors.purple.shade400,
      Colors.indigo.shade400,
      Colors.blue.shade400,
      Colors.teal.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.deepOrange.shade400,
      Colors.brown.shade400,
      Colors.blueGrey.shade400,
    ];
    int hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    // Check if we have a valid URL string first
    bool hasImage =
        profileImageUrl != null &&
        profileImageUrl!.isNotEmpty &&
        !profileImageUrl!.contains("assets/profile.png");

    Widget initialsWidget = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: _getBackgroundColor(userName),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _getInitials(userName),
        style: GoogleFonts.poppins(
          fontSize: fontSize ?? (radius * 0.8),
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );

    if (hasImage) {
      String finalImageUrl = profileImageUrl!;
      // Fix relative URLs from the backend
      if (!finalImageUrl.startsWith("http")) {
        // Remove leading slash if present to avoid double slashes
        if (finalImageUrl.startsWith("/")) {
          finalImageUrl = finalImageUrl.substring(1);
        }
        finalImageUrl = "https://erpsmart.in/total/$finalImageUrl";
      }

      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.network(
            finalImageUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return initialsWidget;
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        ),
      );
    }

    return initialsWidget;
  }
}
