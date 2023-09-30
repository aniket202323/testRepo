CREATE TABLE [dbo].[DashboardLayout] (
    [SelectedPage] INT              NULL,
    [Version]      BIGINT           NULL,
    [PersonId]     UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY CLUSTERED ([PersonId] ASC),
    CONSTRAINT [DashboardLayout_Person_Relation1] FOREIGN KEY ([PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId])
);

