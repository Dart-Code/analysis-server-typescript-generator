class Definition {
  Definition(this.name, this.doc);

  String name;
  String doc;
}

class EnumDefinition extends Definition {
  EnumDefinition(String name, String doc) : super(name, doc);

  final values = new List<String>();
}

class InterfaceDefinition extends Definition {
  InterfaceDefinition(String name, String doc, {this.parent})
      : super(name, doc);

  String parent;
  final properties = new List<PropertyDefinition>();
}

class PropertyDefinition extends Definition {
  PropertyDefinition(
      this.type, this.value, String name, this.isOptional, String doc)
      : super(name, doc);

  String type;
  String value;
  bool isOptional;
}

class TypeAliasDefinition extends Definition {
  TypeAliasDefinition(this.type, String name, String doc) : super(name, doc);

  String type;
}
