CREATE TABLE [dbo].[Local_PG_eCIL_TourStop_QRInfo] (
    [QR_Id]                  INT           IDENTITY (1, 1) NOT NULL,
    [QR_Name]                VARCHAR (50)  NOT NULL,
    [QR_Description]         VARCHAR (255) NULL,
    [QR_GeneratedOn]         DATETIME      NOT NULL,
    [Last_ModifiedTimeStamp] DATETIME      NULL,
    [Route_Id]               INT           NOT NULL,
    [TourStop_Id]            INT           NOT NULL,
    [Entry_By]               INT           NOT NULL,
    CONSTRAINT [PK_Local_PG_eCIL_TourStop_QRInfo] PRIMARY KEY NONCLUSTERED ([QR_Id] ASC),
    CONSTRAINT [Local_PG_eCIL_TourStop_QRInfo_FK_Local_PG_eCIL_Routes] FOREIGN KEY ([Route_Id]) REFERENCES [dbo].[Local_PG_eCIL_Routes] ([Route_Id]),
    CONSTRAINT [Local_PG_eCIL_TourStop_QRInfo_FK_Local_PG_eCIL_TourStops] FOREIGN KEY ([TourStop_Id]) REFERENCES [dbo].[Local_PG_eCIL_TourStops] ([Tour_Stop_Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Local_PG_eCIL_TourStop_QRInfo_IX_QRName]
    ON [dbo].[Local_PG_eCIL_TourStop_QRInfo]([QR_Name] ASC);

