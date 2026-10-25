# Buti’s Block: Flutter Student Application

## What it is for

An application for students to browse accommodation, apply for a room, track their application and report maintenance. It shares data with the ASP.NET landlord website through Supabase.

## What it solves

It allows students to find accommodation, submit documents and follow application or maintenance progress without relying on paper forms and repeated enquiries.

## Requirements

- Flutter SDK with a compatible Dart SDK.
- VS Code with Flutter/Dart extensions, or Android Studio.
- A web browser or configured Android device/emulator.
- Internet connection.
- Configured Supabase database, authentication, storage and access policies.
- The same Supabase project as the landlord website.

## Required technologies and techniques

- Flutter and Dart.
- Models, Views and ViewModels (MVVM), with services for backend operations.
- Supabase Authentication, PostgreSQL and file storage.
- Form validation, document uploads and authenticated access.
- Shared room availability, application tracking and maintenance workflows.

## Step-by-step use

### Start the application

1. Extract the project to a short path, such as `C:\Projects\Student`.
2. Open the folder containing `pubspec.yaml` in your editor.
3. Check the Supabase URL and public key in `lib/services/supabase_config.dart`.
4. Open a terminal in that folder and run:

```powershell
flutter pub get
flutter run -d web-server --web-port 3000
```

5. Keep the terminal open and visit `http://localhost:3000`.
6. For email verification and password recovery, ensure that address is allowed in Supabase Authentication Redirect URLs.

### Apply and track progress

1. Browse accommodation and open a room to view its rent, details and availability.
2. Select **Apply**, then sign in or create a student account.
3. Enter a student number containing exactly nine digits. Verify your email if requested.
4. Check your personal details in **Profile** and correct them before applying.
5. Complete the application form and confirm your selected room.
6. Attach **ID**, **Proof of Registration** and **Proof of Funding**. Use PDF, DOC or DOCX files, up to 10 MB each, with a maximum of five files overall.
7. Accept the declaration and select **Submit Application**.
8. Open **My applications** to track the decision. Only one application per student is allowed.
9. After approval, wait for the landlord to allocate a bed. Refresh to view the bed details.
10. Once a bed is allocated, open **Maintenance**, select the bed, enter the issue and priority, and submit. An optional JPG, PNG or WebP photo can be up to 5 MB.
11. Open **My requests** to track maintenance updates.
12. Use **Forgot password?** on Login if needed, and **Sign out** when finished.

Students select a room; the landlord assigns the bed. Full rooms cannot accept new applications, and approval alone does not enable maintenance.
