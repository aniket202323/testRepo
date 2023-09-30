CREATE TABLE [dbo].[Report_Hits] (
    [Hit_Id]    INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [HitTime]   DATETIME NOT NULL,
    [Report_Id] INT      NOT NULL,
    [User_Id]   INT      NOT NULL,
    CONSTRAINT [PK_Report_Hits] PRIMARY KEY NONCLUSTERED ([Hit_Id] ASC)
);

