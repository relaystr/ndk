List<List<String>> castToListOfListOfString(List<dynamic>? dynamicList) {
  return (dynamicList ?? []).whereType<List>().map((item) {
    return item.map((subItem) {
      if (subItem is String) {
        return subItem;
      } else {
        return subItem?.toString() ?? ''; // Handle null values
      }
    }).toList();
  }).toList();
}
