CREATE ROLE [PE_Proficy]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [PE_Proficy] ADD MEMBER [PEWebService];


GO
ALTER ROLE [PE_Proficy] ADD MEMBER [testuser_joel];

