import 'package:alloy_sdk/src/internal/network/api_client.dart';
import 'package:alloy_sdk/src/internal/service/user_identification_service.dart';
import 'package:alloy_sdk/src/internal/utility/alloy_key.dart';
import 'package:alloy_sdk/src/internal/utility/storage_client.dart';
import 'package:alloy_sdk/src/models/alloy_configuration.dart';
import 'package:alloy_sdk/src/models/alloy_environment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

void main() {
  final now = DateTime.utc(2027, 1, 1);
  final nowMs = now.millisecondsSinceEpoch;
  final maxAgeMs = UserIdentificationService.userIdMaxAge.inMilliseconds;

  late StorageClient storageClient;
  late UserIdentificationService service;

  Future<void> setUpWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    storageClient = StorageClient();
    await storageClient.init();
    service = UserIdentificationService(
      apiClient: ApiClient(
        configuration: AlloyConfiguration(tenant: 'test', env: AlloyEnvironment.development, appID: 'test'),
      ),
      storageClient: storageClient,
    );
  }

  Map<String, Object> storedIds({required int lastUsedAt}) => {
        AlloyKey.domainUserid.value: 'domain-id',
        AlloyKey.domainUseridCreatedAt.value: 1,
        AlloyKey.canonicalUserid.value: 'canonical-id',
        AlloyKey.canonicalUseridCreatedAt.value: 1,
        AlloyKey.useridLastUsedAt.value: lastUsedAt,
      };

  Future<Set<String>> storedKeys() async => (await SharedPreferences.getInstance()).getKeys();

  test('keeps ids used within a year', () async {
    await setUpWith(storedIds(lastUsedAt: nowMs - maxAgeMs));

    await service.expireUserIdsIfUnused(now: now);

    expect(await storedKeys(), containsAll([AlloyKey.domainUserid.value, AlloyKey.canonicalUserid.value]));
  });

  test('removes ids unused for over a year', () async {
    await setUpWith(storedIds(lastUsedAt: nowMs - maxAgeMs - 1));

    await service.expireUserIdsIfUnused(now: now);

    expect(await storedKeys(), isEmpty);
  });

  test('starts the clock for ids stored before the expiry existed', () async {
    await setUpWith({AlloyKey.domainUserid.value: 'domain-id'});

    await service.expireUserIdsIfUnused(now: now);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AlloyKey.domainUserid.value), 'domain-id');
    expect(prefs.getInt(AlloyKey.useridLastUsedAt.value), nowMs);
  });

  test('removes the legacy stored user ids', () async {
    await setUpWith({
      AlloyKey.legacyStoredUserIdsJson.value: '{"ssoUserID":"sso"}',
      AlloyKey.legacyLastApiErrorOccurred.value: true,
    });

    await service.expireUserIdsIfUnused(now: now);

    expect(await storedKeys(), {AlloyKey.useridLastUsedAt.value});
  });
}
