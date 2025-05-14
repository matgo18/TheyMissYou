# TheyMissYou

**TheyMissYou** is an iOS application built with SwiftUI. It enables users to share location-based posts collaboratively within groups. The app focuses on simplicity, geolocation, and social interaction.

## Main Features

* **Authentication**

  * Login and signup interface (`AuthView.swift`)

* **Groups**

  * Create and manage user groups (`GroupsView`, `GroupManager`)

* **Interactive Map**

  * Select locations through a map interface (`MapPickerView`, `LocationsView`)

* **Photo Posts**

  * Create posts that include images and specific locations (`PostPhotoView`, `PostView`, `PostManager`, `ImageManager`)

* **Notifications**

  * Local notifications to keep users engaged (`NotificationManager`)

* **User Profile**

  * Manage user information and preferences (`ProfileView`, `UserManager`)

* **App Settings**

  * Customize app behavior (`SettingsView`)

## Installation

### Prerequisites

* macOS with [Xcode](https://developer.apple.com/xcode/) installed
* Swift 5.0 or later
* A Firebase account if using Firebase integration (`GoogleService-Info.plist` required)

### Steps

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/TheyMissYou.git
   cd TheyMissYou
   ```

2. Open the project in Xcode:

   ```bash
   open TheyMissYou.xcodeproj
   ```

3. If needed, add your own `GoogleService-Info.plist` file in the `TheyMissYou/` directory

4. Build and run the app on a simulator or physical device


## License

This project is open-source. See the `LICENSE` file for more details (if available).
