import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _imagePicker = ImagePicker();
  String? _profileImagePath;
  String? _coverImagePath;

  @override
  void initState() {
    super.initState();
    // Örnek veriler (gerçek uygulamada API'den gelecek)
    _nameController.text = 'Kullanıcı Adı';
    _usernameController.text = 'kullanici';
    _bioController.text = 'Merhaba! Ben bir vlog içerik üreticisiyim.';
  }

  Future<void> _pickImage(bool isProfileImage) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isProfileImage ? 800 : 1920,
        maxHeight: isProfileImage ? 800 : 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (isProfileImage) {
            _profileImagePath = image.path;
          } else {
            _coverImagePath = image.path;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf seçilirken bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // TODO: Profil güncelleme API çağrısı yapılacak
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil başarıyla güncellendi'),
          backgroundColor: Color(0xFF6750A4),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6750A4),
        title: const Text(
          'Profili Düzenle',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Kaydet',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profil ve Kapak Fotoğrafı
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Kapak Fotoğrafı
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    image: _coverImagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_coverImagePath!)),
                            fit: BoxFit.cover,
                          )
                        : const DecorationImage(
                            image: NetworkImage('https://picsum.photos/800/400'),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            onPressed: () => _pickImage(false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Profil Fotoğrafı
                Positioned(
                  bottom: -50,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImagePath != null
                              ? FileImage(File(_profileImagePath!))
                              : const NetworkImage('https://picsum.photos/200')
                                  as ImageProvider,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF6750A4),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => _pickImage(true),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            // Form
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen adınızı girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Kullanıcı Adı',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen kullanıcı adı girin';
                        }
                        if (value.contains(' ')) {
                          return 'Kullanıcı adı boşluk içeremez';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Biyografi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 