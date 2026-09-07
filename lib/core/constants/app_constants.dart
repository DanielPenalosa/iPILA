class AppConstants {
  static const String appName = 'iPILA';
  static const String appTagline =
      'Integrated Public Information & Local Access';
  static const String municipality = 'Municipality of Pila';
  static const String province = 'Laguna';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String reportsCollection = 'reports';
  static const String ordinancesCollection = 'ordinances';
  static const String faqsCollection = 'faqs';
  static const String notificationsCollection = 'notifications';

  // Report statuses
  static const String statusPending = 'Pending';
  static const String statusUnderReview = 'Under Review';
  static const String statusAssigned = 'Assigned';
  static const String statusInProgress = 'In Progress';
  static const String statusDone = 'Done';
  static const String statusNeedsRevision = 'Needs Revision';
  static const String statusResolved = 'Resolved';
  static const String statusRejected = 'Rejected';

  // All statuses in pipeline order
  static const List<String> reportStatuses = [
    statusPending,
    statusUnderReview,
    statusAssigned,
    statusInProgress,
    statusDone,
    statusNeedsRevision,
    statusResolved,
    statusRejected,
  ];

  // Admin-only status transitions
  static const List<String> adminStatuses = [
    statusUnderReview,
    statusAssigned,
    statusNeedsRevision,
    statusResolved,
    statusRejected,
  ];

  // Department-only status transitions
  static const List<String> departmentStatuses = [statusInProgress, statusDone];

  // Legacy aliases — kept for Firestore compatibility during migration
  static const String statusSubmitted = statusPending;
  static const String statusSeen = statusUnderReview;
  static const String statusValidated = statusUnderReview;
  static const String statusQueued = statusAssigned;
  static const String statusForVerification = statusDone;
  static const String statusCompleted = statusResolved;
  static const String statusRevisionRequired = statusNeedsRevision;

  // User roles
  static const String roleResident = 'resident';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'superadmin';
  static const String roleDepartment = 'department';

  // Firestore collections
  static const String departmentsCollection = 'departments';

  // Issue categories
  static const List<String> issueCategories = [
    'Road Damage',
    'Drainage / Flooding',
    'Broken Streetlight',
    'Garbage / Waste',
    'Public Facility',
    'Water Supply',
    'Illegal Structure',
    'Other',
  ];

  // Barangays of Pila, Laguna
  static const List<String> barangays = [
    'Aplaya',
    'Bagong Pook',
    'Bukal',
    'Bulilan Norte',
    'Bulilan Sur',
    'Concepcion',
    'Labuin',
    'Linga',
    'Masico',
    'Mojon',
    'Pansol',
    'Pinagbayanan',
    'San Antonio',
    'San Pedro',
    'Santa Clara Norte',
    'Santa Clara Sur',
    'Tibig',
  ];

  // Municipal departments
  static const List<String> departments = [
    'Engineering Office',
    'Health Office',
    'Social Welfare Office',
    'Environment & Natural Resources',
    'Public Works',
    'Disaster Risk Reduction',
    'Agriculture Office',
    'Business Permit & Licensing',
    'Treasurer\'s Office',
    'General Services',
  ];
}
