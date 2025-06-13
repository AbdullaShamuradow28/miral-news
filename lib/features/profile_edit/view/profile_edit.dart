import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:miral_news/theme_changer.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:miral_news/features/home_page/view/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  State<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  var usernameController = TextEditingController();
  var aboutController = TextEditingController();
  Uint8List? _pickedImageBytes; // Stores bytes of a newly picked image
  String?
  _profileImageUrl; // Stores URL of existing profile picture from backend

  // Base URL for profiles, WITHOUT trailing slash
  final String apiUrl = "http://192.168.1.109:3001/api/profiles";
  final String usersApiUrl =
      "http://192.168.1.109:3001/api/users/"; // Base URL for users

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Call this to load data from server or SharedPreferences
  }

  // New function to load profile data either from server or SharedPreferences
  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedMid = prefs.getString('mid');

    if (storedMid == null || storedMid.isEmpty) {
      print(
        'DEBUG: ProfileEdit:_loadProfileData: MID not found in SharedPreferences. Cannot load profile.',
      );
      // Keep fields empty, as this is a new profile creation flow.
      setState(() {
        usernameController.text = '';
        aboutController.text = '';
        _pickedImageBytes = null;
        _profileImageUrl = null;
      });
      return;
    }

    // First, try to fetch from the server using MID in path with trailing slash
    try {
      // Explicitly add /get_by_mid/ to the URL for GET
      final String profileGetUrl = '$apiUrl/get_by_mid/$storedMid/';
      print(
        'DEBUG: ProfileEdit:_loadProfileData: Attempting to load profile from server for MID: $storedMid at URL: $profileGetUrl',
      );
      final response = await http.get(Uri.parse(profileGetUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> profileData = jsonDecode(response.body);
        setState(() {
          usernameController.text =
              '${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}'
                  .trim();
          aboutController.text = profileData['about_me'] ?? '';

          String? imageUrl = profileData['profile_picture_url']?.toString();
          if (imageUrl != null && imageUrl.isNotEmpty) {
            // Assume the backend returns a direct URL for the image
            _profileImageUrl = imageUrl;
            _pickedImageBytes = null; // Clear picked image if loading from URL
            print(
              "DEBUG: ProfileEdit:_loadProfileData: Image URL loaded from server: $_profileImageUrl",
            );
          } else {
            // If no URL from server, try to load from SharedPreferences (base64)
            String? imageBytesString = prefs.getString('imageBytes');
            if (imageBytesString != null && imageBytesString.isNotEmpty) {
              try {
                _pickedImageBytes = base64Decode(imageBytesString);
                _profileImageUrl = null; // Clear URL if loading from base64
              } catch (e) {
                print(
                  "DEBUG: ProfileEdit:_loadProfileData: Error decoding image from SharedPreferences: $e",
                );
                _pickedImageBytes = null;
              }
            } else {
              _pickedImageBytes = null;
              _profileImageUrl = null;
            }
          }
        });
        // Save the loaded data to SharedPreferences for caching
        await prefs.setString('username', usernameController.text);
        await prefs.setString('about', aboutController.text);
        // If an image URL is loaded, ensure imageBytes in prefs is cleared
        if (_profileImageUrl != null) {
          await prefs.remove('imageBytes');
        }

        print(
          'DEBUG: ProfileEdit:_loadProfileData: Profile data loaded from server and saved to SharedPreferences.',
        );
        return; // Profile data loaded from server, no need to check SharedPreferences
      } else if (response.statusCode == 404) {
        print(
          'DEBUG: ProfileEdit:_loadProfileData: Profile not found on server for MID: $storedMid. This is likely a new profile.',
        );
        // If 404, it means no profile exists, so we proceed with empty fields.
      } else {
        print(
          'DEBUG: ProfileEdit:_loadProfileData: Server returned ${response.statusCode} when fetching profile: ${response.body}. Attempting to load from SharedPreferences.',
        );
      }
    } catch (e) {
      print(
        'DEBUG: ProfileEdit:_loadProfileData: Network error fetching profile from server: $e. Attempting to load from SharedPreferences.',
      );
    }

    // Fallback: If no profile from server, or network error, check SharedPreferences
    setState(() {
      usernameController.text = prefs.getString('username') ?? '';
      aboutController.text = prefs.getString('about') ?? '';

      String? imageBytesString = prefs.getString('imageBytes');
      if (imageBytesString != null && imageBytesString.isNotEmpty) {
        try {
          _pickedImageBytes = base64Decode(imageBytesString);
          _profileImageUrl = null; // Clear URL if loading from base64 in prefs
          print(
            "DEBUG: ProfileEdit:_loadProfileData: Image bytes loaded from SharedPreferences (fallback). Size: ${_pickedImageBytes?.lengthInBytes} bytes",
          );
        } catch (e) {
          print(
            "DEBUG: ProfileEdit:_loadProfileData: Error decoding image from SharedPreferences: $e",
          );
          _pickedImageBytes = null;
        }
      } else {
        _pickedImageBytes = null;
      }
    });
    print(
      'DEBUG: ProfileEdit:_loadProfileData: Profile data loaded from SharedPreferences (fallback).',
    );
  }

  Future<void> submitProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? mid = prefs.getString("mid");

    if (mid == null || mid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: MID пользователя не найден.')),
      );
      return;
    }

    try {
      bool profileExists = await _checkProfileExistence(mid);
      print('DEBUG: ProfileEdit:submitProfile: Profile exists: $profileExists');

      String requestUrl;
      String requestMethod;

      if (profileExists) {
        requestMethod = 'PUT';
        requestUrl = '$apiUrl/get_by_mid/$mid/'; // Use MID in the URL for PUT
      } else {
        requestMethod = 'POST';
        requestUrl = '$apiUrl/'; // POST to the base URL for create
      }

      // Conditional image validation:
      // If creating a new profile AND no image is selected/available, then show error.
      // If updating an existing profile, image is optional.
      if (!profileExists &&
          _pickedImageBytes == null &&
          _profileImageUrl == null) {
        print(
          "DEBUG: ProfileEdit:submitProfile: Error: No image selected for new profile.",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Пожалуйста, выберите изображение для нового профиля.',
            ),
          ),
        );
        return;
      }

      print(
        'DEBUG: ProfileEdit:submitProfile: Preparing $requestMethod request to URL: $requestUrl',
      );

      var request = http.MultipartRequest(requestMethod, Uri.parse(requestUrl));

      // Conditional logic for adding the image to the request
      if (_pickedImageBytes != null) {
        // Если выбрали новую картинку — прикрепляем файл
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_picture_url',
            _pickedImageBytes!,
            filename: 'profile_picture.jpg',
          ),
        );
        print('DEBUG: ProfileEdit:submitProfile: Added NEW image file.');
      } else if (_profileImageUrl != null && profileExists) {
        // If not a new image, but there's an existing URL AND it's an update
        // Send the URL to the backend so it knows to retain the existing image
        // Only send this if updating, otherwise the backend should handle creation without it
        request.fields['profile_picture_url'] = _profileImageUrl!;
        print(
          'DEBUG: ProfileEdit:submitProfile: Retaining existing profile image URL.',
        );
      }
      // If _pickedImageBytes is null and _profileImageUrl is null (or it's a new profile
      // and _profileImageUrl is null), we simply don't include the image field.
      // The backend should then handle the default or absence of an image.

      List<String> names = usernameController.text.trim().split(' ');
      String firstName = names.isNotEmpty ? names[0] : '';
      String lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      request.fields['first_name'] = firstName;
      request.fields['last_name'] = lastName;
      request.fields['mid'] = mid; // Always include mid
      request.fields['about_me'] = aboutController.text;
      request.fields['nickname'] = usernameController.text
          .toLowerCase()
          .replaceAll(" ", '');

      print("DEBUG: ProfileEdit:submitProfile: Sending profile data to API...");
      // Added print statement right before sending the request
      print(
        'DEBUG: ProfileEdit:submitProfile: Request method: ${request.method}, Request URL: ${request.url}',
      );
      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // 201 for POST (Created), 200 for PUT (OK)
        print(
          "DEBUG: ProfileEdit:submitProfile: Profile data successfully sent to API. Status: ${response.statusCode}",
        );
        // Save updated data to prefs after successful API call
        // Note: We save the *newly picked* image bytes to prefs, or clear if using URL
        if (_pickedImageBytes != null) {
          await _saveProfileToPrefs(
            base64Encode(_pickedImageBytes!),
            firstName,
            lastName,
          );
        } else if (_profileImageUrl != null) {
          // If no new image was picked, but we have an URL, save the URL to prefs (or clear imageBytes)
          // This ensures that if we loaded an image from URL, and didn't pick a new one,
          // the prefs for imageBytes are cleared, relying on the URL for display.
          await _saveProfileToPrefs(
            null,
            firstName,
            lastName,
          ); // Clear imageBytes if we're now relying on URL
        } else {
          // If no picked image and no profile URL (e.g., deleted image or never had one)
          await _saveProfileToPrefs(null, firstName, lastName);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              profileExists
                  ? 'Профиль успешно обновлен.'
                  : 'Профиль успешно создан.',
            ),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      } else {
        print(
          "DEBUG: ProfileEdit:submitProfile: Error sending profile data: ${response.statusCode}, ${responseBody.body}",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка сохранения профиля: ${response.statusCode}. ${responseBody.body}',
            ),
          ),
        );
      }
    } catch (e) {
      print(
        "DEBUG: ProfileEdit:submitProfile: Error during profile submission: $e",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при отправке данных профиля: $e')),
      );
    }
  }

  Future<bool> _checkProfileExistence(String mid) async {
    try {
      // Check profile existence using /get_by_mid/ in the URL
      final String checkUrl = '$apiUrl/get_by_mid/$mid/';
      print(
        'DEBUG: ProfileEdit:_checkProfileExistence: Checking profile existence at URL: $checkUrl',
      );
      final response = await http.get(Uri.parse(checkUrl));
      print(
        'DEBUG: ProfileEdit:_checkProfileExistence: Profile existence check response status: ${response.statusCode}',
      );
      return response.statusCode == 200; // Profile exists if status is 200 OK
    } catch (e) {
      print(
        "DEBUG: ProfileEdit:_checkProfileExistence: Error checking profile existence: $e",
      );
      return false; // Assume not exists on network error
    }
  }

  Future<void> _saveProfileToPrefs(
    String? imageBytesBase64,
    String firstName,
    String lastName,
  ) async {
    print(
      "DEBUG: ProfileEdit:_saveProfileToPrefs: Saving profile data to SharedPreferences...",
    );
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('username', '$firstName $lastName'.trim());
    await prefs.setString('about', aboutController.text);
    if (imageBytesBase64 != null) {
      await prefs.setString('imageBytes', imageBytesBase64);
    } else {
      await prefs.remove('imageBytes'); // Remove if no image or using URL
    }

    // mid and email are already in prefs from login, no need to resave here
    print(
      "DEBUG: ProfileEdit:_saveProfileToPrefs: Profile data saved to SharedPreferences.",
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        // Read bytes directly and store in _pickedImageBytes
        pickedFile.readAsBytes().then((value) {
          setState(() {
            _pickedImageBytes = value; // Directly store Uint8List
            _profileImageUrl = null; // Clear URL if a new image is picked
            print(
              'DEBUG: ProfileEdit:_pickImage: Image selected and converted to Uint8List. Size: ${_pickedImageBytes?.lengthInBytes} bytes',
            );
          });
        });
      } else {
        print('DEBUG: ProfileEdit:_pickImage: No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeChanger = Provider.of<ThemeChanger>(context);
    final currentColors = themeChanger.currentColors;
    return Scaffold(
      body: SwipeDetector(
        onSwipeRight: (offset) => Navigator.pop(context),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                Text(
                  "Последний шаг!",
                  style: GoogleFonts.geologica(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Оформите ваш профиль, чтобы завершить регистрацию!",
                  style: GoogleFonts.geologica(fontSize: 20),
                ),
                const SizedBox(height: 36),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFF4F4F4),
                      // Prioritize picked image, then URL, then placeholder
                      backgroundImage:
                          _pickedImageBytes != null
                              ? MemoryImage(_pickedImageBytes!)
                              : (_profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!)
                                      as ImageProvider<Object>?
                                  : null),
                      child:
                          _pickedImageBytes == null && _profileImageUrl == null
                              ? const Icon(
                                Icons.camera_alt_outlined,
                                size: 50,
                                color: Colors.black,
                              )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    usernameController.text.isEmpty
                        ? "Ваше имя"
                        : usernameController.text,
                    style: GoogleFonts.geologica(fontSize: 28),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    aboutController.text.isEmpty
                        ? "О себе"
                        : aboutController.text,
                    style: GoogleFonts.geologica(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24), // Added some space
                Text(
                  "Ваше имя", // Changed from "О вас" to "Ваше имя" for clarity
                  style: GoogleFonts.geologica(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20000)),
                    color: currentColors.inputCol,
                  ),
                  child: TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      hintText: "Введите ваше имя",
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                    style: GoogleFonts.geologica(fontSize: 16),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "О себе", // Added explicit label for about field
                  style: GoogleFonts.geologica(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20000)),
                    color: currentColors.inputCol,
                  ),
                  child: TextField(
                    controller: aboutController,
                    decoration: const InputDecoration(
                      hintText: "Расскажите о себе",
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                    style: GoogleFonts.geologica(fontSize: 16),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 24), // Added some space
                GestureDetector(
                  onTap: submitProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20000)),
                      color: Color(0xFF334EFF),
                    ),
                    child: Center(
                      child: Text(
                        "Завершить",
                        style: GoogleFonts.geologica(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
