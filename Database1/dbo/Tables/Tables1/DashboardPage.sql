CREATE TABLE [dbo].[DashboardPage] (
    [PageId]    NVARCHAR (255)   NOT NULL,
    [PageName]  NVARCHAR (255)   NULL,
    [PageType]  NVARCHAR (255)   NULL,
    [PageXML]   IMAGE            NULL,
    [Timestamp] DATETIME         NULL,
    [Version]   BIGINT           NULL,
    [IdRoles]   UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([PageId] ASC),
    CONSTRAINT [DashboardPage_PersonnelRole_Relation1] FOREIGN KEY ([IdRoles]) REFERENCES [dbo].[PersonnelRole] ([IdRoles])
);


GO
CREATE NONCLUSTERED INDEX [NC_DashboardPage_IdRoles]
    ON [dbo].[DashboardPage]([IdRoles] ASC);

