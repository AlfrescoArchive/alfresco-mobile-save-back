Alfresco SaveBack Sample Code
=============================

This is the GitHub repository for the Alfresco SaveBack API and sample project demonstrating its use.

Quick Start
-----------

1. Clone this source repository. (`git clone https://github.com/Alfresco/alfresco-mobile-save-back.git`)
2. Launch Xcode 4.5 and open the project.
3. Build and install the sample app on an iOS Simulator or device (iOS 5 and newer supported).
4. You also need a recent Alfresco Mobile 1.4 build, so clone and install the Alfresco Mobile iOS app v1.4 (`git clone https://bitbucket.org/ziadev/alfresco-mobile.git`)

Testing
-------

1. Launch the Alfresco Mobile app and configure an account.
2. Browse to any hosted content.
3. Choose "Open In..." from the action menu and select the "Alfresco SB" app.
4. The Alfresco SaveBack Sample app will be launched and show the name of the content file.
5. If SaveBack API metadata is detected, the Alfresco logo will be in colour.
<p><img src="https://raw.github.com/Alfresco/alfresco-mobile-save-back/master/Resources/Images/has-alfresco-metadata.png"></p>
6. Tap the Action Button and choose "Save Back". Alfresco will be the only app offered.
7. Tap Alfresco to save the document back to the repository.

Notes
-----

* The sample app updates the file just before save back with the current time. It does not alter the content.
* The content of the file can be changed using iTunes File Sharing or an app such as [PhoneView](http://www.ecamm.com/mac/phoneview/).
* Sending a file to the Sample App without the Alfresco SaveBack metadata will result in a monochrome logo.
<p><img src="https://raw.github.com/Alfresco/alfresco-mobile-save-back/master/Resources/Images/no-alfresco-metadata.png"></p>

