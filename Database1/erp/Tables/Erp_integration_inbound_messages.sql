CREATE TABLE [erp].[Erp_integration_inbound_messages] (
    [Id]                      BIGINT             IDENTITY (1, 1) NOT NULL,
    [Inserted_Date]           DATETIMEOFFSET (7) NOT NULL,
    [Key_Data]                VARCHAR (255)      NULL,
    [Media_Type]              VARCHAR (255)      NOT NULL,
    [Message]                 NVARCHAR (MAX)     NOT NULL,
    [Message_Type]            VARCHAR (255)      NOT NULL,
    [Process_Start_Date]      DATETIMEOFFSET (7) NULL,
    [Process_Completion_Date] DATETIMEOFFSET (7) NULL,
    [Response_Code]           INT                NULL,
    [Response_Message]        NVARCHAR (MAX)     NULL,
    [Inserted_By]             VARCHAR (255)      NULL,
    [Retry_Count]             INT                CONSTRAINT [DF_Constraint] DEFAULT ((0)) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

