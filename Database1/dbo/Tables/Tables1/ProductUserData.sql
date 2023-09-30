CREATE TABLE [dbo].[ProductUserData] (
    [ProductUserInfoId]    UNIQUEIDENTIFIER NOT NULL,
    [ProductUserName]      NVARCHAR (255)   NULL,
    [PasswordHash]         NVARCHAR (255)   NULL,
    [Version]              BIGINT           NULL,
    [ProductApplicationId] UNIQUEIDENTIFIER NULL,
    [Id]                   UNIQUEIDENTIFIER NULL,
    [PersonId]             UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ProductUserInfoId] ASC),
    CONSTRAINT [ProductUserData_ProductApplicationData_Relation1] FOREIGN KEY ([ProductApplicationId]) REFERENCES [dbo].[ProductApplicationData] ([ProductApplicationId]),
    CONSTRAINT [ProductUserData_UserAccount_Relation1] FOREIGN KEY ([Id]) REFERENCES [PR_Authorization].[UserAccount] ([UserAccountId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ProductUserData_ProductApplicationId_Id_PersonId]
    ON [dbo].[ProductUserData]([ProductApplicationId] ASC, [Id] ASC, [PersonId] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_ProductUserData_Id_PersonId]
    ON [dbo].[ProductUserData]([Id] ASC, [PersonId] ASC);

