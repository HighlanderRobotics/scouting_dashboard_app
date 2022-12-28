class OfflineAnalysisUnavailableException extends Error {}

abstract class AnalysisFunction {
  Future<dynamic> getAnalysis() async {
    var analysis = await getOnlineAnalysis().catchError((error) async {
      return await getOfflineAnalysis();
    });

    return analysis;
  }

  Future<dynamic> getOfflineAnalysis() async {
    throw OfflineAnalysisUnavailableException();
  }

  Future<dynamic> getOnlineAnalysis();
}
