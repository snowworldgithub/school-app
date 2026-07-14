import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String apiBaseUrl = 'http://127.0.0.1:8000';

String _textValue(dynamic value) => value?.toString() ?? '';

String _apiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

Map<String, String> _studentFromServer(Map<String, dynamic> data) {
  final name = _textValue(data['full_name']).trim();
  final className = _textValue(
    data['student_class_display'] ?? data['student_class_name'],
  );

  return {
    'id': _textValue(data['id']),
    'name': name.isEmpty ? 'Student ${_textValue(data['roll_number'])}' : name,
    'fatherName': _textValue(data['father_name']),
    'motherName': _textValue(data['mother_name']),
    'class': className,
    'roll': _textValue(data['roll_number']),
    'gr': _textValue(data['gr_number']),
    'gender': _textValue(data['gender']).isEmpty
        ? 'Male'
        : _textValue(data['gender']),
    'fatherPhone': _textValue(data['father_phone']),
    'motherPhone': _textValue(data['mother_phone']),
    'whatsapp': _textValue(data['whatsapp']),
    'fatherNic': _textValue(data['father_nic']),
    'motherNic': _textValue(data['mother_nic']),
    'address': _textValue(data['address']),
    'prevSchool': _textValue(data['prev_school']),
    'feeStatus': 'Unpaid',
    'attendanceStatus': 'Absent',
    'attendanceTime': '',
  };
}

void main() => runApp(const SchoolApp());

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "Ahmed's Educational System",
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color.fromARGB(255, 232, 10, 10),
    ),
    home: const DashboardScreen(),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;
  final List<Map<String, String>> _students = [];
  bool _loadingStudents = true;

  @override
  void initState() {
    super.initState();
    _loadStudentsFromServer();
  }

  Future<void> _loadStudentsFromServer() async {
    try {
      final studentsRes = await http.get(Uri.parse('$apiBaseUrl/api/students/'));
      if (studentsRes.statusCode != 200) {
        debugPrint('Students load fail: ${studentsRes.body}');
        return;
      }

      final decodedStudents = jsonDecode(studentsRes.body) as List<dynamic>;
      final loadedStudents = decodedStudents
          .whereType<Map<String, dynamic>>()
          .map(_studentFromServer)
          .toList();

      final today = _apiDate(DateTime.now());
      final attendanceRes = await http.get(
        Uri.parse('$apiBaseUrl/api/attendance/?date=$today'),
      );
      if (attendanceRes.statusCode == 200) {
        final decodedAttendance = jsonDecode(attendanceRes.body) as List<dynamic>;
        for (final item in decodedAttendance.whereType<Map<String, dynamic>>()) {
          final studentId = _textValue(item['student']);
          final index = loadedStudents.indexWhere((s) => s['id'] == studentId);
          if (index == -1) continue;

          final status = _textValue(item['status']);
          loadedStudents[index]['attendanceStatus'] =
              status == 'present' ? 'Present' : 'Absent';
          loadedStudents[index]['attendanceTime'] =
              _textValue(item['marked_at']);
        }
      }

      if (!mounted) return;
      setState(() {
        _students
          ..clear()
          ..addAll(loadedStudents);
        _loadingStudents = false;
      });
    } catch (e) {
      debugPrint('Students load error: $e');
      if (!mounted) return;
      setState(() => _loadingStudents = false);
    }
  }

  Future<void> _deleteStudentFromServer(int index) async {
    final student = _students[index];
    final id = student['id'];
    if (id != null && id.isNotEmpty) {
      final response = await http.delete(Uri.parse('$apiBaseUrl/api/students/$id/'));
      if (response.statusCode != 204 && response.statusCode != 200) {
        debugPrint('Delete fail: ${response.body}');
        return;
      }
    }

    if (!mounted) return;
    setState(() => _students.removeAt(index));
  }

  int _getFeeAmount(String cls) {
    final c = cls.toLowerCase();
    if (c.contains('pg') || c.contains('kg')) return 2000;
    if (c.contains('8') || c.contains('9') || c.contains('10')) return 5000;
    return 2500;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(totalStudents: _students.length),
      StudentsTab(
        students: _students,
        onAdd: (s) {
          setState(() => _students.add(s));
          _loadStudentsFromServer();
        },
        onDelete: _deleteStudentFromServer,
        onRefresh: _loadStudentsFromServer,
      ),
      FeesTab(
        students: _students,
        getFeeAmount: _getFeeAmount,
        onStatusChange: (i, status) =>
            setState(() => _students[i]['feeStatus'] = status),
      ),
      AttendanceTab(
        students: _students,
        onMarkAttendance: (i) => setState(() {
          final now = DateTime.now();
          _students[i]['attendanceStatus'] = 'Present';
          _students[i]['attendanceTime'] = _formatDateTime(now);
        }),
      ),
      const NoticesTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8510A),
        title: const Text(
          "Ahmed's Educational System",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _loadingStudents
          ? const Center(child: CircularProgressIndicator())
          : pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: const Color(0xFFE8510A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Fees'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Notices'),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class HomeTab extends StatelessWidget {
  final int totalStudents;
  const HomeTab({super.key, required this.totalStudents});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8510A), Color(0xFFFF7043)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assalam-o-Alaikum!',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Overview',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _Card(
              title: 'Total Students',
              value: '$totalStudents',
              icon: Icons.people,
              color: const Color(0xFFE8510A),
            ),
            const _Card(
              title: 'Pre-Primary Fee',
              value: 'Rs 2,000',
              icon: Icons.child_care,
              color: Colors.blue,
            ),
            const _Card(
              title: 'Primary Fee',
              value: 'Rs 2,500',
              icon: Icons.class_,
              color: Colors.green,
            ),
            const _Card(
              title: 'Senior Fee',
              value: 'Rs 5,000',
              icon: Icons.school,
              color: Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Fee Structure',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _feeRow('Pre-Primary', 'PG to KG II', 'Rs 2,000', Colors.blue),
        const SizedBox(height: 8),
        _feeRow(
          'Primary & Secondary',
          'Class 1 to 7',
          'Rs 2,500',
          const Color(0xFFE8510A),
        ),
        const SizedBox(height: 8),
        _feeRow('Senior', 'Class 8 to 10', 'Rs 5,000', Colors.purple),
      ],
    ),
  );

  Widget _feeRow(String level, String classes, String amount, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    classes,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
}

