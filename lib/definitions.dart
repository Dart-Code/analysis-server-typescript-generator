class ClassDefinition {
  String name;
  String doc;
  final List<PropertyDefinition> properties;

  ClassDefinition(this.name, this.doc)
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
