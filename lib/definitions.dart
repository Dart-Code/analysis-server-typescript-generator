class ClassDefinition {
  String name;
  String doc;
  final List<PropertyDefinition> properties;

  ClassDefinition(this.name, this.doc)
      : this.properties = new List<PropertyDefinition>();
}

class PropertyDefinition {
  String name;
  String doc;

  PropertyDefinition(this.name, this.doc);
}
