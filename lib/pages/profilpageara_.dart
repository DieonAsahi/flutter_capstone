// import 'package:flutter/material.dart';

// class ProfilePage extends StatelessWidget {
//   const ProfilePage({super.key});

//   final Color primaryColor = const Color(0xFFA79277);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         title: const Text(
//           'Profile',
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings_outlined),
//             onPressed: () {
//               Navigator.pushNamed(context, '/settings');
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// ================= PROFILE HEADER =================
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 CircleAvatar(
//                   radius: 42,
//                   backgroundColor: primaryColor.withOpacity(0.2),
//                   child: const Icon(Icons.person, size: 48, color: Colors.grey),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: const [
//                       Text(
//                         'Araa',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         '@araa_style',
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                       SizedBox(height: 6),
//                       Text(
//                         'Female • Fashion Enthusiast',
//                         style: TextStyle(fontSize: 13),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 16),

//             /// ================= ACTION BUTTON =================
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     style: OutlinedButton.styleFrom(
//                       side: BorderSide(color: primaryColor),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                     ),
//                     onPressed: () {
//                       Navigator.pushNamed(context, '/editprofile');
//                     },
//                     child: Text(
//                       'Edit Profil',
//                       style: TextStyle(
//                         color: primaryColor,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: primaryColor,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                     ),
//                     onPressed: () {
//                       Navigator.pushNamed(context, '/settings');
//                     },
//                     child: const Text(
//                       'Pengaturan',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 24),

//             /// ================= STAT =================
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: const [
//                 _ProfileStat(title: 'Post', value: '12'),
//                 _ProfileStat(title: 'Favorite', value: '24'),
//                 _ProfileStat(title: 'Mix', value: '6'),
//               ],
//             ),

//             const SizedBox(height: 24),

//             /// ================= OUTFIT GRID =================
//             const Text(
//               'Outfit yang Dibagikan',
//               style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
//             ),
//             const SizedBox(height: 12),

//             GridView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: 12,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 3,
//                 crossAxisSpacing: 10,
//                 mainAxisSpacing: 10,
//                 childAspectRatio: 0.75,
//               ),
//               itemBuilder: (context, index) {
//                 return Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: const Icon(
//                     Icons.checkroom,
//                     color: Colors.grey,
//                     size: 36,
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// ================= STAT ITEM =================
// class _ProfileStat extends StatelessWidget {
//   final String title;
//   final String value;

//   const _ProfileStat({required this.title, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           title,
//           style: const TextStyle(color: Colors.grey),
//         ),
//       ],
//     );
//   }
// }
