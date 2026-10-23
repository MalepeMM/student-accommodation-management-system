import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:helloworld/models/accommodation.dart';
import 'package:helloworld/services/accommodation_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:helloworld/models/prototype_session.dart';
import 'package:helloworld/widgets/prototype_widgets.dart';
import 'package:helloworld/views/screens/07_application_form/application_form_page.dart';
import 'package:helloworld/views/screens/02_create_account/create_account_page.dart';
import 'package:helloworld/views/screens/11_my_profile/profile_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PrototypeSession.clear();
  });
  testWidgets('Application autofills registered details and blocks incomplete submission', (tester) async {
    final repository = _FormRepository();
    await tester.pumpWidget(MaterialApp(home: ApplicationFormPage(repository: repository)));
    await tester.pumpAndSettle();
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(fields.map((f) => f.controller!.text).toList(),
      ['Registered Student', 'student@example.test', '012345678', '0712345678', '']);
    for (var i = 0; i < 4; i++) {
      final textField = tester.widget<TextField>(find.descendant(
        of: find.byType(TextFormField).at(i),
        matching: find.byType(TextField),
      ));
      expect(textField.readOnly, isTrue);
    }
    for (final field in tester.widgetList<DropdownButtonFormField<String>>(find.byType(DropdownButtonFormField<String>))) {
      expect(field.initialValue, isNull);
    }
    for (final type in ['ID', 'Proof of registration', 'Proof of funding']) {
      expect(find.text('Add $type document'), findsOneWidget);
    }
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isFalse);
    await tester.ensureVisible(find.text('Submit Application'));
    await tester.tap(find.text('Submit Application'));
    await tester.pump();
    expect(repository.submissions, 0);
  });
  testWidgets('Existing applicants see tracking instead of another application form', (tester) async {
    final repository = _FormRepository()..alreadyApplied = true;
    await tester.pumpWidget(MaterialApp(home: ApplicationFormPage(repository: repository)));
    await tester.pumpAndSettle();
    expect(find.text('View my application'), findsOneWidget);
    expect(find.text('Submit Application'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(repository.submissions, 0);
  });
  testWidgets('Registration student number filters letters, keeps leading zeroes and limits length', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateAccountPage()));
    final number = find.ancestor(
      of: find.byWidgetPredicate((w) => w is TextField && w.keyboardType == TextInputType.number),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(number, '0a1234567899');
    expect(tester.widget<TextFormField>(number).controller!.text, '012345678');
    await tester.enterText(number, '12345678');
    final field = tester.widget<TextFormField>(number);
    expect(field.validator!(field.controller!.text), 'Student number must contain exactly 9 digits');
  });
  testWidgets('Primary buttons are blue even on former grey variants', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PrototypeButton('Continue', grey: true, onPressed: () {}))));
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.style!.backgroundColor!.resolve({}), prototypeBlue);
  });
  testWidgets('Wide navigation highlights the selected destination', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: PrototypePage(nav: 1, children: [SizedBox()])));
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(tiles.take(4).map((tile) => tile.selected).toList(), [false, true, false, false]);
    expect(find.text('Log out'), findsOneWidget);
    expect(
      tester.getCenter(find.byType(ListTile).last).dy,
      greaterThan(tester.getCenter(find.byType(ListTile).at(3)).dy),
    );
  });
  testWidgets('Profile handles large text and keyboard at phone width', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    PrototypeSession.name = 'A student with a longer full name';
    await tester.pumpWidget(MaterialApp(builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5), viewInsets: const EdgeInsets.only(bottom: 240)),
      child: child!), home: const ProfilePage(accommodationPanel: SizedBox())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _FormRepository extends AccommodationRepository {
  int submissions = 0;
  bool alreadyApplied = false;
  @override
  Future<String?> getExistingApplicationId() async => alreadyApplied ? 'existing-application' : null;
  @override
  Future<Map<String, dynamic>> getStudentProfile() async => {
    'firstname': 'Registered', 'lastname': 'Student', 'email': 'student@example.test',
    'studentnumber': '012345678', 'phonenumber': '0712345678'};
  @override
  Future<List<Accommodation>> getAccommodations() async => [];
  @override
  Future<String> submitApplication({required String id, required Accommodation room,
    required Map<String, dynamic> details, required List<PlatformFile> files}) async {
    submissions++; return id;
  }
}
