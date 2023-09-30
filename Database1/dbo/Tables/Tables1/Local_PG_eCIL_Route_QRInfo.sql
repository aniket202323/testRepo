CREATE TABLE [dbo].[Local_PG_eCIL_Route_QRInfo] (
    [QR_Id]                  INT           IDENTITY (1, 1) NOT NULL,
    [QR_Name]                VARCHAR (50)  NOT NULL,
    [QR_Description]         VARCHAR (255) NULL,
    [QR_GeneratedOn]         DATETIME      NOT NULL,
    [Last_ModifiedTimeStamp] DATETIME      NULL,
    [Route_Id]               INT           NOT NULL,
    [Entry_By]               INT           NULL,
    CONSTRAINT [PK_Local_PG_eCIL_Route_QRInfo] PRIMARY KEY NONCLUSTERED ([QR_Id] ASC),
    CONSTRAINT [Local_PG_eCIL_Route_QRInfo_FK_Local_PG_eCIL_Routes] FOREIGN KEY ([Route_Id]) REFERENCES [dbo].[Local_PG_eCIL_Routes] ([Route_Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Local_PG_eCIL_Route_QRInfo_IX_QRName]
    ON [dbo].[Local_PG_eCIL_Route_QRInfo]([QR_Name] ASC);

