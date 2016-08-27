class InterfaceDefinition {
  String name;
  String doc;
  final List<PropertyDefinition> properties;

  InterfaceDefinition(this.name, this.doc)
      : this.properties = new List<PropertyDefinition>();
}

class PropertyDefinition {
  String type;
  String value;
  String name;
  bool isOptional;
  String doc;

  PropertyDefinition(this.type, this.name, this.isOptional, this.doc);
}
