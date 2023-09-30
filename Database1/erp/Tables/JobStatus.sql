CREATE TABLE [erp].[JobStatus] (
    [Job_Id]                 BIGINT         NOT NULL,
    [Key_Data]               VARCHAR (255)  NULL,
    [Request_Completed_Date] DATETIME2 (7)  NULL,
    [Request_Received_Date]  DATETIME2 (7)  NULL,
    [Response_Code]          INT            NULL,
    [Response_Message]       NVARCHAR (MAX) NULL,
    [Org_Code]               VARCHAR (255)  NULL,
    PRIMARY KEY CLUSTERED ([Job_Id] ASC)
);

