CREATE TABLE [dbo].[ReportingSchedule] (
    [ReportingScheduleId]     UNIQUEIDENTIFIER NOT NULL,
    [Name]                    NVARCHAR (255)   NULL,
    [Description]             NVARCHAR (255)   NULL,
    [ReportingServerName]     NVARCHAR (255)   NULL,
    [IsIntegratedSecurity]    BIT              NULL,
    [UserName]                NVARCHAR (255)   NULL,
    [Password]                NVARCHAR (255)   NULL,
    [IsActivated]             BIT              NULL,
    [ChangeTrackingRetention] INT              NULL,
    [Version]                 BIGINT           NULL,
    [ItemId]                  UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ReportingScheduleId] ASC),
    CONSTRAINT [ReportingSchedule_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId])
);


GO
CREATE NONCLUSTERED INDEX [NC_ReportingSchedule_ItemId]
    ON [dbo].[ReportingSchedule]([ItemId] ASC);

