CREATE TABLE [PR_Authorization].[Person] (
    [PersonId]         UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    [TenantId]         UNIQUEIDENTIFIER DEFAULT ([PR_Authorization].[ufn_GetDefaultTenant]()) NOT NULL,
    [S95Id]            NVARCHAR (255)   NOT NULL,
    [Description]      NVARCHAR (1024)  NULL,
    [FirstName]        NVARCHAR (255)   NULL,
    [MiddleName]       NVARCHAR (255)   NULL,
    [LastName]         NVARCHAR (255)   NULL,
    [Version]          BIGINT           DEFAULT ((1)) NOT NULL,
    [CreatedBy]        NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [CreatedDate]      DATETIME         DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]   NVARCHAR (255)   DEFAULT (suser_name()) NOT NULL,
    [LastModifiedDate] DATETIME         DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_Person] PRIMARY KEY CLUSTERED ([PersonId] ASC),
    CONSTRAINT [FK_Person_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [PR_Authorization].[Tenant] ([TenantId])
);


GO
ALTER TABLE [PR_Authorization].[Person] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK1_Person]
    ON [PR_Authorization].[Person]([TenantId] ASC, [S95Id] ASC);

