enum AlloyKey {
  iabTcfTcString,
  iabTcfPurposeConsents,
  iabTcfCmpSdkId,
  canonicalUserid,
  canonicalUseridCreatedAt,
  storedUserIdsJson,
  lastApiErrorOccurred,
  domainUserid,
  domainUseridCreatedAt;

  String get value {
    switch (this) {
      case AlloyKey.iabTcfTcString:
        return 'IABTCF_TCString';
      case AlloyKey.iabTcfPurposeConsents:
        return 'IABTCF_PurposeConsents';
      case AlloyKey.iabTcfCmpSdkId:
        return 'IABTCF_CmpSdkID';
      case AlloyKey.canonicalUserid:
        return 'aly_canonical_userid';
      case AlloyKey.canonicalUseridCreatedAt:
        return 'aly_canonical_userid_created_at';
      case AlloyKey.storedUserIdsJson:
        return 'aly_stored_user_ids_json';
      case AlloyKey.lastApiErrorOccurred:
        return 'aly_last_api_error_occurred';
      case AlloyKey.domainUserid:
        return 'aly_domain_userid';
      case AlloyKey.domainUseridCreatedAt:
        return 'aly_domain_userid_created_at';
    }
  }
} 