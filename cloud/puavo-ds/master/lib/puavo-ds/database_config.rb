module PuavoDatabaseConfig
  CONFIG = {
    'olcDbMaxSize' => [ '40000000000' ],
    'olcLastMod'   => [ 'TRUE' ],
  }
  INDEXES = [ 'cn eq,sub',
              'creatorsName eq',
              'displayName sub',
              'entryCSN eq',
              'gidNumber eq',
              'givenName sub',
              'homeDirectory eq',
              'krbPrincipalName eq',
              'member eq',
              'memberUid eq',
              'objectClass eq',
              'puavoAdminOfSchool eq',
              'puavoDevicePrimaryUser eq',
              'puavoDeviceType eq',
              'puavoEduGroupType eq',
              'puavoEduPersonAffiliation eq',
              'puavoExternalId eq',
              'puavoHostname eq',
              'puavoId eq',
              'puavoPrinterQueue eq',
              'puavoSchoolAdmin eq',
              'puavoSchool eq',
              'puavoServiceDomain eq',
              'puavoWirelessPrinterQueue eq',
              'sn sub',
              'uid eq,sub' ]
  MODULES = [ '{0}back_mdb',
              '{1}dynlist',
              '{2}unique',
              '{3}ppolicy',
              '{4}syncprov',
              '{5}memberof',
              '{6}valsort',
              '{7}auditlog',
              '{8}refint',
              '{9}constraint',
              '{10}accesslog',
              '{11}deref',
              '{12}smbkrb5pwd_srv' ]
end
