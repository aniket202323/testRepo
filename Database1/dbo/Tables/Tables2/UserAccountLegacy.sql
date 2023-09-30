CREATE TABLE [dbo].[UserAccountLegacy] (
    [Id]                  UNIQUEIDENTIFIER NOT NULL,
    [LoginName]           NVARCHAR (255)   NULL,
    [PasswordHash]        NVARCHAR (255)   NULL,
    [PasswordSalt]        NVARCHAR (255)   NULL,
    [EmailAddress]        NVARCHAR (255)   NULL,
    [AccountDisabled]     BIT              NULL,
    [LastLogin]           DATETIME         NULL,
    [FirstFailedLogin]    DATETIME         NULL,
    [FailedLoginCount]    TINYINT          NULL,
    [LockoutStart]        DATETIME         NULL,
    [IsWindowsDomainUser] BIT              NULL,
    [Version]             BIGINT           NULL,
    [PersonId]            UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC, [PersonId] ASC),
    CONSTRAINT [UserAccount_Person_Relation1] FOREIGN KEY ([PersonId]) REFERENCES [dbo].[PersonLegacy] ([PersonId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_UserAccount_LoginName]
    ON [dbo].[UserAccountLegacy]([LoginName] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_UserAccount_PersonId]
    ON [dbo].[UserAccountLegacy]([PersonId] ASC);