class _Card extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _Card({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 26),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    ),
  );
}

class StudentsTab extends StatefulWidget {
  final List<Map<String, String>> students;
  final Function(Map<String, String>) onAdd;
  final Function(int) onDelete;
  final Function()? onRefresh;
  const StudentsTab({
    super.key,
    required this.students,
    required this.onAdd,
    required this.onDelete,
    this.onRefresh,
  });
  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final _nameC = TextEditingController();
  final _fatherNameC = TextEditingController();
  final _motherNameC = TextEditingController();
  final _classC = TextEditingController();
  final _rollC = TextEditingController();
  final _grC = TextEditingController();
  final _fatherPhoneC = TextEditingController();
  final _motherPhoneC = TextEditingController();
  final _whatsappC = TextEditingController();
  final _fatherNicC = TextEditingController();
  final _motherNicC = TextEditingController();
  final _addressC = TextEditingController();
  final _prevSchoolC = TextEditingController();
  String _gender = 'Male';
  String _lastSaveError = '';

  String _uniqueSuffix() => DateTime.now().microsecondsSinceEpoch.toString();

 Future<Map<String, String>?> addStudentToServer(Map<String, String> data) async {
  _lastSaveError = '';
  try {
    final roll = (data['roll'] ?? '').trim().isEmpty
        ? _uniqueSuffix()
        : (data['roll'] ?? '').trim();
    final registerRes = await http.post(
      Uri.parse('$apiBaseUrl/api/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': 'student_$roll',
        'first_name': data['name'] ?? '',
        'last_name': '',
        'email': 'student_$roll@school.local',
        'password': 'student123',
        'role': 'student',
        'phone': data['fatherPhone'] ?? '',
      }),
    );

    if (registerRes.statusCode != 201 && registerRes.statusCode != 200) {
      debugPrint('Register fail: ${registerRes.body}');
      _lastSaveError = registerRes.body;
      return null;
    }
    final userId = jsonDecode(registerRes.body)['id'];

    final studentRes = await http.post(
      Uri.parse('$apiBaseUrl/api/students/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user': userId,
        'roll_number': roll,
        'gr_number': data['gr'] ?? '',
        'gender': _gender,
        'address': data['address'] ?? '',
        'prev_school': data['prevSchool'] ?? '',
        'father_name': data['fatherName'] ?? '',
        'father_phone': data['fatherPhone'] ?? '',
        'father_nic': data['fatherNic'] ?? '',
        'mother_name': data['motherName'] ?? '',
        'mother_phone': data['motherPhone'] ?? '',
        'mother_nic': data['motherNic'] ?? '',
        'whatsapp': data['whatsapp'] ?? '',
        'class_name': data['class'] ?? '',
      }),
    );

