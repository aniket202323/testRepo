CREATE ROLE [FC_Proficy_IntHub]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [FC_Proficy_IntHub] ADD MEMBER [EU\profinthub.im];

