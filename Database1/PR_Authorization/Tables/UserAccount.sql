CREATE TABLE [PR_Authorization].[UserAccount] (
    [UserAccountId]       UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    [PersonId]            UNIQUEIDENTIFIER NOT NULL,
    [LoginName]           NVARCHAR (255)   NOT NULL,
    [PasswordHash]        NVARCHAR (255)   NULL,
    [PasswordSalt]        NVARCHAR (255)   NULL,
    [EmailAddress]        NVARCHAR (255)   NULL,
    [AccountDisabled]     BIT              NULL,
    [LastLogin]           DATETIME         NULL,
    [FirstFailedLogin]    DATETIME         NULL,
    [FailedLoginCount]    TINYINT          NULL,
    [LockoutStart]        DATETIME         NULL,
    [IsWindowsDomainUser] BIT              NULL,
    [Version]             BIGINT           DEFAULT ((1)) NOT NULL,
    [Deleted]             BIT              CONSTRAINT [DF_UserAccount_Deleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]           NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]         DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]      NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate]    DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_UserAccount] PRIMARY KEY CLUSTERED ([UserAccountId] ASC),
    CONSTRAINT [FK_UserAccount_Person] FOREIGN KEY ([PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK1_UserAccount]
    ON [PR_Authorization].[UserAccount]([LoginName] ASC);


GO
CREATE NONCLUSTERED INDEX [IE1_UserAccount]
    ON [PR_Authorization].[UserAccount]([PersonId] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This contains the "login" information for a user.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'UserAccount';

