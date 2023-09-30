CREATE TABLE [dbo].[Route_QRInfo] (
    [QR_Id]                  INT           IDENTITY (1, 1) NOT NULL,
    [QR_Name]                VARCHAR (50)  NOT NULL,
    [QR_Description]         VARCHAR (255) NULL,
    [QR_GeneratedOn]         DATETIME      NOT NULL,
    [Last_ModifiedTimeStamp] DATETIME      NULL,
    [Last_ModifiedBy]        INT           NULL,
    [Route_Id]               INT           NOT NULL,
    PRIMARY KEY CLUSTERED ([QR_Id] ASC),
    FOREIGN KEY ([Route_Id]) REFERENCES [dbo].[Local_PG_eCIL_Routes] ([Route_Id])
);

