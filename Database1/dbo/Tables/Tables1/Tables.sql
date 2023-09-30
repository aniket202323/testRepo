CREATE TABLE [dbo].[Tables] (
    [Allow_User_Defined_Property] BIT           CONSTRAINT [Tables_DF_AllowUDP] DEFAULT ((0)) NOT NULL,
    [Allow_X_Ref]                 BIT           NULL,
    [TableId]                     INT           NOT NULL,
    [TableName]                   VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_Tables] PRIMARY KEY NONCLUSTERED ([TableId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Tables_IDX_TableName]
    ON [dbo].[Tables]([TableName] ASC);

