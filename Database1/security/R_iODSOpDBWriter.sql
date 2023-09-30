CREATE ROLE [R_iODSOpDBWriter]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [R_iODSOpDBWriter] ADD MEMBER [EU\opdbwriter.im];

