abstract class AnalyticsEvent {}

class LoadDashboardStats extends AnalyticsEvent {
	final String periode;
	LoadDashboardStats({this.periode = '7d'});
}

class RefreshDashboardStats extends AnalyticsEvent {
	final String periode;
	RefreshDashboardStats({this.periode = '7d'});
}

class LoadStatusPangan extends AnalyticsEvent {}
