class CategoryKnowledge {
  static const Map<String, List<String>> categories = {
    "อาหาร": ["ข้าว", "ก๋วยเตี๋ยว", "น้ำ", "กาแฟ", "ขนม", "ผัด", "ต้ม", "แกง", "ทอด", "หมู", "ไก่", "ปลา", "เครื่องดื่ม", "ยำ", "ส้มตำ", "ลาบ", "โจ๊ก", "บะหมี่", "เกาเหลา", "ชา", "นม"],
    "เดินทาง": ["รถเมล์", "แท็กซี่", "วิน", "bts", "mrt", "น้ำมัน", "ทางด่วน", "ค่ารถ", "grab", "bolt"],
    "ของใช้": ["สบู่", "ยาสระผม", "ยาสีฟัน", "ผงซักฟอก", "ทิชชู่", "เครื่องสำอาง", "ครีม", "ยา"],
    "ช้อปปิ้ง": ["เสื้อ", "กางเกง", "รองเท้า", "กระเป๋า", "ของเล่น", "ห้าง"],
    "บิล": ["ค่าน้ำ", "ค่าไฟ", "ค่าเน็ต", "ค่าโทรศัพท์", "บัตรเครดิต", "ค่าห้อง", "ค่าบ้าน", "ค่ารถ"],
    "อื่นๆ": []
  };

  static String getPromptContext() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("Keywords:");
    categories.forEach((category, keywords) {
      if (keywords.isNotEmpty) {
        buffer.writeln("$category: ${keywords.join(',')}");
      }
    });
    return buffer.toString();
  }
}
