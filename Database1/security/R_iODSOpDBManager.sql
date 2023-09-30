CREATE ROLE [R_iODSOpDBManager]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [R_iODSOpDBManager] ADD MEMBER [EU\opdbmanager.im];

