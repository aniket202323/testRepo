CREATE TABLE [dbo].[PrintServer_Files] (
    [File_ID]                  INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Copies]                   TINYINT        CONSTRAINT [DF_PrintServer_Files_Copies] DEFAULT ((1)) NOT NULL,
    [DeleteFlag]               BIT            CONSTRAINT [DF_PrintServer_Files_DeleteFlag] DEFAULT ((1)) NOT NULL,
    [ErrorDirectory]           VARCHAR (1000) NULL,
    [File_Processed]           BIT            CONSTRAINT [DF_PrintServer_Files_File_Processed] DEFAULT ((0)) NOT NULL,
    [File_Processed_TimeStamp] DATETIME       NULL,
    [FileName]                 VARCHAR (1000) NOT NULL,
    [MoveToDirectory]          VARCHAR (1000) NULL,
    [NumberOfAttempts]         INT            CONSTRAINT [DF_PrintServer_Files_NumberOfAttempts] DEFAULT ((0)) NOT NULL,
    [PrinterName]              VARCHAR (1000) NULL,
    CONSTRAINT [PK_PrintServer_Files] PRIMARY KEY CLUSTERED ([File_ID] ASC)
);

