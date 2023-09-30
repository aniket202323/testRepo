CREATE TABLE [dbo].[Local_PrIME_PreStaged_Material_Request] (
    [Id]               INT            IDENTITY (1, 1) NOT NULL,
    [OpenTableId]      INT            NULL,
    [RequestId]        VARCHAR (50)   NULL,
    [BOMRMProdCode]    NVARCHAR (255) NULL,
    [BOMRMSubProdCode] NVARCHAR (255) NULL,
    [BOMRMTNLocatn]    NVARCHAR (255) NULL,
    [ProcessOrder]     NVARCHAR (255) NULL,
    [Quantity]         INT            NULL,
    [DefaultUserName]  NVARCHAR (255) NULL,
    [SOAEventTimeSlot] DATETIME       NULL,
    [InsertedTime]     DATETIME       NULL,
    [ProcessedTime]    DATETIME       NULL,
    [Status]           NVARCHAR (255) NULL,
    CONSTRAINT [Local_PrIME_PreStaged_Material_Request_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);

