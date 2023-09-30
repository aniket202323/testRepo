CREATE TABLE [dbo].[Message_Properties] (
    [MsgPropertyDataType] VARCHAR (50) NULL,
    [MsgPropertyDesc]     VARCHAR (50) NOT NULL,
    [MsgPropertyId]       INT          NOT NULL,
    CONSTRAINT [MessageProperties_PK_MsgPropertyId] PRIMARY KEY CLUSTERED ([MsgPropertyId] ASC)
);

