class ViewAllHomePageLis {
  String? id;
  String? title;
  String? description;
  String? empId;
  String? userType;
  String? customerId;
  String? cName;
  String? cPhone;
  String? cAddress;
  String? status;
  String? createdAt;
  String? updatedAt;

  ViewAllHomePageLis(
      {this.id,
      this.title,
      this.description,
      this.empId,
      this.userType,
      this.customerId,
      this.cName,
      this.cPhone,
      this.cAddress,
      this.status,
      this.createdAt,
      this.updatedAt});

  ViewAllHomePageLis.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    title = json['title'].toString();
    description = json['description'].toString();
    empId = json['emp_id'].toString();
    userType = json['user_type'].toString();
    customerId = json['customer_id'].toString();
    cName = json['c_name'].toString();
    cPhone = json['c_phone'].toString();
    cAddress = json['c_address'].toString();
    status = json['status'].toString();
    createdAt = json['created_at'].toString();
    updatedAt = json['updated_at'].toString();
  }
}
