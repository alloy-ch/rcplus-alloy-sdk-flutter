class PageViewParameters {
  final String pageURL;
  final String referer;
  final String contentID;
  final String logicalPath;
  final Map<String, dynamic>? customTrackingAttributes;

  PageViewParameters({
    required this.pageURL,
    required this.referer,
    required this.contentID,
    required this.logicalPath,
    this.customTrackingAttributes,
  });

  factory PageViewParameters.empty() {
    return PageViewParameters(
        pageURL: '',
        referer: '',
        contentID: '',
        logicalPath: '',
        customTrackingAttributes: null
    );
  }
}