CREATE ROLE [CLmig_app_role]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [CLmig_app_role] ADD MEMBER [EU\CLUser.im];

