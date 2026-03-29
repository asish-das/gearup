
class SystemSettings {
  final String primaryAdminEmail;
  final String twoFactorAuth;
  final int sessionTimeout;
  
  final Map<String, PermissionSet> rolePermissions;
  
  final bool emailAlerts;
  final bool pushNotifications;
  final bool weeklyReport;
  
  final bool darkMode;
  final String accentColor; // Hex string
  final String adminName;
  final String adminDesignation;

  SystemSettings({
    required this.primaryAdminEmail,
    required this.twoFactorAuth,
    required this.sessionTimeout,
    required this.rolePermissions,
    required this.emailAlerts,
    required this.pushNotifications,
    required this.weeklyReport,
    required this.darkMode,
    required this.accentColor,
    required this.adminName,
    required this.adminDesignation,
  });

  factory SystemSettings.initial() {
    return SystemSettings(
      primaryAdminEmail: 'admin@gearup.enterprise',
      twoFactorAuth: 'Enabled (SMS + App)',
      sessionTimeout: 30,
      rolePermissions: {
        'User Management': PermissionSet(view: true, edit: true, delete: false),
        'Financial Reports': PermissionSet(view: true, edit: false, delete: false),
        'Service Log Control': PermissionSet(view: true, edit: true, delete: true),
      },
      emailAlerts: true,
      pushNotifications: false,
      weeklyReport: true,
      darkMode: false,
      accentColor: '#5D40D4',
      adminName: 'Asish Das',
      adminDesignation: 'Chief Technology Officer',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryAdminEmail': primaryAdminEmail,
      'twoFactorAuth': twoFactorAuth,
      'sessionTimeout': sessionTimeout,
      'rolePermissions': rolePermissions.map((k, v) => MapEntry(k, v.toMap())),
      'emailAlerts': emailAlerts,
      'pushNotifications': pushNotifications,
      'weeklyReport': weeklyReport,
      'darkMode': darkMode,
      'accentColor': accentColor,
      'adminName': adminName,
      'adminDesignation': adminDesignation,
    };
  }

  factory SystemSettings.fromMap(Map<String, dynamic> map) {
    return SystemSettings(
      primaryAdminEmail: map['primaryAdminEmail'] ?? '',
      twoFactorAuth: map['twoFactorAuth'] ?? '',
      sessionTimeout: map['sessionTimeout'] ?? 30,
      rolePermissions: (map['rolePermissions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, PermissionSet.fromMap(v as Map<String, dynamic>)),
          ) ??
          {},
      emailAlerts: map['emailAlerts'] as bool? ?? false,
      pushNotifications: map['pushNotifications'] as bool? ?? false,
      weeklyReport: map['weeklyReport'] as bool? ?? false,
      darkMode: map['darkMode'] as bool? ?? false,
      accentColor: map['accentColor'] as String? ?? '#5D40D4',
      adminName: map['adminName'] ?? 'Asish Das',
      adminDesignation: map['adminDesignation'] ?? 'Chief Technology Officer',
    );
  }
}

class PermissionSet {
  final bool view;
  final bool edit;
  final bool delete;

  PermissionSet({required this.view, required this.edit, required this.delete});

  Map<String, dynamic> toMap() {
    return {'view': view, 'edit': edit, 'delete': delete};
  }

  factory PermissionSet.fromMap(Map<String, dynamic> map) {
    return PermissionSet(
      view: map['view'] ?? false,
      edit: map['edit'] ?? false,
      delete: map['delete'] ?? false,
    );
  }
}
