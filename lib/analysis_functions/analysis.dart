class OfflineAnalysisUnavailableException extends Error {
  OfflineAnalysisUnavailableException(this.onlineError);

  final String onlineError;

  @override
  String toString() =>
      "Online analysis failed, and offline analysis is unavailable: $onlineError";
}

abstract class AnalysisFunction {
  Future<dynamic> getAnalysis() async {
    var analysis = await getOnlineAnalysis().catchError((error) async {
      return await getOfflineAnalysis(error.toString());
    });

    return analysis;
  }

  Future<dynamic> getOfflineAnalysis(String onlineError) async {
    throw OfflineAnalysisUnavailableException(onlineError);
  }

  Future<dynamic> getOnlineAnalysis();
}
