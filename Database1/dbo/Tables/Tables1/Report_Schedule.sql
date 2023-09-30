CREATE TABLE [dbo].[Report_Schedule] (
    [Schedule_Id]     INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Computer_Name]   VARCHAR (20)  NULL,
    [Daily]           VARCHAR (50)  NULL,
    [Description]     VARCHAR (255) NULL,
    [Error_Code]      INT           CONSTRAINT [DF_Report_Schedule_Error_Code] DEFAULT ((0)) NULL,
    [Error_String]    VARCHAR (255) NULL,
    [Interval]        INT           NULL,
    [Last_Result]     INT           NULL,
    [Last_Run_Time]   DATETIME      NOT NULL,
    [Monthly]         VARCHAR (50)  NULL,
    [Next_Run_Time]   DATETIME      NULL,
    [Process_Id]      SMALLINT      NULL,
    [Report_Id]       INT           NOT NULL,
    [Run_Attempts]    INT           NULL,
    [Start_Date_Time] DATETIME      NOT NULL,
    [Status]          INT           NULL,
    CONSTRAINT [PK___1__27] PRIMARY KEY CLUSTERED ([Schedule_Id] ASC),
    CONSTRAINT [ReportSchedule_FK_ReportId] FOREIGN KEY ([Report_Id]) REFERENCES [dbo].[Report_Definitions] ([Report_Id]),
    CONSTRAINT [ReportSchedule_UC_ReportId] UNIQUE NONCLUSTERED ([Report_Id] ASC)
);

