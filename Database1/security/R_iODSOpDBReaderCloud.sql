CREATE ROLE [R_iODSOpDBReaderCloud]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [R_iODSOpDBReaderCloud] ADD MEMBER [EU\opdbreadercloud.im];

