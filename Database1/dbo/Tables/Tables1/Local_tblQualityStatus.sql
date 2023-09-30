CREATE TABLE [dbo].[Local_tblQualityStatus] (
    [Id]              INT                       IDENTITY (1, 1) NOT NULL,
    [Prodid]          INT                       NULL,
    [Product]         [dbo].[Varchar_Prod_Code] NOT NULL,
    [Batchcode]       VARCHAR (255)             NOT NULL,
    [PostingDate]     VARCHAR (10)              NULL,
    [DocuemntDate]    VARCHAR (10)              NULL,
    [ReferenceNumber] VARCHAR (10)              NULL,
    [Location]        VARCHAR (255)             NULL,
    [MovementType]    VARCHAR (255)             NULL,
    [Quantity]        VARCHAR (255)             NULL,
    [UOM]             VARCHAR (15)              NULL,
    [InsertedDate]    DATETIME                  NOT NULL,
    [OrderStartdate]  VARCHAR (50)              NULL,
    [OrderFinishdate] VARCHAR (50)              NULL,
    [PU_ID]           INT                       NULL,
    [FromStatus]      VARCHAR (25)              NULL,
    [ToStatus]        VARCHAR (25)              NULL,
    FOREIGN KEY ([Prodid]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    FOREIGN KEY ([Product]) REFERENCES [dbo].[Products_Base] ([Prod_Code]),
    FOREIGN KEY ([PU_ID]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    FOREIGN KEY ([UOM]) REFERENCES [dbo].[Engineering_Unit] ([Eng_Unit_Code])
);


GO
CREATE NONCLUSTERED INDEX [Local_tblQualityStatus_IDX1]
    ON [dbo].[Local_tblQualityStatus]([Id] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Local_tblQualityStatus_IDX2]
    ON [dbo].[Local_tblQualityStatus]([Batchcode] ASC, [InsertedDate] ASC);

