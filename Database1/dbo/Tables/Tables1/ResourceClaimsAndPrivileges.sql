CREATE TABLE [dbo].[ResourceClaimsAndPrivileges] (
    [Version]         BIGINT           NULL,
    [ResourceClaimId] UNIQUEIDENTIFIER NOT NULL,
    [IdPrivileges]    UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([ResourceClaimId] ASC, [IdPrivileges] ASC),
    CONSTRAINT [ResourceClaimsAndPrivileges_PersonnelPrivileges_Relation1] FOREIGN KEY ([IdPrivileges]) REFERENCES [PR_Authorization].[Privilege] ([PrivilegeId]),
    CONSTRAINT [ResourceClaimsAndPrivileges_ResourceClaims_Relation1] FOREIGN KEY ([ResourceClaimId]) REFERENCES [dbo].[ResourceClaims] ([ResourceClaimId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ResourceClaimsAndPrivileges_IdPrivileges]
    ON [dbo].[ResourceClaimsAndPrivileges]([IdPrivileges] ASC);

