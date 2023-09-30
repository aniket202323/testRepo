CREATE TABLE [PR_Authorization].[Privilege] (
    [PrivilegeId]      UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    [Name]             NVARCHAR (255)   NOT NULL,
    [Description]      NVARCHAR (255)   NULL,
    [Type]             NVARCHAR (255)   NULL,
    [TypeName]         NVARCHAR (255)   NULL,
    [OperationId]      NVARCHAR (255)   NULL,
    [Version]          BIGINT           DEFAULT ((1)) NOT NULL,
    [CreatedBy]        NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]      DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]   NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate] DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_Privilege] PRIMARY KEY CLUSTERED ([PrivilegeId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK1_Privilege]
    ON [PR_Authorization].[Privilege]([Name] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This contains the valid Privileges that can be assigned to Privilege Sets, which can then be assigned to Users either directly or through a User Group.', @level0type = N'SCHEMA', @level0name = N'PR_Authorization', @level1type = N'TABLE', @level1name = N'Privilege';

