CREATE TABLE [dbo].[Report_Definition_Data] (
    [Row_Id]    INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Data]      TEXT     NULL,
    [Pagenum]   SMALLINT NOT NULL,
    [Report_Id] INT      NOT NULL,
    [Timestamp] DATETIME CONSTRAINT [DF_Report_Definition_Data_Timestamp] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_Report_Definition_Data] PRIMARY KEY CLUSTERED ([Row_Id] ASC)
);