    if (studentRes.statusCode == 201) {
      final resData = jsonDecode(studentRes.body);
      return _studentFromServer(resData);
    } else {
      debugPrint('Fail: ${studentRes.body}');
      _lastSaveError = studentRes.body;
      return null;
    }
  } catch (e) {
    debugPrint('Error: $e');
    _lastSaveError = e.toString();
    return null;
  }
}

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool readOnly = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      keyboardType: type,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(icon),
      ),
    ),
  );

  String _qrData(Map<String, String> student) {
    final identifier = student['gr']?.isNotEmpty == true
        ? student['gr']
        : student['roll'] ?? student['id'];
    return 'AES-STUDENT:$identifier';
  }

  Future<void> _prepareNewStudentForm() async {
    _nameC.clear();
    _fatherNameC.clear();
    _motherNameC.clear();
    _classC.clear();
    _rollC.clear();
    _fatherPhoneC.clear();
    _motherPhoneC.clear();
    _whatsappC.clear();
    _fatherNicC.clear();
    _motherNicC.clear();
    _addressC.clear();
    _prevSchoolC.clear();
    _gender = 'Male';
    _rollC.text = 'Loading...';
    _grC.text = 'Loading...';

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/students/next-gr/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _grC.text = _textValue(data['gr_number']);
        _rollC.text = _textValue(data['roll_number']);
        return;
      }
      debugPrint('Next GR fail: ${response.body}');
    } catch (e) {
      debugPrint('Next GR error: $e');
    }

    if (_rollC.text == 'Loading...') {
      _rollC.clear();
    }
    _grC.clear();
  }

  Future<void> _printStudentCard(Map<String, String> student) async {
    final doc = pw.Document();
    final qrData = _qrData(student);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(16),
        build: (_) => pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1.2),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                "Ahmed's Educational System",
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Student Attendance Card',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Divider(height: 16),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: qrData,
                width: 96,
                height: 96,
              ),
              pw.SizedBox(height: 12),
              _cardPdfRow('Name', student['name'] ?? '-'),
              _cardPdfRow('Father', student['fatherName'] ?? '-'),
              _cardPdfRow('Class', student['class'] ?? '-'),
              _cardPdfRow('Roll', student['roll'] ?? '-'),
              _cardPdfRow('GR', student['gr'] ?? '-'),
              pw.Spacer(),
              pw.Text(
                'Scan this QR for attendance',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  pw.Widget _cardPdfRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 42,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
        ),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    ),
  );

  void _showQrCard(Map<String, String> student) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black87),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Ahmed's Educational System",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Text(
                      'Student Attendance Card',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    QrImageView(data: _qrData(student), size: 170),
                    const SizedBox(height: 12),
                    _cardInfo('Name', student['name'] ?? '-'),
                    _cardInfo('Father', student['fatherName'] ?? '-'),
                    _cardInfo('Class', student['class'] ?? '-'),
                    _cardInfo('Roll', student['roll'] ?? '-'),
                    _cardInfo('GR', student['gr'] ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print, color: Colors.white),
                      label: const Text(
                        'Print Card',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8510A),
                      ),
                      onPressed: () => _printStudentCard(student),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardInfo(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Future<void> _showForm() async {
    await _prepareNewStudentForm();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'New Student Admission',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tamam fields bharein',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Divider(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Student Info',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE8510A),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _field(_nameC, 'Student Name *', Icons.person),
                _field(_classC, 'Class (e.g. KG I / Class 5) *', Icons.class_),
                _field(
                  _rollC,
                  'Roll Number *',
                  Icons.numbers,
                  type: TextInputType.number,
                ),
                _field(
                  _grC,
                  'GR Number',
                  Icons.confirmation_number,
                  readOnly: true,
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.grey),
                      const SizedBox(width: 12),
                      const Text('Gender:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 20),
                      ChoiceChip(
                        label: const Text('Male'),
                        selected: _gender == 'Male',
                        selectedColor: const Color(0xFFE8510A),
                        labelStyle: TextStyle(
                          color: _gender == 'Male'
                              ? Colors.white
                              : Colors.black,
                        ),
                        onSelected: (_) =>
                            setModalState(() => _gender = 'Male'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Female'),
                        selected: _gender == 'Female',
                        selectedColor: const Color(0xFFE8510A),
                        labelStyle: TextStyle(
                          color: _gender == 'Female'
                              ? Colors.white
                              : Colors.black,
                        ),
                        onSelected: (_) =>
                            setModalState(() => _gender = 'Female'),
                      ),
                    ],
                  ),
                ),
                _field(
                  _prevSchoolC,
                  'Previous School (if any)',
                  Icons.school_outlined,
                ),
                _field(_addressC, 'Address', Icons.location_on),
                const Divider(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Father Info',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE8510A),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _field(_fatherNameC, 'Father Name *', Icons.person_outline),
                _field(
                  _fatherPhoneC,
                  'Father Phone',
                  Icons.phone,
                  type: TextInputType.phone,
                ),
                _field(
                  _fatherNicC,
                  'Father NIC Number',
                  Icons.credit_card,
                  type: TextInputType.number,
                ),
                const Divider(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mother Info',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE8510A),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _field(_motherNameC, 'Mother Name', Icons.person_outline),
                _field(
                  _motherPhoneC,
                  'Mother Phone',
                  Icons.phone,
                  type: TextInputType.phone,
                ),
                _field(
                  _motherNicC,
                  'Mother NIC Number',
                  Icons.credit_card,
                  type: TextInputType.number,
                ),
                const Divider(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Contact',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE8510A),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _field(
                  _whatsappC,
                  'WhatsApp Number',
                  Icons.chat,
                  type: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8510A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: ()async {
                      if (_nameC.text.isEmpty || _classC.text.isEmpty) return;
                      final studentData = {
                        'id': DateTime.now().microsecondsSinceEpoch.toString(),
                        'name': _nameC.text,
                        'fatherName': _fatherNameC.text,
                        'motherName': _motherNameC.text,
                        'class': _classC.text,
                        'roll': _rollC.text,
                        'gr': _grC.text,
                        'gender': _gender,
                        'fatherPhone': _fatherPhoneC.text,
                        'motherPhone': _motherPhoneC.text,
                        'whatsapp': _whatsappC.text,
                        'fatherNic': _fatherNicC.text,
                        'motherNic': _motherNicC.text,
                        'address': _addressC.text,
                        'prevSchool': _prevSchoolC.text,
                        'feeStatus': 'Unpaid',
                        'attendanceStatus': 'Absent',
                        'attendanceTime': '',
                      };
                      final savedStudent = await addStudentToServer(studentData);
                      if (!mounted) return;
                      if (savedStudent == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _lastSaveError.isEmpty
                                  ? 'Student Django main save nahi hua'
                                  : 'Save fail: $_lastSaveError',
                            ),
                          ),
                        );
                        return;
                      }
                      widget.onAdd(savedStudent);
                      if (widget.onRefresh != null) {
                        widget.onRefresh!();
                      }
                      _nameC.clear();
                      _fatherNameC.clear();
                      _motherNameC.clear();
                      _classC.clear();
                      _rollC.clear();
                      _grC.clear();
                      _fatherPhoneC.clear();
                      _motherPhoneC.clear();
                      _whatsappC.clear();
                      _fatherNicC.clear();
                      _motherNicC.clear();
                      _addressC.clear();
                      _prevSchoolC.clear();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Add Student',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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

  @override
  Widget build(BuildContext context) => Scaffold(
    body: RefreshIndicator(
      onRefresh: () async {
        if (widget.onRefresh != null) {
          await Future.delayed(const Duration(milliseconds: 500));
          widget.onRefresh!();
        }
      },
      child: widget.students.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 70, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Koi student nahi hai',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  Text(
                    'Neeche + button dabao',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.students.length,
              itemBuilder: (_, i) {
              final s = widget.students[i];
              final isFemale = s['gender'] == 'Female';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isFemale
                          ? Colors.pink
                          : const Color(0xFFE8510A),
                      radius: 24,
                      child: Text(
                        s['name']![0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                s['name']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isFemale
                                      ? Colors.pink.withValues(alpha: 0.1)
                                      : Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  s['gender'] ?? 'Male',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isFemale ? Colors.pink : Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${s['class']} • Roll: ${s['roll']} • GR: ${s['gr']}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Father: ${s['fatherName']}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Ph: ${s['fatherPhone']} • WA: ${s['whatsapp']}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          tooltip: 'QR Card',
                          icon: const Icon(
                            Icons.qr_code,
                            color: Color(0xFFE8510A),
                          ),
                          onPressed: () => _showQrCard(s),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Student?'),
                              content: Text(
                                '${s['name']} ko delete karna chahti hain?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    widget.onDelete(i);
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: const Color(0xFFE8510A),
      onPressed: _showForm,
      icon: const Icon(Icons.person_add, color: Colors.white),
      label: const Text('Add Student', style: TextStyle(color: Colors.white)),
    ),
  );
}

class FeesTab extends StatelessWidget {
  final List<Map<String, String>> students;
  final int Function(String) getFeeAmount;
  final Function(int, String) onStatusChange;
  const FeesTab({
    super.key,
    required this.students,
    required this.getFeeAmount,
    required this.onStatusChange,
  });

  String _getLevel(String cls) {
    final c = cls.toLowerCase();
    if (c.contains('pg') || c.contains('kg')) return 'Pre-Primary';
    if (c.contains('8') || c.contains('9') || c.contains('10')) return 'Senior';
    return 'Primary';
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _receiptNo(DateTime dateTime) {
    final y = dateTime.year.toString();
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final h = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    final s = dateTime.second.toString().padLeft(2, '0');
    return 'AES-$y$m$d-$h$min$s';
  }

  Future<void> _printReceipt(Map<String, String> student, int feeAmount) async {
    final doc = pw.Document();
    final paidAmount = student['paidAmount'] ?? feeAmount.toString();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.2)),
          padding: const pw.EdgeInsets.all(18),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "Ahmed's Educational System",
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Fee Receipt',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Divider(height: 28),
              _pdfRow('Receipt No', student['receiptNo'] ?? '-'),
              _pdfRow('Date & Time', student['paidAt'] ?? '-'),
              _pdfRow('Student Name', student['name'] ?? '-'),
              _pdfRow('Father Name', student['fatherName'] ?? '-'),
              _pdfRow('Class', student['class'] ?? '-'),
              _pdfRow('Roll No', student['roll'] ?? '-'),
              _pdfRow('GR No', student['gr'] ?? '-'),
              _pdfRow('Fee Month', student['feeMonth'] ?? '-'),
              _pdfRow('Payment Method', student['paymentMethod'] ?? '-'),
              pw.Divider(height: 28),
              _pdfRow('Monthly Fee', 'Rs $feeAmount'),
              _pdfRow('Amount Paid', 'Rs $paidAmount'),
              _pdfRow('Status', student['feeStatus'] ?? 'Paid'),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Received By: Admin'),
                  pw.Text('Signature: __________'),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 115,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Text(': '),
        pw.Expanded(child: pw.Text(value)),
      ],
    ),
  );

  void _showFeeForm(
    BuildContext context,
    int index,
    Map<String, String> student,
    int feeAmount,
  ) {
    final amountC = TextEditingController(text: feeAmount.toString());
    final monthC = TextEditingController(
      text: '${DateTime.now().month}/${DateTime.now().year}',
    );
    String method = 'Cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Submit Fee',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                _infoLine('Student', student['name'] ?? '-'),
                _infoLine('Class', student['class'] ?? '-'),
                _infoLine('Monthly Fee', 'Rs $feeAmount'),
                const SizedBox(height: 12),
                TextField(
                  controller: amountC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Paid Amount',
                    prefixIcon: const Icon(Icons.payments),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: monthC,
                  decoration: InputDecoration(
                    labelText: 'Fee Month',
                    prefixIcon: const Icon(Icons.calendar_month),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: const Icon(Icons.receipt_long),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(
                      value: 'Bank Transfer',
                      child: Text('Bank Transfer'),
                    ),
                    DropdownMenuItem(
                      value: 'EasyPaisa/JazzCash',
                      child: Text('EasyPaisa/JazzCash'),
                    ),
                  ],
                  onChanged: (value) =>
                      setModalState(() => method = value ?? 'Cash'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.receipt_long, color: Colors.white),
                    label: const Text(
                      'Generate Receipt',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8510A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      final now = DateTime.now();
                      student['feeStatus'] = 'Paid';
                      student['receiptNo'] = _receiptNo(now);
                      student['paidAt'] = _formatDateTime(now);
                      student['paidAmount'] = amountC.text.trim().isEmpty
                          ? feeAmount.toString()
                          : amountC.text.trim();
                      student['feeMonth'] = monthC.text.trim();
                      student['paymentMethod'] = method;
                      onStatusChange(index, 'Paid');
                      Navigator.pop(context);
                      _showReceipt(context, student, feeAmount);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  void _showReceipt(
    BuildContext context,
    Map<String, String> student,
    int feeAmount,
  ) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReceiptView(student: student, feeAmount: feeAmount),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print, color: Colors.white),
                      label: const Text(
                        'Print',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8510A),
                      ),
                      onPressed: () => _printReceipt(student, feeAmount),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collected = students.fold<int>(0, (total, student) {
      if (student['feeStatus'] != 'Paid') return total;
      final feeAmount = getFeeAmount(student['class'] ?? '');
      return total + (int.tryParse(student['paidAmount'] ?? '') ?? feeAmount);
    });

    return Scaffold(
      body: students.isEmpty
          ? const Center(
              child: Text(
                'No students found',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (_, i) {
                final s = students[i];
                final feeAmount = getFeeAmount(s['class'] ?? '');
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: s['gender'] == 'Female'
                            ? Colors.pink
                            : const Color(0xFFE8510A),
                        radius: 22,
                        child: Text(
                          (s['name']?.isNotEmpty ?? false)
                              ? s['name']![0]
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['name'] ?? 'Unknown student',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${_getLevel(s['class'] ?? '')} - ${s['class'] ?? ''}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Fee: Rs $feeAmount',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            if (s['receiptNo'] != null)
                              Text(
                                'Receipt: ${s['receiptNo']}',
                                style: const TextStyle(
                                  color: Color(0xFFE8510A),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Chip(
                            label: Text(s['feeStatus'] ?? 'Unpaid'),
                            backgroundColor: s['feeStatus'] == 'Paid'
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.orange.withValues(alpha: 0.12),
                          ),
                          const SizedBox(height: 6),
                          FilledButton.icon(
                            onPressed: () =>
                                _showFeeForm(context, i, s, feeAmount),
                            icon: const Icon(Icons.payments, size: 16),
                            label: const Text('Submit'),
                          ),
                          if (s['receiptNo'] != null)
                            TextButton.icon(
                              onPressed: () =>
                                  _showReceipt(context, s, feeAmount),
                              icon: const Icon(Icons.receipt_long, size: 16),
                              label: const Text('Slip'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          'Collected: Rs $collected',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE8510A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _ReceiptView extends StatelessWidget {
  final Map<String, String> student;
  final int feeAmount;
  const _ReceiptView({required this.student, required this.feeAmount});

  Widget _row(String label, String value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: strong ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: strong ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final paidAmount = student['paidAmount'] ?? feeAmount.toString();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black87, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Column(
              children: [
                Text(
                  "Ahmed's Educational System",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Fee Receipt',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 24, color: Colors.black87),
          _row('Receipt No', student['receiptNo'] ?? '-', strong: true),
          _row('Date & Time', student['paidAt'] ?? '-'),
          _row('Student Name', student['name'] ?? '-'),
          _row('Father Name', student['fatherName'] ?? '-'),
          _row('Class', student['class'] ?? '-'),
          _row('Roll No', student['roll'] ?? '-'),
          _row('GR No', student['gr'] ?? '-'),
          _row('Fee Month', student['feeMonth'] ?? '-'),
          _row('Payment Method', student['paymentMethod'] ?? '-'),
          const Divider(height: 24, color: Colors.black87),
          _row('Monthly Fee', 'Rs $feeAmount'),
          _row('Amount Paid', 'Rs $paidAmount', strong: true),
          _row('Status', student['feeStatus'] ?? 'Paid', strong: true),
          const SizedBox(height: 28),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Received By: Admin'),
              Text('Signature: __________'),
            ],
          ),
        ],
      ),
    );
  }
}

class AttendanceTab extends StatefulWidget {
  final List<Map<String, String>> students;
  final Function(int) onMarkAttendance;
  const AttendanceTab({
    super.key,
    required this.students,
    required this.onMarkAttendance,
  });

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  String _qrData(Map<String, String> student) {
    final identifier = student['gr']?.isNotEmpty == true
        ? student['gr']
        : student['roll'] ?? student['id'];
    return 'AES-STUDENT:$identifier';
  }

  Future<bool> _markAttendanceOnServer(String qrData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/attendance/qr/mark/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'qr_data': qrData,
          'status': 'present',
          'marked_by': 'Flutter QR',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      debugPrint('Attendance fail: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Attendance error: $e');
      return false;
    }
  }

  void _openScanner() {
    var scanned = false;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 430,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                color: const Color(0xFFE8510A),
                child: const Text(
                  'Scan Student QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: MobileScanner(
                  onDetect: (capture) async {
                    if (scanned || capture.barcodes.isEmpty) return;
                    final code = capture.barcodes.first.rawValue;
                    if (code == null) return;

                    final index = widget.students.indexWhere(
                      (student) => _qrData(student) == code,
                    );
                    scanned = true;
                    Navigator.pop(dialogContext);

                    if (index == -1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Student QR record nahi mila'),
                        ),
                      );
                      return;
                    }

                    final saved = await _markAttendanceOnServer(code);
                    if (!mounted) return;

                    if (!saved) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Django server par attendance save nahi hui'),
                        ),
                      );
                      return;
                    }

                    widget.onMarkAttendance(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${widget.students[index]['name']} ki attendance lag gayi',
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                  label: const Text('Close Scanner'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: widget.students.isEmpty
        ? const Center(
            child: Text(
              'No students found',
              style: TextStyle(color: Colors.grey),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.students.length,
            itemBuilder: (_, i) {
              final s = widget.students[i];
              final isPresent = s['attendanceStatus'] == 'Present';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isPresent ? Icons.check_circle : Icons.qr_code_scanner,
                      color: isPresent ? Colors.green : const Color(0xFFE8510A),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['name'] ?? 'Unknown student',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${s['class'] ?? ''} - Roll: ${s['roll'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          if ((s['attendanceTime'] ?? '').isNotEmpty)
                            Text(
                              'Time: ${s['attendanceTime']}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(isPresent ? 'Present' : 'Absent'),
                      backgroundColor: isPresent
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.red.withValues(alpha: 0.10),
                    ),
                  ],
                ),
              );
            },
          ),
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: const Color(0xFFE8510A),
      onPressed: widget.students.isEmpty ? null : _openScanner,
      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
      label: const Text('Scan QR', style: TextStyle(color: Colors.white)),
    ),
  );
}

class NoticesTab extends StatelessWidget {
  const NoticesTab({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.campaign_outlined, size: 70, color: Colors.grey),
        SizedBox(height: 12),
        Text(
          'No notices yet',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    ),
  );
}
