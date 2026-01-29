class Restaurant {
  final int id;
  final int tenantId;
  final String uuid;
  final String name;
  final String code;
  final String? address;
  final bool active;

  Restaurant({
    required this.id,
    required this.tenantId,
    required this.uuid,
    required this.name,
    required this.code,
    this.address,
    required this.active,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as int,
      tenantId: json['tenant_id'] as int,
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'uuid': uuid,
      'name': name,
      'code': code,
      'address': address,
      'active': active,
    };
  }

  @override
  String toString() {
    return 'Restaurant(id: $id, name: $name, code: $code)';
  }
}
