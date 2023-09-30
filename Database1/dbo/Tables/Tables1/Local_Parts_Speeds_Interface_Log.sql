CREATE TABLE [dbo].[Local_Parts_Speeds_Interface_Log] (
    [RESOURCE_ID]         VARCHAR (5)   NULL,
    [BRAND_CODE]          VARCHAR (9)   NULL,
    [EFF_DATE]            DATETIME      NULL,
    [LINE_SPEED]          INT           NULL,
    [TRANS_ID]            INT           NULL,
    [TRANS_TABLE]         VARCHAR (20)  NULL,
    [TRANS_TYPE]          VARCHAR (22)  NULL,
    [TRANS_OUTCOME]       VARCHAR (50)  NULL,
    [INTERFACE_COMMENTS]  VARCHAR (500) NULL,
    [SQL_SERVER_MESSAGES] VARCHAR (500) NULL
);

