CREATE TABLE [dbo].[DashboardLayoutPage] (
    [r_Order]  INT              NULL,
    [Version]  BIGINT           NULL,
    [PersonId] UNIQUEIDENTIFIER NOT NULL,
    [PageId]   NVARCHAR (255)   NOT NULL,
    PRIMARY KEY CLUSTERED ([PersonId] ASC, [PageId] ASC),
    CONSTRAINT [DashboardLayoutPage_DashboardLayout_Relation1] FOREIGN KEY ([PersonId]) REFERENCES [dbo].[DashboardLayout] ([PersonId]),
    CONSTRAINT [DashboardLayoutPage_DashboardPage_Relation1] FOREIGN KEY ([PageId]) REFERENCES [dbo].[DashboardPage] ([PageId])
);


GO
CREATE NONCLUSTERED INDEX [NC_DashboardLayoutPage_PageId]
    ON [dbo].[DashboardLayoutPage]([PageId] ASC);

