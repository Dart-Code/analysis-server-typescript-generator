class Definition {
  String name;
  String doc;

  Definition(this.name, this.doc);
}

class InterfaceDefinition extends Definition {
  String parent;
  final properties = new List<PropertyDefinition>();

  InterfaceDefinition(String name, String doc, {this.parent})
      : super(name, doc);
}

class PropertyDefinition extends Definition {
  String type;
  String value;
  bool isOptional;

  PropertyDefinition(
      this.type, this.value, String name, this.isOptional, String doc)
      : super(name, doc);
}

class EnumDefinition extends Definition {
  final values = new List<String>();

  EnumDefinition(String name, String doc) : super(name, doc);
}

class TypeAliasDefinition extends Definition {
  String type;

  TypeAliasDefinition(this.type, String name, String doc) : super(name, doc);
}
