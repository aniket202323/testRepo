CREATE TABLE [dbo].[Local_PG_eCIL_QRInfo_History] (
    [QR_History_Id]   INT           IDENTITY (1, 1) NOT NULL,
    [QR_Id]           INT           NOT NULL,
    [QR_Name]         VARCHAR (150) NOT NULL,
    [QR_Description]  VARCHAR (255) NULL,
    [QR_Created_On]   DATETIME      NOT NULL,
    [LastModified_On] DATETIME      NULL,
    [Line_Ids]        VARCHAR (255) NULL,
    [Var_Ids]         VARCHAR (MAX) NULL,
    [Route_Ids]       VARCHAR (255) NULL,
    [Tour_Stop_Id]    INT           NULL,
    [Entry_By]        INT           NOT NULL,
    [QR_Type]         VARCHAR (50)  NULL,
    [DBTT_Id]         TINYINT       NULL,
    PRIMARY KEY CLUSTERED ([QR_History_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Local_PG_eCIL_QRInfo_History_IX_QRId]
    ON [dbo].[Local_PG_eCIL_QRInfo_History]([QR_Id] ASC);

