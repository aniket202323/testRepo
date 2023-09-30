CREATE TABLE [dbo].[Local_PG_eCIL_Tasks_QRInfo] (
    [QR_Id]                  INT           IDENTITY (1, 1) NOT NULL,
    [QR_Name]                VARCHAR (150) NOT NULL,
    [QR_Description]         VARCHAR (255) NULL,
    [QR_GeneratedOn]         DATETIME      NOT NULL,
    [Last_ModifiedTimeStamp] DATETIME      NULL,
    [Line_Ids]               VARCHAR (255) NULL,
    [MasterUnit_Ids]         VARCHAR (255) NULL,
    [SlaveUnit_Ids]          VARCHAR (255) NULL,
    [Var_Ids]                VARCHAR (MAX) NOT NULL,
    [Route_Ids]              VARCHAR (255) NULL,
    CONSTRAINT [PK_Local_PG_eCIL_Tasks_QRInfo] PRIMARY KEY NONCLUSTERED ([QR_Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Local_PG_eCIL_Tasks_QRInfo_IX_QRName]
    ON [dbo].[Local_PG_eCIL_Tasks_QRInfo]([QR_Name] ASC);

