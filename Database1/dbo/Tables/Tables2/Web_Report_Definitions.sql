CREATE TABLE [dbo].[Web_Report_Definitions] (
    [WRD_Id]              INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Destination_EG_Id]   INT          NULL,
    [Hold_For_Review]     INT          NULL,
    [Is_Active]           INT          CONSTRAINT [DF_Web_Report_Definition_Is_Active] DEFAULT ((1)) NULL,
    [Last_Time_Trigger]   DATETIME     NULL,
    [Reject_EG_Id]        INT          NULL,
    [Report_Addressee_Id] INT          NULL,
    [Report_Type_Id]      INT          NULL,
    [RRD_Id]              INT          NULL,
    [Trigger_Delay]       INT          NULL,
    [WARC_Id]             INT          NULL,
    [WAT_Id]              INT          NULL,
    [WRD_Desc]            VARCHAR (50) NOT NULL,
    [WRT_Id]              INT          NOT NULL,
    CONSTRAINT [PK_Web_Report_Definitions] PRIMARY KEY NONCLUSTERED ([WRD_Id] ASC),
    CONSTRAINT [WRD_CUST] FOREIGN KEY ([Report_Addressee_Id]) REFERENCES [dbo].[Customer] ([Customer_Id]),
    CONSTRAINT [WRD_RRD] FOREIGN KEY ([RRD_Id]) REFERENCES [dbo].[Report_Relative_Dates] ([RRD_Id]),
    CONSTRAINT [WRD_WARC] FOREIGN KEY ([WARC_Id]) REFERENCES [dbo].[Web_App_Reject_Codes] ([WARC_Id]),
    CONSTRAINT [WRD_WRT] FOREIGN KEY ([WRT_Id]) REFERENCES [dbo].[Web_Report_Triggers] ([WRT_Id])
);

