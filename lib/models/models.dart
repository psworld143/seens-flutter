class Student {
  final int? id;
  final String idNo;
  final String? photoLocation;
  final DateTime? dateAdded;

  Student({
    this.id,
    required this.idNo,
    this.photoLocation,
    this.dateAdded,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      idNo: json['id_no'] ?? '',
      photoLocation: json['photo_location'],
      dateAdded: json['date_added'] != null 
          ? DateTime.parse(json['date_added']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_no': idNo,
      'photo_location': photoLocation,
      'date_added': dateAdded?.toIso8601String(),
    };
  }
}

class LogEntry {
  final int? id;
  final String? studentId;
  final String? action;
  final DateTime? timestamp;
  final String? details;

  LogEntry({
    this.id,
    this.studentId,
    this.action,
    this.timestamp,
    this.details,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      studentId: json['student_id'],
      action: json['action'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : null,
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'action': action,
      'timestamp': timestamp?.toIso8601String(),
      'details': details,
    };
  }
}

class Account {
  final int? id;
  final String? username;
  final String? role;
  final DateTime? createdAt;

  Account({
    this.id,
    this.username,
    this.role,
    this.createdAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      username: json['username'],
      role: json['role'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] == 1 || json['success'] == true,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'],
    );
  }
}
