enum AlloyKey {
  iabTcfTcString,
  iabTcfPurposeConsents,
  iabTcfVendorConsents,
  iabTcfCmpSdkId,
  canonicalUserid,
  canonicalUseridCreatedAt,
  domainUseridWasReset,
  domainUserid,
  domainUseridCreatedAt,
  useridLastUsedAt,
  // No longer written, removed from devices that still have them
  legacyStoredUserIdsJson,
  legacyLastApiErrorOccurred;

  String get value {
    switch (this) {
      case AlloyKey.iabTcfTcString:
        return 'IABTCF_TCString';
      case AlloyKey.iabTcfPurposeConsents:
        return 'IABTCF_PurposeConsents';
      case AlloyKey.iabTcfVendorConsents:
        return 'IABTCF_VendorConsents';
      case AlloyKey.iabTcfCmpSdkId:
        return 'IABTCF_CmpSdkID';
      case AlloyKey.canonicalUserid:
        return 'aly_canonical_userid';
      case AlloyKey.canonicalUseridCreatedAt:
        return 'aly_canonical_userid_created_at';
      case AlloyKey.domainUseridWasReset:
        return 'aly_domain_userid_was_reset';
      case AlloyKey.domainUserid:
        return 'aly_domain_userid';
      case AlloyKey.domainUseridCreatedAt:
        return 'aly_domain_userid_created_at';
      case AlloyKey.useridLastUsedAt:
        return 'aly_userid_last_used_at';
      case AlloyKey.legacyStoredUserIdsJson:
        return 'aly_stored_user_ids_json';
      case AlloyKey.legacyLastApiErrorOccurred:
        return 'aly_last_api_error_occurred';
    }
  }
}
