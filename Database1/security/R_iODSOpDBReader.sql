CREATE ROLE [R_iODSOpDBReader]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [R_iODSOpDBReader] ADD MEMBER [EU\opdbreader.im];

